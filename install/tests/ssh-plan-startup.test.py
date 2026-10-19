#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class StartupTests(unittest.TestCase):
    def test_ssh_has_no_automatic_forwarding(self):
        config = (ROOT / 'ssh/config').read_text()
        config = '\n'.join(line for line in config.splitlines() if not line.startswith('Include '))
        with tempfile.NamedTemporaryFile(mode='w') as fixture:
            fixture.write(config)
            fixture.flush()
            for host in ('stronghold', 'stronghold-2.local', 'aiserver', 'other'):
                result = subprocess.run(['ssh', '-G', '-F', fixture.name, host], capture_output=True, text=True, check=True)
                self.assertNotIn('localforward ', result.stdout)

    def check_completion(self, mode):
        config = (ROOT / 'zsh/zshrc.symlink').read_text()
        start = config.index('if command -v plan ')
        marker = '    unset _plan_completion\nfi\n'
        end = config.index(marker, start) + len(marker)
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp)
            plan = fixture / 'plan'
            plan.write_text('''#!/bin/sh
printf '%s\\n' "$2" >> "$TEST_CALLS"
if [ "$TEST_MODE" = broken ]; then
    echo 'touch "$HOME/unwanted-evaluation"'
    echo failure >&2
    exit 1
fi
if [ "$2" = zsh ]; then
    if [ "$TEST_MODE" = legacy ]; then
        echo 'Usage: plan completion bash' >&2
        exit 1
    fi
    echo '_plan_native() { :; }; compdef _plan_native plan'
else
    echo '_plan_legacy() { COMPREPLY=(open); }; complete -F _plan_legacy plan'
fi
''')
            plan.chmod(0o755)
            insecure = fixture / 'insecure-completions'
            insecure.mkdir()
            insecure.chmod(0o777)
            (insecure / '_untrusted_fixture').write_text('#compdef untrusted_fixture\n')
            script = 'fpath=("$HOME/insecure-completions" $fpath)\nautoload -U compinit bashcompinit\ncompinit -i -d "$HOME/.zcompdump" || exit 13\nbashcompinit\n'
            script += '[[ -z ${_comps[untrusted_fixture]-} ]] || exit 14\n'
            script += config[start:end]
            if mode == 'native':
                script += '[[ ${_comps[plan]} == _plan_native ]] || exit 10\n'
            elif mode == 'legacy':
                script += '[[ $(complete -p plan) == *"_plan_legacy"* ]] || exit 11\n'
            script += '[[ ! -e "$HOME/unwanted-evaluation" ]] || exit 12\n'
            env = dict(os.environ, HOME=temp, TEST_MODE=mode, TEST_CALLS=str(fixture / 'calls'), PATH=f'{temp}:/usr/bin:/bin')
            result = subprocess.run(['zsh', '-f', '-c', script], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, '')
            calls = (fixture / 'calls').read_text().splitlines()
            self.assertEqual(calls, ['zsh'] if mode == 'native' else ['zsh', 'bash'])

    def test_native_completion(self):
        self.check_completion('native')

    def test_legacy_completion(self):
        self.check_completion('legacy')

    def test_failed_completion_is_not_evaluated(self):
        self.check_completion('broken')


if __name__ == '__main__':
    unittest.main()

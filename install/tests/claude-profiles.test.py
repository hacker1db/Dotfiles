import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ProfilesTest(unittest.TestCase):
    def test_install_and_reinstall(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            repo = root / 'repo'
            home = root / 'home'
            (repo / 'install').mkdir(parents=True)
            shutil.copytree(ROOT / 'claude', repo / 'claude', ignore=shutil.ignore_patterns('.local', 'skills', 'plugins'))
            shutil.copy2(ROOT / 'install/claude-profiles.py', repo / 'install/claude-profiles.py')
            home.mkdir()
            hook = home / '.claude/hooks/sonar-secrets/build-scripts'
            hook.mkdir(parents=True)
            for name in ('prompt-secrets.sh', 'pretool-secrets.sh'):
                (hook / name).write_text('#!/bin/sh\nexit 0\n')
                (hook / name).chmod(0o700)
            commit = home / '.dotfiles/claude/hooks'
            commit.mkdir(parents=True)
            (commit / 'pre-commit-security.sh').write_text('#!/bin/sh\nexit 0\n')
            (commit / 'pre-commit-security.sh').chmod(0o700)
            local = home / 'foundry.json'
            local.write_text(json.dumps({'env': {'ANTHROPIC_FOUNDRY_RESOURCE': 'fixture-resource'}}))
            personal = home / '.claude-personal'
            personal.mkdir()
            status = {'type': 'command', 'command': 'my-status'}
            unrelated = {'hooks': [{'type': 'command', 'command': 'my-unrelated-hook'}]}
            (personal / 'settings.json').write_text(json.dumps({'statusLine': status, 'env': {'ANTHROPIC_API_KEY': 'dummy-stored-key', 'CLAUDE_CODE_OAUTH_TOKEN': 'dummy-stored-token'}, 'apiKeyHelper': 'unwanted-helper', 'hooks': {'Stop': [unrelated], 'UserPromptSubmit': [{'hooks': [{'type': 'command', 'command': '~/.claude/hooks/sonar-secrets/build-scripts/prompt-secrets.sh'}]}]}}))
            environment = {k: v for k, v in os.environ.items() if not k.startswith(('ANTHROPIC_', 'CLAUDE_CODE_USE_'))}
            environment['HOME'] = str(home)
            command = ['python3', str(repo / 'install/claude-profiles.py'), '--foundry-settings', str(local)]
            subprocess.run(command, env=environment, check=True, capture_output=True)
            first = {}
            for name in ('foundry', 'subscription', 'personal'):
                directory = home / ('.claude-' + name)
                self.assertEqual(directory.stat().st_mode & 0o777, 0o700)
                path = directory / 'settings.json'
                self.assertTrue(path.is_symlink())
                first[name] = path.read_bytes()
                settings = json.loads(first[name])
                serialized = json.dumps(settings.get('hooks', {}))
                self.assertNotIn('sonar-secrets', serialized)
                self.assertEqual('pre-commit-security.sh' in serialized, name != 'personal')
                self.assertEqual(settings['env']['CLAUDE_CODE_USE_FOUNDRY'], '1' if name == 'foundry' else '0')
            settings = json.loads(first['personal'])
            self.assertEqual(settings['statusLine'], status)
            self.assertEqual(settings['hooks']['Stop'], [unrelated])
            self.assertNotIn('dummy-stored', json.dumps(settings))
            self.assertNotIn('apiKeyHelper', settings)
            backups = list(personal.glob('settings.json.backup.*'))
            self.assertEqual(len(backups), 1)
            subprocess.run(command, env=environment, check=True, capture_output=True)
            for name, data in first.items():
                self.assertEqual((home / ('.claude-' + name) / 'settings.json').read_bytes(), data)
            self.assertEqual(list(personal.glob('settings.json.backup.*')), backups)
            checked = subprocess.run(command + ['--check'], env=environment, capture_output=True)
            self.assertEqual(checked.returncode, 0, checked.stdout)
            for name, data in first.items():
                self.assertEqual((home / ('.claude-' + name) / 'settings.json').read_bytes(), data)
            (commit / 'pre-commit-security.sh').unlink()
            missing = subprocess.run(command + ['--check'], env=environment, capture_output=True)
            self.assertEqual(missing.returncode, 2)
            self.assertIn(b'Missing work hook prerequisite', missing.stdout)
            (commit / 'pre-commit-security.sh').write_text('#!/bin/sh\nexit 0\n')
            (commit / 'pre-commit-security.sh').chmod(0o700)
            dirty = dict(environment, ANTHROPIC_API_KEY='dummy-never-use', CLAUDE_CODE_USE_BEDROCK='1')
            checked = subprocess.run(command + ['--check'], env=dirty, capture_output=True)
            self.assertEqual(checked.returncode, 2)
            self.assertNotIn(b'dummy-never-use', checked.stdout + checked.stderr)
            self.assertEqual(dirty['ANTHROPIC_API_KEY'], 'dummy-never-use')
            (home / '.claude-foundry/settings.json').unlink()
            skipped = subprocess.run(command + ['--skip-foundry'], env=environment, capture_output=True)
            self.assertEqual(skipped.returncode, 0, skipped.stderr)
            self.assertFalse((home / '.claude-foundry/settings.json').exists())
            subprocess.run(command, env=environment, check=True, capture_output=True)
            local.write_text(json.dumps({'env': {'ANTHROPIC_FOUNDRY_API_KEY': 'dummy'}}))
            failed = subprocess.run(command, env=environment, capture_output=True)
            self.assertNotEqual(failed.returncode, 0)
            for name, data in first.items():
                self.assertEqual((home / ('.claude-' + name) / 'settings.json').read_bytes(), data)


if __name__ == '__main__':
    unittest.main()

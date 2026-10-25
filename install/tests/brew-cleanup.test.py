import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / 'zsh/functions.zsh').read_text()
FUNCTION = SOURCE[SOURCE.index('function brew-cleanup(){'):SOURCE.index('\nfunction update-node-tools(){')]


class BrewCleanupTests(unittest.TestCase):
    def check_cleanup(self, leaves, dump, succeeds, leaves_status=0, dump_status=0):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'install').mkdir()
            brewfile = root / 'install/brewfile'
            brewfile.write_text('original\n')
            (root / 'dump').write_text(dump)
            (root / 'leaves').write_text(leaves)
            brew = root / 'brew'
            brew.write_text('''#!/bin/sh
case "$1" in
bundle)
    for arg do
        case "$arg" in --file=*) cp "$DOTFILES/dump" "${arg#--file=}" ;; esac
    done
    exit "$DUMP_STATUS" ;;
leaves) cat "$DOTFILES/leaves"; exit "$LEAVES_STATUS" ;;
cleanup|doctor) echo "$1" >> "$DOTFILES/calls" ;;
*) exit 99 ;;
esac
''')
            brew.chmod(0o755)
            environment = dict(os.environ, DOTFILES=directory, TMPDIR=directory,
                               PATH=directory + ':' + os.environ['PATH'],
                               LEAVES_STATUS=str(leaves_status), DUMP_STATUS=str(dump_status))
            result = subprocess.run(['zsh', '-f', '-c', FUNCTION + '\nbrew-cleanup'],
                                    env=environment, capture_output=True, text=True)
            self.assertEqual(result.returncode == 0, succeeds, result.stdout + result.stderr)
            self.assertEqual(brewfile.read_text(), dump if succeeds else 'original\n')
            calls = root / 'calls'
            self.assertEqual(calls.read_text() if calls.exists() else '', 'cleanup\ndoctor\n' if succeeds else '')
            self.assertEqual(list(root.glob('brewfile.*')), [])

    def test_qualified_and_core_formulae(self):
        self.check_cleanup('hashicorp/tap/terraform\nazure/functions/azure-functions-core-tools@4\njq\n',
                           'brew "hashicorp/tap/terraform"\nbrew "azure/functions/azure-functions-core-tools@4"\nbrew "jq"\n', True)

    def test_unqualified_leaf_with_qualified_dump(self):
        self.check_cleanup('terraform\n', 'brew "hashicorp/tap/terraform"\n', True)

    def test_different_tap_is_not_a_match(self):
        self.check_cleanup('hashicorp/tap/terraform\n', 'brew "other/tap/terraform"\n', False)

    def test_missing_formula(self):
        self.check_cleanup('jq\n', 'brew "tree"\n', False)

    def test_failed_leaves(self):
        self.check_cleanup('', 'brew "jq"\n', False, leaves_status=1)

    def test_failed_dump(self):
        self.check_cleanup('jq\n', 'brew "jq"\n', False, dump_status=1)



class BundleInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bundle test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.install = self.root / 'install'
        self.install.mkdir()
        shutil.copytree(ROOT / 'install/lib', self.install / 'lib')
        shutil.copy(ROOT / 'install/deferred.sh', self.install / 'deferred.sh')
        source = (ROOT / 'install/install_tools.sh').read_text()
        (self.install / 'install_tools.sh').write_text(source[:source.index('# Claude Code')])
        self.brewfile = self.install / 'brewfile'
        self.brewfile.write_text('brew "jq"\ncask "app"\nmas "App with spaces", id: 42\n')
        self.pending = self.root / 'state/dotfiles/deferred-installs'
        (self.root / 'bin').mkdir()
        self.env = dict(os.environ, PATH=str(self.root / 'bin') + ':' + os.environ['PATH'],
                        XDG_STATE_HOME=str(self.root / 'state'), CALLS=str(self.root / 'calls'),
                        DOTFILES_DEFER_PROMPTS='0', INSTALL_STATUS='0', CHECK_STATUS='0', CLEANUP_STATUS='0')
        self.executable('uname', '#!/bin/sh\necho Darwin\n')
        self.executable('brew', r'''#!/bin/sh
printf '%s\n' "$*" >> "$CALLS"
case "$1 $2" in
  'bundle install')
    if [ "${DOTFILES_DEFER_PROMPTS:-0}" = 1 ]; then
      [ "$SUDO_ASKPASS" = /usr/bin/false ] || exit 98
      [ "$HOMEBREW_BUNDLE_MAS_SKIP" = '42 ' ] || exit 98
    fi
    exit "$INSTALL_STATUS" ;;
  'bundle list') echo app ;;
  'bundle check')
    [ "$HOMEBREW_BUNDLE_CASK_SKIP" = 'app ' ] || exit 98
    [ "$HOMEBREW_BUNDLE_MAS_SKIP" = '42 ' ] || exit 98
    exit "$CHECK_STATUS" ;;
  'bundle cleanup') exit "$CLEANUP_STATUS" ;;
  *) exit 99 ;;
esac
''')

    def executable(self, name, text):
        path = self.root / 'bin' / name
        path.write_text(text)
        path.chmod(0o755)

    def run_script(self, name='install_tools.sh', success=True):
        result = subprocess.run(['bash', str(self.install / name)], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

    def calls(self):
        path = self.root / 'calls'
        return path.read_text().splitlines() if path.exists() else []

    def test_install_then_cleanup_the_same_brewfile(self):
        self.run_script()
        self.assertEqual(self.calls(), [
            f'bundle install --file={self.brewfile}',
            f'bundle cleanup --file={self.brewfile} --brews --cask --tap --mas --force',
        ])

    def test_failed_install_never_cleans_up(self):
        self.env['INSTALL_STATUS'] = '1'
        self.run_script(success=False)
        self.assertEqual(len(self.calls()), 1)

    def test_cleanup_failure_is_returned(self):
        self.env['CLEANUP_STATUS'] = '1'
        self.run_script(success=False)

    def test_missing_brewfile_never_calls_brew(self):
        self.brewfile.unlink()
        self.run_script(success=False)
        self.assertEqual(self.calls(), [])

    def test_deferred_cask_failure_retries_bundle_before_cleanup(self):
        self.env.update(DOTFILES_DEFER_PROMPTS='1', INSTALL_STATUS='1')
        self.run_script()
        self.assertTrue(self.pending.exists())
        self.assertFalse(any('cleanup' in call for call in self.calls()))
        self.env.update(DOTFILES_DEFER_PROMPTS='0', INSTALL_STATUS='0')
        self.run_script('deferred.sh')
        self.assertFalse(self.pending.exists())
        self.assertTrue(self.calls()[-2].startswith('bundle install '))
        self.assertTrue(self.calls()[-1].startswith('bundle cleanup '))

    def test_deferred_formula_failure_stops_install(self):
        self.env.update(DOTFILES_DEFER_PROMPTS='1', INSTALL_STATUS='1', CHECK_STATUS='1')
        self.run_script(success=False)
        self.assertFalse(any('cleanup' in call for call in self.calls()))

    def test_failed_deferred_bundle_keeps_pending_file(self):
        self.env['DOTFILES_DEFER_PROMPTS'] = '1'
        self.run_script()
        self.env.update(DOTFILES_DEFER_PROMPTS='0', INSTALL_STATUS='1')
        self.run_script('deferred.sh', success=False)
        self.assertTrue(self.pending.exists())
        self.assertFalse(any('cleanup' in call for call in self.calls()))

    def test_failed_deferred_cleanup_keeps_pending_file(self):
        self.env['DOTFILES_DEFER_PROMPTS'] = '1'
        self.run_script()
        self.env.update(DOTFILES_DEFER_PROMPTS='0', CLEANUP_STATUS='1')
        self.run_script('deferred.sh', success=False)
        self.assertTrue(self.pending.exists())

    def test_no_pending_install_does_nothing(self):
        self.run_script('deferred.sh')
        self.assertEqual(self.calls(), [])


if __name__ == '__main__':
    unittest.main()

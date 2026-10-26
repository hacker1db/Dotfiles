import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / 'zsh/functions.zsh').read_text()
FUNCTION = SOURCE[SOURCE.index('function update-node-tools(){'):SOURCE.index('\nfunction get-azsubcount(){')]


class UpdateTests(unittest.TestCase):
    def run_update(self, list_status=0, update_status=0, remove_status=0,
                   packages=True, stale=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / 'tools'
            tools.mkdir()
            pnpm_home = root / 'pnpm'
            (pnpm_home / 'bin').mkdir(parents=True)
            pnpm = tools / 'pnpm'
            pnpm.write_text('''#!/bin/zsh
print -r -- "$*" >> "$CALLS"
case "$1" in
    list)
        [[ "$PACKAGES" == yes ]] && print '├── prettier@3.9.10'
        if [[ "$STALE" == yes ]] && ! grep -q '^remove' "$CALLS"; then
            print '├── plan-manager@0.3.0'
        fi
        exit "$LIST_STATUS" ;;
    update) exit "$UPDATE_STATUS" ;;
    remove) exit "$REMOVE_STATUS" ;;
    *) exit 99 ;;
esac
''')
            pnpm.chmod(0o755)
            env = dict(os.environ, PATH=str(tools) + ':/usr/bin:/bin',
                       PNPM_HOME=str(pnpm_home), CALLS=str(root / 'calls'),
                       LIST_STATUS=str(list_status), UPDATE_STATUS=str(update_status),
                       REMOVE_STATUS=str(remove_status),
                       PACKAGES='yes' if packages else 'no',
                       STALE='yes' if stale else 'no')
            script = FUNCTION + '''
original_path="$PATH"
original_home="$PNPM_HOME"
update-node-tools
result=$?
[[ "$PATH" == "$original_path" && "$PNPM_HOME" == "$original_home" ]] || exit 99
exit $result
'''
            result = subprocess.run(['/bin/zsh', '-f', '-c', script], env=env,
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 99, result.stderr)
            return result, (root / 'calls').read_text()

    def test_success_preserves_environment_and_updates(self):
        result, calls = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('update --global --latest', calls)
        self.assertNotIn('remove', calls)
        self.assertIn('All global pnpm packages updated!', result.stdout)

    def test_update_failure_is_not_reported_as_success(self):
        result, calls = self.run_update(update_status=1)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('All global pnpm packages updated!', result.stdout)

    def test_listing_failure_does_not_start_update(self):
        result, calls = self.run_update(list_status=1)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('update --global', calls)

    def test_unmanaged_package_is_removed_before_update(self):
        result, calls = self.run_update(stale=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('remove --global plan-manager', calls)
        self.assertLess(calls.index('remove --global plan-manager'),
                        calls.index('update --global --latest'))

    def test_removal_failure_does_not_start_update(self):
        result, calls = self.run_update(stale=True, remove_status=1)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn('update --global', calls)

    def test_only_unmanaged_packages_does_not_start_update(self):
        result, calls = self.run_update(packages=False, stale=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('remove --global plan-manager', calls)
        self.assertNotIn('update --global', calls)
        self.assertIn('No global pnpm packages found.', result.stdout)

    def test_empty_install_does_not_start_update(self):
        result, calls = self.run_update(packages=False)
        self.assertEqual(result.returncode, 0)
        self.assertNotIn('update --global', calls)


if __name__ == '__main__':
    unittest.main()

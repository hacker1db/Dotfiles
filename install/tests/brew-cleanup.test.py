import os
from pathlib import Path
import subprocess
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


if __name__ == '__main__':
    unittest.main()

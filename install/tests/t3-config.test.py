import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'bin/t3-config'


class T3ConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.live = self.root / 'userdata'
        self.live.mkdir()
        self.snapshot = self.root / 'preferences.json'
        self.put('client-settings.json', {'fontSizeCode': 13, 'favorites': ['private-id']})
        self.put('settings.json', {
            'defaultAutoPull': True,
            'worktreesDirectory': '/private/worktrees',
            'providerInstances': {'antigravity': {
                'driver': 'antigravity', 'enabled': True,
                'config': {'authMethod': 'oauth-personal', 'apiKey': 'secret-fixture',
                           'binaryPath': '/private/bin/agent'}
            }},
        })
        self.put('keybindings.json', [{'key': 'mod+j', 'command': 'terminal.toggle'},
                                     {'key': 'mod+g', 'command': 'script.private.run'}])

    def put(self, name, value):
        (self.live / name).write_text(json.dumps(value))

    def run_tool(self, action, *extra, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), action, '--userdata', str(self.live),
                                 '--config', str(self.snapshot), *extra], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def test_export_excludes_credentials_and_machine_state(self):
        self.run_tool('export')
        text = self.snapshot.read_text()
        for excluded in ['secret-fixture', 'apiKey', '/private/', 'private-id', 'script.private']:
            self.assertNotIn(excluded, text)
        self.assertEqual(json.loads(text)['settings.json']['providerInstances']['antigravity']['config'],
                         {'authMethod': 'oauth-personal'})

    def test_apply_preserves_local_values_and_is_idempotent(self):
        self.run_tool('export')
        self.put('client-settings.json', {'fontSizeCode': 18, 'favorites': ['keep-me']})
        before = (self.live / 'client-settings.json').read_bytes()
        self.run_tool('apply')
        client = json.loads((self.live / 'client-settings.json').read_text())
        self.assertEqual(client, {'fontSizeCode': 13, 'favorites': ['keep-me']})
        server = json.loads((self.live / 'settings.json').read_text())
        self.assertEqual(server['providerInstances']['antigravity']['config']['apiKey'], 'secret-fixture')
        self.assertEqual(server['worktreesDirectory'], '/private/worktrees')
        self.assertEqual(len(json.loads((self.live / 'keybindings.json').read_text())), 2)
        backups = list(self.live.glob('*.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), before)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
        self.run_tool('apply')
        self.assertEqual(list(self.live.glob('*.backup-*')), backups)

    def test_rejects_secrets_in_snapshot_before_any_write(self):
        self.run_tool('export')
        snapshot = json.loads(self.snapshot.read_text())
        snapshot['settings.json']['providerInstances']['antigravity']['config']['apiKey'] = 'bad'
        self.snapshot.write_text(json.dumps(snapshot))
        before = {p.name: p.read_bytes() for p in self.live.iterdir()}
        self.run_tool('apply', ok=False)
        self.assertEqual({p.name: p.read_bytes() for p in self.live.iterdir()}, before)

    def test_dry_run_and_symlink_refusal(self):
        self.run_tool('export')
        self.put('client-settings.json', {'fontSizeCode': 20})
        before = {p.name: p.read_bytes() for p in self.live.iterdir()}
        self.run_tool('apply', '--dry-run')
        self.assertEqual({p.name: p.read_bytes() for p in self.live.iterdir()}, before)
        path = self.live / 'settings.json'
        target = self.root / 'local-settings.json'
        path.rename(target)
        path.symlink_to(target)
        self.run_tool('apply', ok=False)
        self.assertEqual((self.live / 'client-settings.json').read_bytes(), before['client-settings.json'])

    def test_fresh_machine_and_missing_export(self):
        self.run_tool('export')
        for path in self.live.iterdir():
            path.unlink()
        self.run_tool('export', ok=False)
        self.run_tool('apply')
        self.assertEqual(json.loads((self.live / 'settings.json').read_text()),
                         json.loads(self.snapshot.read_text())['settings.json'])


if __name__ == '__main__':
    unittest.main()

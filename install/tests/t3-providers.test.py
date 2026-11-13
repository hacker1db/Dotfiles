import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class T3ProvidersTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='t3 providers ')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / 'home'
        self.root = self.home / '.dotfiles/main'
        for name in ['bin/t3-config', 'install/t3-config.sh', 'install.sh',
                     'install/lib/log.sh', 'install/lib/env.sh', 'config/t3code/profiles.json',
                     'config/t3code/client-settings.json', 'config/t3code/keybindings.json']:
            dest = self.root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, dest)
        for profile in ['personal', 'subscription', 'foundry']:
            self.write(self.root / f'claude/profiles/{profile}/settings.json', {})
            self.write(self.home / f'.claude-{profile}/settings.json', {'model': 'fixture-model'})
        for directory in ['.codex', '.codex_foundry']:
            path = self.home / directory / 'config.toml'
            path.parent.mkdir(parents=True)
            path.write_text('model = "fixture-model"\n')
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        for path in [self.bin / 'codex', self.home / '.local/bin/claude']:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('#!/bin/sh\nexit 0\n')
            path.chmod(0o755)
        self.env = {**os.environ, 'HOME': str(self.home), 'PATH': str(self.bin) + os.pathsep + os.environ['PATH']}
        self.settings = self.home / '.t3/userdata/settings.json'
        self.initial = {'defaultModelSelection': {'instanceId': 'codex', 'model': 'keep-model'},
                        'providerInstances': {'antigravity': {'driver': 'antigravity', 'config': {'apiKey': 'local-value'}},
                                              'codex': {'driver': 'codex', 'config': {'shadowHomePath': 'old', 'localOption': True}}}}
        self.write(self.settings, self.initial)

    def write(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))

    def run_install(self, *args, status=0):
        result = subprocess.run(['bash', str(self.root / 'install.sh'), 't3-config', *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, status, result.stdout + result.stderr)
        return result

    def read(self):
        return json.loads(self.settings.read_text())

    def test_install_maps_all_profiles_and_preserves_local_state(self):
        self.run_install()
        result = self.read()
        providers = result['providerInstances']
        self.assertEqual(len(providers), 6)
        self.assertEqual(providers['antigravity'], self.initial['providerInstances']['antigravity'])
        self.assertEqual(result['defaultModelSelection'], self.initial['defaultModelSelection'])
        for name, profile in [('claudeAgent', 'personal'), ('dotfiles-claude-subscription', 'subscription'),
                              ('dotfiles-claude-foundry', 'foundry')]:
            self.assertEqual(providers[name]['driver'], 'claudeAgent')
            self.assertEqual(providers[name]['config']['homePath'], str(self.home / f'.claude-{profile}'))
            self.assertEqual(providers[name]['config']['binaryPath'], str(self.home / '.local/bin/claude'))
            self.assertTrue(providers[name]['enabled'])
        self.assertEqual(providers['codex']['config']['homePath'], str(self.home / '.codex'))
        self.assertEqual(providers['codex']['config']['shadowHomePath'], '')
        self.assertEqual(providers['codex']['config']['setupMode'], 'existing')
        self.assertTrue(providers['codex']['config']['localOption'])
        self.assertEqual(providers['dotfiles-codex-home-foundry']['config']['homePath'], str(self.home / '.codex_foundry'))
        backups = list(self.settings.parent.glob('*.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(json.loads(backups[0].read_text()), self.initial)
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
        self.run_install()
        self.run_install('--check')
        self.assertEqual(list(self.settings.parent.glob('*.backup-*')), backups)

    def test_missing_foundry_remains_visible_and_disabled(self):
        (self.home / '.claude-foundry/settings.json').unlink()
        (self.home / '.codex_foundry/config.toml').unlink()
        result = self.run_install(status=2)
        providers = self.read()['providerInstances']
        self.assertFalse(providers['dotfiles-claude-foundry']['enabled'])
        self.assertFalse(providers['dotfiles-codex-home-foundry']['enabled'])
        self.assertTrue(providers['claudeAgent']['enabled'])
        self.assertIn('disabled; requires', result.stdout)
        self.run_install('--check', status=2)
        self.write(self.home / '.claude-foundry/settings.json', {})
        (self.home / '.codex_foundry/config.toml').write_text('')
        self.run_install()
        self.assertTrue(self.read()['providerInstances']['dotfiles-codex-home-foundry']['enabled'])

    def test_discovery_and_unsupported_named_profile(self):
        directory = self.home / '.codex_work'
        directory.mkdir()
        (directory / 'config.toml').write_text('')
        (directory / 'review.config.toml').write_text('model="fixture"')
        result = self.run_install(status=2)
        providers = self.read()['providerInstances']
        self.assertTrue(providers['dotfiles-codex-home-work']['enabled'])
        self.assertFalse(providers['dotfiles-codex-profile-work-review']['enabled'])
        self.assertIn('app-server does not support --profile', result.stdout)
        self.assertEqual(providers['dotfiles-codex-profile-work-review']['config']['launchArgs'], '')

    def test_dry_run_and_check_do_not_write(self):
        before = self.settings.read_bytes()
        self.run_install('--dry-run')
        self.run_install('--check', status=2)
        self.assertEqual(self.settings.read_bytes(), before)
        self.assertEqual(list(self.settings.parent.glob('*.backup-*')), [])

    def test_wrong_driver_and_symlink_fail_before_writes(self):
        data = self.initial
        data['providerInstances']['claudeAgent'] = {'driver': 'codex'}
        self.write(self.settings, data)
        before = self.settings.read_bytes()
        self.run_install(status=1)
        self.assertEqual(self.settings.read_bytes(), before)
        target = self.settings.with_name('real-settings.json')
        self.settings.rename(target)
        self.settings.symlink_to(target)
        self.run_install(status=1)
        self.assertEqual(target.read_bytes(), before)

    def test_duplicate_home_names_fail_before_writes(self):
        for name in ['.codex-work', '.codex_work']:
            p = self.home / name
            p.mkdir()
            (p / 'config.toml').write_text('')
        before = self.settings.read_bytes()
        self.run_install(status=1)
        self.assertEqual(self.settings.read_bytes(), before)

    def test_missing_binary_disables_profiles(self):
        (self.home / '.local/bin/claude').unlink()
        self.run_install(status=2)
        providers = self.read()['providerInstances']
        self.assertFalse(providers['claudeAgent']['enabled'])
        self.assertTrue(providers['codex']['enabled'])

    def test_link_runs_provider_reconciliation_in_integration_phase(self):
        text = (ROOT / 'install/link.sh').read_text()
        call = text.index('bash "$DOTFILES/install/t3-config.sh"')
        self.assertGreater(call, text.index('[[ "$LINK_PHASE" == files ]] && exit 0'))
        self.assertGreater(call, text.index('bash "$DOTFILES/install/claude-profiles.sh"'))
        self.assertGreater(call, text.index('! reconcile_codex_config'))


    def test_link_skips_without_t3_and_only_warns_on_incomplete_profiles(self):
        text = (ROOT / 'install/link.sh').read_text()
        block = text[text.index('if [[ -d "$HOME/.t3" ]]; then'):text.index('Skipping T3 provider profiles')]
        self.assertIn('bash "$DOTFILES/install/t3-config.sh"', block)
        incomplete = block[block.index('2)'):block.index('*)')]
        self.assertNotIn('LINK_FAILURE', incomplete)
        self.assertIn('LINK_FAILURE=1', block[block.index('*)'):])

    def test_install_links_ui_files_and_backs_up_existing(self):
        userdata = self.settings.parent
        self.write(userdata / 'keybindings.json', [{'key': 'local', 'command': 'local'}])
        self.run_install('--check', status=2)
        self.run_install('--dry-run')
        self.assertFalse((userdata / 'keybindings.json').is_symlink())
        self.run_install()
        for name in ['client-settings.json', 'keybindings.json']:
            target = userdata / name
            self.assertTrue(target.is_symlink())
            self.assertEqual(Path(os.readlink(target)), self.root / 'config/t3code' / name)
        backups = list(userdata.glob('keybindings.json.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(json.loads(backups[0].read_text()), [{'key': 'local', 'command': 'local'}])
        self.assertFalse(list(userdata.glob('client-settings.json.backup-*')))
        self.run_install('--check')

if __name__ == '__main__':
    unittest.main()

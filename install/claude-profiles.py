#!/usr/bin/env python3
import argparse
import copy
import json
import os
from pathlib import Path
import shutil
import tempfile
import time


def merge(left, right):
    result = copy.deepcopy(left)
    for key, value in right.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def load(path):
    return json.loads(path.read_text()) if path.exists() else {}


def atomic_json(path, value):
    data = json.dumps(value, indent=2, sort_keys=True) + '\n'
    if path.is_symlink():
        raise ValueError('Refusing symlinked generated settings: ' + str(path))
    if path.exists() and path.read_text() == data:
        path.chmod(0o600)
        return
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(data)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--foundry-settings', type=Path)
    parser.add_argument('--skip-foundry', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    home = Path.home()
    os.umask(0o077)
    generated = root / 'claude/.local/profiles'
    if generated.is_symlink() or generated.parent.is_symlink():
        raise ValueError('Refusing symlinked generated directory')
    if not args.check:
        generated.mkdir(parents=True, exist_ok=True)
        generated.chmod(0o700)
    base = load(root / 'claude/settings.base.json')
    work = load(root / 'claude/settings.work.json')
    local_path = args.foundry_settings or home / '.config/claude-code/foundry-profile.json'
    local = {} if args.skip_foundry else load(local_path)
    allowed = {'ANTHROPIC_FOUNDRY_RESOURCE', 'ANTHROPIC_FOUNDRY_BASE_URL',
               'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_SONNET_MODEL',
               'ANTHROPIC_DEFAULT_HAIKU_MODEL'}
    if set(local) - {'env'} or set(local.get('env', {})) - allowed:
        raise ValueError('Foundry local input must contain only documented nonsecret env fields')
    env = local.get('env', {})
    if env.get('ANTHROPIC_FOUNDRY_BASE_URL') and not env['ANTHROPIC_FOUNDRY_BASE_URL'].startswith('https://'):
        raise ValueError('Foundry endpoint requires HTTPS')
    conflicts = sorted(k for k, v in os.environ.items() if v and
                       (k.startswith('ANTHROPIC_') or k.startswith('CLAUDE_CODE_USE_') or
                        k in {'CLAUDE_CODE_OAUTH_TOKEN', 'CLAUDE_CODE_SKIP_FOUNDRY_AUTH'}))
    if conflicts:
        print('Before direct invocation, unset conflicting inherited variables: ' + ', '.join(conflicts))
    incomplete = bool(conflicts)
    profiles = ('subscription', 'personal') if args.skip_foundry else ('foundry', 'subscription', 'personal')
    for profile in profiles:
        directory = home / ('.claude-' + profile)
        if directory.is_symlink():
            raise ValueError('Refusing symlinked profile directory: ' + str(directory))
        if not args.check:
            directory.mkdir(mode=0o700, exist_ok=True)
            directory.chmod(0o700)
        if profile == 'foundry' and not any(env.get(k) for k in ('ANTHROPIC_FOUNDRY_RESOURCE', 'ANTHROPIC_FOUNDRY_BASE_URL')):
            print('Foundry not installed: supply explicit resource or HTTPS endpoint in ' + str(local_path))
            incomplete = True
            continue
        dest = directory / 'settings.json'
        target = generated / (profile + '.json')
        if args.check:
            problems = []
            if not dest.is_symlink() or dest.resolve() != target.resolve():
                problems.append('settings target mismatch')
            if not target.is_file() or target.is_symlink():
                problems.append('missing or symlinked generated settings')
            if not directory.exists() or directory.stat().st_mode & 0o777 != 0o700:
                problems.append('profile directory must have mode 700')
            if target.is_file() and target.stat().st_mode & 0o777 != 0o600:
                problems.append('generated settings must have mode 600')
            existing = load(dest)
            provider = existing.get('env', {})
            expected = '1' if profile == 'foundry' else '0'
            if provider.get('CLAUDE_CODE_USE_FOUNDRY') != expected:
                problems.append('Foundry provider mismatch')
            for key in ('CLAUDE_CODE_USE_BEDROCK', 'CLAUDE_CODE_USE_VERTEX'):
                if provider.get(key) != '0':
                    problems.append('conflicting provider: ' + key)
            if profile != 'foundry':
                if existing.get('forceLoginMethod') != 'claudeai':
                    problems.append('claude.ai login method missing')
                if existing.get('apiKeyHelper') or any(value and key.startswith('ANTHROPIC_') for key, value in provider.items()):
                    problems.append('unexpected authentication or model override')
            hooks = existing.get('hooks', {})
            for event, registrations in work.get('hooks', {}).items():
                for registration in registrations:
                    if profile != 'personal' and registration not in hooks.get(event, []):
                        problems.append('missing work hook registration')
            if profile == 'personal' and any(marker in json.dumps(hooks).lower() for marker in ('sonar-secrets/', 'pre-commit-security.sh', 'ggshield', 'gitguardian')):
                problems.append('work hook found in personal profile')
            print(profile + ': ' + ('; '.join(problems) if problems else 'settings, permissions, provider, and hook scope verified'))
            incomplete |= bool(problems)
            continue
        existing = load(dest)
        settings = merge(base, existing)
        for event, registrations in list(settings.get('hooks', {}).items()):
            kept = []
            for registration in registrations:
                registration['hooks'] = [hook for hook in registration.get('hooks', [])
                                         if 'sonar-secrets/' not in hook.get('command', '')]
                if registration['hooks']:
                    kept.append(registration)
            if kept:
                settings['hooks'][event] = kept
            else:
                del settings['hooks'][event]
        if profile != 'personal':
            existing_hooks = copy.deepcopy(settings.get('hooks', {}))
            for event, registrations in work.get('hooks', {}).items():
                entries = existing_hooks.setdefault(event, [])
                for registration in registrations:
                    if registration not in entries:
                        entries.append(registration)
            settings['hooks'] = existing_hooks
        else:
            filtered = {}
            for event, registrations in settings.get('hooks', {}).items():
                entries = []
                for registration in registrations:
                    registration = copy.deepcopy(registration)
                    registration['hooks'] = [h for h in registration.get('hooks', []) if not any(
                        marker in h.get('command', '') for marker in ('sonar-secrets/', 'pre-commit-security.sh', 'ggshield', 'gitguardian'))]
                    if registration['hooks']:
                        entries.append(registration)
                if entries:
                    filtered[event] = entries
            settings['hooks'] = filtered
        settings.pop('apiKeyHelper', None)
        settings['env'] = {k: v for k, v in settings.get('env', {}).items()
                           if not k.startswith(('ANTHROPIC_', 'CLAUDE_CODE_USE_')) and k not in
                           {'CLAUDE_CODE_OAUTH_TOKEN', 'CLAUDE_CODE_SKIP_FOUNDRY_AUTH'}}
        settings['env'].update({'CLAUDE_CODE_USE_FOUNDRY': '0', 'CLAUDE_CODE_USE_BEDROCK': '0', 'CLAUDE_CODE_USE_VERTEX': '0'})
        if profile == 'foundry':
            settings = merge(settings, load(root / 'claude/settings.foundry.json'))
            settings = merge(settings, local)
        else:
            settings['forceLoginMethod'] = 'claudeai'
            settings['model'] = base['model']
        if 'statusLine' in existing:
            settings['statusLine'] = existing['statusLine']
        if dest.exists() or dest.is_symlink():
            if not dest.is_symlink() or dest.resolve() != target.resolve():
                backup = directory / ('settings.json.backup.' + str(time.time_ns()))
                shutil.copy2(dest, backup)
                backup.chmod(0o600)
        atomic_json(target, settings)
        if not dest.is_symlink() or dest.resolve() != target.resolve():
            link = directory / ('settings.json.link.' + str(time.time_ns()))
            link.symlink_to(target)
            os.replace(link, dest)
        print('Configured ' + profile + ': ' + str(dest))
    for registrations in work.get('hooks', {}).values():
        for registration in registrations:
            for hook in registration.get('hooks', []):
                command = hook.get('command', '')
                if command.startswith('~/') and (not (home / command[2:]).is_file() or not os.access(home / command[2:], os.X_OK)):
                    print('Missing work hook prerequisite or executable permission: ' + command)
                    incomplete = True
    return 2 if incomplete else 0


if __name__ == '__main__':
    raise SystemExit(main())

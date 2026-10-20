import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { test } from 'node:test'

const root = resolve(import.meta.dirname, '../..')
const checker = join(root, 'install/check-codex-writable-root.mjs')
const expected = '/tmp/plans'

function check(source) {
  const dir = mkdtempSync(join(tmpdir(), 'codex-writable-root-'))
  const config = join(dir, 'config.toml')
  writeFileSync(config, source)
  return spawnSync(process.execPath, [checker, config, expected], { encoding: 'utf8' }).status
}

test('only sandbox writable_roots grants plan-library access', () => {
  assert.equal(check(`[projects."${expected}"]\ntrust_level = "trusted"\n`), 1)
  assert.equal(check(`# ${expected}\n[sandbox_workspace_write]\nwritable_roots = ["/tmp/other"]\n`), 1)
  assert.equal(check(`[sandbox_workspace_write]\nwritable_roots = ["/tmp/other", "${expected}"]\n`), 0)
  assert.equal(check(`[sandbox_workspace_write]\nwritable_roots = []\nwritable_roots = ["${expected}"]\n`), 2)
})

test('Git identity is configured only after the final local config link', () => {
  const tools = readFileSync(join(root, 'install/tools.zsh'), 'utf8')
  const link = readFileSync(join(root, 'install/link.zsh'), 'utf8')
  assert.doesNotMatch(tools, /Configuring Git identity/)
  assert.ok(link.indexOf('Configuring Git identity') > link.indexOf('Ensuring ~\/.gitconfig-local link'))
  assert.ok(link.indexOf('Configuring Git identity') > link.indexOf('link_file "$SOURCE_CANDIDATE" "$LOCAL_FILE"'))
})

test('new installer scripts contain no explanatory comments', () => {
  for (const file of ['claude-profiles.zsh', 'dotnet.zsh', 'lib.zsh', 'link.zsh', 'node.zsh', 'osx.zsh', 'theme.zsh', 'tmux-plugins.zsh', 'tools.zsh']) {
    const comments = readFileSync(join(root, 'install', file), 'utf8')
      .split('\n')
      .filter(line => /^\s*#/.test(line) && !/^#!/.test(line))
    assert.deepEqual(comments, [], file)
  }
})

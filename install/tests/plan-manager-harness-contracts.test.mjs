import assert from 'node:assert/strict'
import { chmodSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

function read(path) {
  return readFileSync(join(root, path), 'utf8')
}

const hostedUrl = 'https://planmanager.hacker1db.dev'
for (const path of [
  'codex/AGENTS.md',
  'config/opencode/AGENTS.md',
  'config/copilot/copilot-instructions.md',
  'copilot/copilot-instructions.md',
]) {
  assert.equal(realpathSync(join(root, path)), join(root, 'global/AGENTS.md'))
}

const harnesses = [
  {
    name: 'Claude Code',
    policy: [
      'claude/commands/plans.md',
      'claude/output-styles/plan-browser.md',
    ],
    mockAdapter(artifact) {
      assert.match(read('claude/commands/plans.md'), /Use the `plans` skill/)
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'Codex desktop/CLI',
    policy: ['global/AGENTS.md'],
    mockAdapter(artifact) {
      assert.match(read('global/AGENTS.md'), /Codex uses `\$plans`/)
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'OpenCode',
    policy: [
      'global/AGENTS.md',
      'config/opencode/command/plans.md',
    ],
    mockAdapter(artifact) {
      assert.match(read('config/opencode/command/plans.md'), /Delegate to the `plan` CLI/)
      assert.match(read('global/AGENTS.md'), /OpenCode and Copilot use `\/plans`/)
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'Copilot',
    policy: ['global/AGENTS.md'],
    mockAdapter(artifact) {
      assert.match(read('global/AGENTS.md'), /OpenCode and Copilot use `\/plans`/)
      return ['capture', artifact, '--json']
    },
  },
]

for (const harness of harnesses) {
  const contract = harness.policy.map(read).join('\n')
  assert.match(contract, /plan capture <artifact> --json/, `${harness.name} lacks artifact capture`)
  assert.match(contract, /Before the final response/i, `${harness.name} lacks finalization guard`)
  assert.match(contract, /durable plan/i, `${harness.name} lacks durable-plan boundary`)
  assert.ok(contract.includes(hostedUrl), `${harness.name} lacks the hosted Plan Manager URL`)
  assert.match(contract, /plan push <id> --json/, `${harness.name} does not publish plan mutations by default`)
  assert.match(contract, /local-only/i, `${harness.name} lacks the explicit local-only override`)
  assert.match(contract, /native|built-in|Plan agent/i, `${harness.name} does not preserve native planning`)
}

const settings = JSON.parse(read('claude/settings.base.json'))
assert.equal(settings.plansDirectory, '~/notes/SecondBrain/4.Resources/plans')
assert.match(read('claude/output-styles/plan-browser.md'), /Do not generate adjacent HTML files/)

const bootstrap = read('install/plan-manager-bootstrap.sh')
for (const target of [
  '$HOME/.copilot/copilot-instructions.md',
  '$HOME/.codex/AGENTS.md',
  '$HOME/.config/opencode/AGENTS.md',
  '$HOME/.config/opencode/command/plans.md',
]) {
  assert.ok(bootstrap.includes(target), `installer does not manage ${target}`)
}
assert.equal((bootstrap.match(/"\$DOTFILES\/global\/AGENTS\.md"/g) || []).length, 3)

const planBin = process.env.PLAN_MANAGER_TEST_BIN
if (planBin) {
  const fixture = mkdtempSync(join(tmpdir(), 'plan-harness-contract-'))
  try {
    const pandoc = join(fixture, 'pandoc')
    writeFileSync(pandoc, `#!/usr/bin/env node
let input = ''
process.stdin.setEncoding('utf8')
process.stdin.on('data', chunk => { input += chunk })
process.stdin.on('end', () => {
  const text = input.replace(/<[^>]+>/g, ' ').replace(/\\s+/g, ' ').trim()
  process.stdout.write('# Captured\\n\\n' + text + '\\n')
})
`)
    chmodSync(pandoc, 0o755)
    for (const harness of harnesses) {
      const key = harness.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')
      const planHome = join(fixture, key, 'plans')
      const artifact = join(fixture, `${key}-plan.html`)
      writeFileSync(artifact, `<html><head><title>${harness.name} Plan</title></head><body>Durable harness plan</body></html>`)
      const env = { ...process.env, PLAN_HOME: planHome, PLAN_PANDOC: pandoc }
      const command = harness.mockAdapter(artifact)
      const first = spawnSync(process.execPath, [planBin, ...command], { encoding: 'utf8', env })
      assert.equal(first.status, 0, `${harness.name} finalization failed: ${first.stderr}`)
      const created = JSON.parse(first.stdout)
      assert.equal(created.capture.action, 'created')
      assert.equal(created.capture.source, artifact)
      assert.ok(created.path.startsWith(planHome))
      assert.ok(created.url.startsWith('http://plans.localhost:4173/plans/'))

      const second = spawnSync(process.execPath, [planBin, ...harness.mockAdapter(artifact)], { encoding: 'utf8', env })
      assert.equal(second.status, 0, `${harness.name} recapture failed: ${second.stderr}`)
      const unchanged = JSON.parse(second.stdout)
      assert.equal(unchanged.capture.action, 'unchanged')
      assert.equal(unchanged.id, created.id)
      assert.equal(unchanged.url, created.url)
    }
  } finally {
    rmSync(fixture, { recursive: true, force: true })
  }
}

process.stdout.write('plan-manager harness contract tests passed\n')

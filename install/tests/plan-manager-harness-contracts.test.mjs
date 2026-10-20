import assert from 'node:assert/strict'
import { chmodSync, existsSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

function read(path) {
  return readFileSync(join(root, path), 'utf8')
}

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
    mockAdapter(artifact) {
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'Codex desktop/CLI',
    mockAdapter(artifact) {
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'OpenCode',
    mockAdapter(artifact) {
      return ['capture', artifact, '--json']
    },
  },
  {
    name: 'Copilot',
    mockAdapter(artifact) {
      return ['capture', artifact, '--json']
    },
  },
]

const settings = JSON.parse(read('claude/settings.base.json'))
assert.equal(settings.plansDirectory, '~/notes/SecondBrain/4.Resources/plans')
const planBrowser = read('claude/output-styles/plan-browser.md')
assert.match(planBrowser, /use the `plans` skill/i)
assert.match(planBrowser, /Do not generate adjacent HTML files/)
assert.doesNotMatch(planBrowser, /plan push/)
assert.equal(existsSync(join(root, 'claude/commands/plans.md')), false)
assert.equal(existsSync(join(root, 'config/opencode/command/plans.md')), false)

const globalPolicy = read('global/AGENTS.md')
assert.match(globalPolicy, /canonical source of operational instructions/)
assert.match(globalPolicy, /publish every successful plan mutation/)
assert.match(globalPolicy, /local-only handling/)
assert.doesNotMatch(globalPolicy, /plan push/)
assert.match(globalPolicy, /For every pull request:/)
assert.match(globalPolicy, /Search the target repository for an existing GitHub issue/)
assert.match(globalPolicy, /Never create an unlinked pull request/)
assert.match(globalPolicy, /Closes #<number>/)
assert.match(globalPolicy, /Refs #<number>/)

const githubCommand = read('claude/commands/github-cli.md')
assert.match(githubCommand, /Every pull request must reference a GitHub issue/)
assert.match(githubCommand, /gh pr view --json body/)

const pullRequestTemplate = read('.github/pull_request_template.md')
assert.match(pullRequestTemplate, /Linked GitHub issue \(required\)/)
assert.match(pullRequestTemplate, /Closes #<issue-number>/)
assert.match(pullRequestTemplate, /## Validation/)
assert.match(pullRequestTemplate, /## Evidence/)
assert.match(pullRequestTemplate, /## Rollback/)

const reviewGuidance = read('REVIEW.md')
assert.match(reviewGuidance, /concrete defect, violated requirement, or meaningful maintenance problem/)
assert.match(reviewGuidance, /Do not invent a minimum number of findings/)
assert.match(reviewGuidance, /Stop when no evidence-backed findings remain/)

const bootstrap = read('install/plan-manager-bootstrap.sh')
for (const target of [
  '$HOME/.copilot/copilot-instructions.md',
  '$HOME/.codex/AGENTS.md',
  '$HOME/.config/opencode/AGENTS.md',
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

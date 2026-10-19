#!/usr/bin/env node

import { chmod, mkdir, open, readFile, rename, stat, unlink } from 'node:fs/promises'
import { dirname } from 'node:path'

const [templatePath, destination, home, plan, worktree, planRoot, runtimePath, cliIdentity] = process.argv.slice(2)

if (!cliIdentity) {
  process.stderr.write('Usage: render-plan-launchagent.mjs <template> <destination> <home> <plan> <worktree> <plan-root> <path> <cli-identity>\n')
  process.exit(2)
}

function xml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;')
}

const replacements = new Map([
  ['@@HOME@@', home],
  ['@@PLAN@@', plan],
  ['@@WORKTREE@@', worktree],
  ['@@PLAN_ROOT@@', planRoot],
  ['@@PATH@@', runtimePath],
  ['@@CLI_ID@@', cliIdentity],
])

let content = await readFile(templatePath, 'utf8')
for (const [placeholder, value] of replacements) {
  content = content.replaceAll(placeholder, xml(value))
}
if (/@@[A-Z_]+@@/.test(content)) throw new Error('LaunchAgent template contains unresolved placeholders')

let previous = null
let mode = 0o644
try {
  previous = await readFile(destination, 'utf8')
  mode = (await stat(destination)).mode
} catch (error) {
  if (error.code !== 'ENOENT') throw error
}

if (previous === content) {
  process.stdout.write('unchanged\n')
  process.exit(0)
}

await mkdir(dirname(destination), { recursive: true })
const temporaryPath = `${destination}.tmp-${process.pid}-${Date.now()}`
const handle = await open(temporaryPath, 'wx', mode)
try {
  await handle.writeFile(content, 'utf8')
  await handle.sync()
  await handle.close()
  await chmod(temporaryPath, mode)
  await rename(temporaryPath, destination)
} catch (error) {
  await handle.close().catch(() => {})
  await unlink(temporaryPath).catch(() => {})
  throw error
}

process.stdout.write('changed\n')

#!/usr/bin/env node

import { chmod, copyFile, mkdir, open, readFile, rename, stat, unlink } from 'node:fs/promises'
import { dirname } from 'node:path'

const [configPath, planRoot] = process.argv.slice(2)

if (!configPath || !planRoot) {
  process.stderr.write('Usage: reconcile-codex-config.mjs <config-path> <plan-root>\n')
  process.exit(2)
}

function sectionName(line) {
  const match = line.match(/^\s*\[([^\]]+)\]\s*(?:#.*)?$/)
  return match ? match[1].trim() : null
}

function keyName(line) {
  const match = line.match(/^\s*([A-Za-z0-9_-]+)\s*=/)
  return match ? match[1] : null
}

function findArrayEnd(lines, startLine) {
  let quote = null
  let escaped = false
  let comment = false
  let depth = 0
  let opened = false
  const values = []
  let current = ''
  let valueLine = -1
  let valueEnd = -1

  for (let lineIndex = startLine; lineIndex < lines.length; lineIndex++) {
    const line = lines[lineIndex]
    const start = lineIndex === startLine ? line.indexOf('=') + 1 : 0
    for (let column = start; column < line.length; column++) {
      const char = line[column]
      if (comment) continue
      if (quote) {
        if (escaped) {
          current += char
          escaped = false
        } else if (quote === '"' && char === '\\') {
          current += char
          escaped = true
        } else if (char === quote) {
          values.push(quote === '"' ? JSON.parse(`"${current}"`) : current)
          valueLine = lineIndex
          valueEnd = column + 1
          quote = null
          current = ''
        } else {
          current += char
        }
        continue
      }
      if (char === '#') {
        comment = true
      } else if (char === '"' || char === "'") {
        if (!opened || depth !== 1) throw new Error('writable_roots must be an array of strings')
        quote = char
      } else if (char === '[') {
        depth++
        opened = true
        if (depth > 1) throw new Error('nested writable_roots arrays are not supported')
      } else if (char === ']') {
        depth--
        if (depth === 0) {
          return { endLine: lineIndex, endColumn: column, values, valueLine, valueEnd }
        }
      } else if (opened && depth === 1 && !/[\s,]/.test(char)) {
        throw new Error('writable_roots must be an array of strings')
      }
    }
    comment = false
  }
  throw new Error('unterminated writable_roots array')
}

function commaFollows(lines, valueLine, valueEnd, endLine, endColumn) {
  let comment = false
  for (let lineIndex = valueLine; lineIndex <= endLine; lineIndex++) {
    const line = lines[lineIndex]
    const start = lineIndex === valueLine ? valueEnd : 0
    const limit = lineIndex === endLine ? endColumn : line.length
    for (let column = start; column < limit; column++) {
      const char = line[column]
      if (comment) continue
      if (char === '#') {
        comment = true
      } else if (char === ',') {
        return true
      } else if (!/\s/.test(char)) {
        return false
      }
    }
    comment = false
  }
  return false
}

function reconcile(original) {
  const lines = original.length > 0 ? original.match(/[^\n]*\n|[^\n]+$/g) ?? [] : []
  const sectionIndexes = []

  for (let index = 0; index < lines.length; index++) {
    if (sectionName(lines[index].replace(/\n$/, '')) === 'sandbox_workspace_write') {
      sectionIndexes.push(index)
    }
  }

  if (sectionIndexes.length > 1) {
    throw new Error('duplicate [sandbox_workspace_write] sections')
  }

  if (sectionIndexes.length === 0) {
    const separator = original.length === 0 || original.endsWith('\n') ? '' : '\n'
    return `${original}${separator}\n[sandbox_workspace_write]\nwritable_roots = [${JSON.stringify(planRoot)}]\n`
  }

  const sectionIndex = sectionIndexes[0]
  let sectionEnd = lines.length
  for (let index = sectionIndex + 1; index < lines.length; index++) {
    if (sectionName(lines[index].replace(/\n$/, '')) !== null) {
      sectionEnd = index
      break
    }
  }

  const rootsIndexes = []
  for (let index = sectionIndex + 1; index < sectionEnd; index++) {
    if (keyName(lines[index].replace(/\n$/, '')) === 'writable_roots') rootsIndexes.push(index)
  }
  if (rootsIndexes.length > 1) throw new Error('duplicate writable_roots keys')

  if (rootsIndexes.length === 0) {
    const indent = '  '
    lines.splice(sectionIndex + 1, 0, `${indent}writable_roots = [${JSON.stringify(planRoot)}]\n`)
    return lines.join('')
  }

  const rootsIndex = rootsIndexes[0]
  const parsed = findArrayEnd(lines.map(line => line.replace(/\n$/, '')), rootsIndex)
  if (parsed.values.includes(planRoot)) return original

  const quoted = JSON.stringify(planRoot)
  if (parsed.endLine === rootsIndex) {
    const line = lines[rootsIndex]
    const before = line.slice(0, parsed.endColumn)
    const after = line.slice(parsed.endColumn)
    const separator = parsed.values.length > 0 && !before.trimEnd().endsWith(',') ? ', ' : ''
    lines[rootsIndex] = `${before}${separator}${quoted}${after}`
    return lines.join('')
  }

  const plainLines = lines.map(line => line.replace(/\n$/, ''))
  if (parsed.values.length > 0 &&
      !commaFollows(plainLines, parsed.valueLine, parsed.valueEnd, parsed.endLine, parsed.endColumn)) {
    const lastLine = lines[parsed.valueLine]
    lines[parsed.valueLine] = `${lastLine.slice(0, parsed.valueEnd)},${lastLine.slice(parsed.valueEnd)}`
  }
  const closingIndent = lines[parsed.endLine].match(/^\s*/)?.[0] ?? ''
  lines.splice(parsed.endLine, 0, `${closingIndent}  ${quoted}\n`)
  return lines.join('')
}

async function nextBackupPath(path) {
  const now = new Date()
  const stamp = [
    now.getFullYear(),
    String(now.getMonth() + 1).padStart(2, '0'),
    String(now.getDate()).padStart(2, '0'),
    String(now.getHours()).padStart(2, '0'),
    String(now.getMinutes()).padStart(2, '0'),
    String(now.getSeconds()).padStart(2, '0'),
  ].join('')
  let candidate = `${path}.backup-${stamp}`
  let suffix = 2
  while (true) {
    try {
      await stat(candidate)
      candidate = `${path}.backup-${stamp}-${suffix++}`
    } catch {
      return candidate
    }
  }
}

await mkdir(dirname(configPath), { recursive: true })

let original = ''
let existingMode = 0o600
let existed = true
try {
  original = await readFile(configPath, 'utf8')
  existingMode = (await stat(configPath)).mode
} catch (error) {
  if (error.code !== 'ENOENT') throw error
  existed = false
}

const updated = reconcile(original)
if (updated === original) {
  process.stdout.write('unchanged\n')
  process.exit(0)
}

if (existed) {
  const backupPath = await nextBackupPath(configPath)
  await copyFile(configPath, backupPath)
  process.stdout.write(`backup=${backupPath}\n`)
}

const temporaryPath = `${configPath}.tmp-${process.pid}-${Date.now()}`
const handle = await open(temporaryPath, 'wx', existingMode)
try {
  await handle.writeFile(updated, 'utf8')
  await handle.sync()
  await handle.close()
  await chmod(temporaryPath, existingMode)
  await rename(temporaryPath, configPath)
} catch (error) {
  await handle.close().catch(() => {})
  await unlink(temporaryPath).catch(() => {})
  throw error
}

process.stdout.write(existed ? 'updated\n' : 'created\n')

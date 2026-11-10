#!/usr/bin/env node

import { readFile } from 'node:fs/promises'

const [configPath, expectedRoot] = process.argv.slice(2)

if (!configPath || !expectedRoot) process.exit(2)

const source = await readFile(configPath, 'utf8').catch(() => '')
const lines = source.split(/\r?\n/)
let section = ''
let sections = 0
let roots = 0
let array = ''
let collecting = false
let depth = 0
let quote = ''
let escaped = false

function consume(text) {
  let output = ''
  for (const char of text) {
    if (quote) {
      output += char
      if (escaped) escaped = false
      else if (quote === '"' && char === '\\') escaped = true
      else if (char === quote) quote = ''
      continue
    }
    if (char === '#') break
    if (char === '"' || char === "'") quote = char
    if (char === '[') depth++
    if (char === ']') depth--
    output += char
  }
  return output
}

for (const line of lines) {
  if (collecting) {
    array += `\n${consume(line)}`
    if (depth === 0) collecting = false
    continue
  }

  const header = line.match(/^\s*\[([^\]]+)\]\s*(?:#.*)?$/)
  if (header) {
    section = header[1].trim()
    if (section === 'sandbox_workspace_write') sections++
    continue
  }
  if (section !== 'sandbox_workspace_write') continue

  const key = line.match(/^\s*writable_roots\s*=\s*(.*)$/)
  if (!key) continue
  roots++
  depth = 0
  quote = ''
  escaped = false
  array = consume(key[1])
  collecting = depth !== 0
}

if (sections > 1 || roots > 1 || collecting || depth !== 0 || quote) process.exit(2)
if (sections === 0 || roots === 0) process.exit(1)

const values = []
const stringPattern = /"(?:\\.|[^"\\])*"|'[^']*'/g
for (const match of array.matchAll(stringPattern)) {
  values.push(match[0][0] === '"' ? JSON.parse(match[0]) : match[0].slice(1, -1))
}
const remainder = array.replace(stringPattern, '').replace(/[\s,\[\]]/g, '')
if (remainder) process.exit(2)
process.exit(values.includes(expectedRoot) ? 0 : 1)

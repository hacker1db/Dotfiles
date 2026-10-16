/**
 * safe_path.js — Validate CLI-supplied file paths for the draw.io helpers.
 *
 * Paths are resolved against an allowed base directory (the current working
 * directory, or DRAWIO_ALLOWED_DIR when set). Symlinks are resolved before the
 * containment check, so neither `..` segments nor links can escape the base.
 */
'use strict';

const fs   = require('fs');
const path = require('path');

function allowedBase() {
  return fs.realpathSync(path.resolve(process.env.DRAWIO_ALLOWED_DIR || process.cwd()));
}

function assertInside(base, target, original) {
  const rel = path.relative(base, target);
  if (rel === '' || rel.startsWith('..') || path.isAbsolute(rel)) {
    throw new Error(`Refusing path outside ${base}: ${original}`);
  }
}

function checkExt(p, exts) {
  const ext = path.extname(p).toLowerCase();
  if (!exts.includes(ext)) throw new Error(`Expected ${exts.join(' or ')} file: ${p}`);
}

/** Resolve an existing regular file to read. */
function inputPath(p, exts) {
  if (typeof p !== 'string' || !p || p.includes('\0')) throw new Error('Invalid input path');
  checkExt(p, exts);
  const base = allowedBase();
  const resolved = path.resolve(base, p);
  if (!fs.existsSync(resolved)) throw new Error(`Not found: ${p}`);
  const real = fs.realpathSync(resolved);
  assertInside(base, real, p);
  if (!fs.statSync(real).isFile()) throw new Error(`Not a regular file: ${p}`);
  return real;
}

/** Resolve a file to write; its directory must exist and it must not be a symlink. */
function outputPath(p, exts) {
  if (typeof p !== 'string' || !p || p.includes('\0')) throw new Error('Invalid output path');
  checkExt(p, exts);
  const base = allowedBase();
  const resolved = path.resolve(base, p);
  const dir = fs.realpathSync(path.dirname(resolved));
  const target = path.join(dir, path.basename(resolved));
  assertInside(base, target, p);
  let st = null;
  try { st = fs.lstatSync(target); } catch { /* new file */ }
  if (st && !st.isFile()) throw new Error(`Refusing to overwrite non-regular file or symlink: ${p}`);
  return target;
}

module.exports = { inputPath, outputPath };

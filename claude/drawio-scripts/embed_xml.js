/**
 * embed_xml.js — Embed draw.io XML into a PNG as a tEXt chunk
 * Makes the PNG "editable" — drag it into draw.io to reopen the source.
 *
 * Usage: node embed_xml.js <input.png> <input.drawio> <output.png>
 */
'use strict';

const fs = require('fs');

const [,,pngPath, drawioPath, outPath] = process.argv;
if (!pngPath || !drawioPath || !outPath) {
  process.stderr.write('Usage: node embed_xml.js <input.png> <input.drawio> <output.png>\n');
  process.exit(1);
}

const pngBuf = fs.readFileSync(pngPath);
const xml    = fs.readFileSync(drawioPath, 'utf8');

const SIG = Buffer.from([137,80,78,71,13,10,26,10]);
if (!pngBuf.slice(0,8).equals(SIG)) {
  console.error('Input is not a valid PNG file');
  process.exit(1);
}

// CRC32 table
const tbl = Array.from({length:256}, (_,n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
  return c;
});
const crc = b => {
  let c = 0xFFFFFFFF;
  for (const x of b) c = (c >>> 8) ^ tbl[(c ^ x) & 255];
  return (c ^ 0xFFFFFFFF) >>> 0;
};

function makeChunk(type, data) {
  const tp = Buffer.from(type, 'ascii');
  const lb = Buffer.alloc(4);
  lb.writeUInt32BE(data.length);
  const cb = Buffer.alloc(4);
  cb.writeUInt32BE(crc(Buffer.concat([tp, data])));
  return [lb, tp, data, cb];
}

const parts = [SIG];
let off = 8;
while (off < pngBuf.length) {
  const len  = pngBuf.readUInt32BE(off);
  const type = pngBuf.slice(off + 4, off + 8).toString('ascii');
  // Insert tEXt chunk with mxfile XML right before IEND
  if (type === 'IEND') {
    parts.push(...makeChunk('tEXt', Buffer.from('mxfile\0' + xml, 'latin1')));
  }
  parts.push(pngBuf.slice(off, off + 12 + len));
  off += 12 + len;
}

fs.writeFileSync(outPath, Buffer.concat(parts));
const stat = fs.statSync(outPath);
console.log(`Editable PNG saved: ${outPath} (${(stat.size/1024).toFixed(1)} KB)`);

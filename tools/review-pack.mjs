#!/usr/bin/env node
// Builds the review pack the independent reviewer judges (docs/ART_CONTRACT.md §9):
//   lineup_<actor>.png   one frame of every clip on a shared ground line, with height guides
//   strip_<clip>.png     every frame of a clip, with the pivot and height guides
//   onion_<clip>.png     each pair of adjacent frames overlaid (earlier blue, later orange)
//   composite_<clip>.png hero attack body + whip, hand socket marked, hitbox on active frames
//   audit.json/.md       the automated audit, run on the same frames
//   index.md             what to look at, in order
// Images carry no verdicts, so the reviewer's first description is blind.
//
//   node tools/review-pack.mjs --frames <frames_root> [--out <dir>] [--contract ...]
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadContract, classOf, isCharacter, canvasOf, pivotOf } from './lib/contract.mjs';
import { runAudit } from './lib/audit.mjs';
import { dirSource } from './lib/source.mjs';
import { inkMask } from './lib/measure.mjs';
import { writePNG } from './lib/png.mjs';
import { canvas, paste, hline, rect, cross, text, textWidth, INK } from './lib/draw.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const argv = process.argv.slice(2);
const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : undefined; };
const root = opt('--frames');
if (!root) { console.error('usage: node tools/review-pack.mjs --frames <frames_root> [--out <dir>]'); process.exit(2); }
const out = resolve(opt('--out') || join(root, '..', 'review'));
const c = loadContract(opt('--contract') || resolve(repo, 'contract/art_contract.json'));
const src = dirSource(root);
mkdirSync(out, { recursive: true });

const PER_ROW = 8, GAP = 10, LABEL = 22, MARGIN = 14;
const written = [];
const save = (name, img) => { writePNG(join(out, name), img); written.push(name); };

// Union ink bbox over frames, always including the pivot and (for characters) the design height line.
function cropOf(frames, pivot, extraTop = 0) {
  let x0 = pivot[0], y0 = pivot[1] - extraTop, x1 = pivot[0], y1 = pivot[1];
  for (const f of frames) {
    const m = inkMask(f, c.measurement.ink_alpha);
    for (let y = 0; y < f.height; y++) for (let x = 0; x < f.width; x++) {
      if (!m[y * f.width + x]) continue;
      if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
    }
  }
  return [Math.max(0, x0 - MARGIN), Math.max(0, y0 - MARGIN), x1 + MARGIN, y1 + MARGIN];
}

// Lay tiles out in rows; draw(tileCanvas, index, ox, oy) paints one tile; guides span each row.
function sheet(title, count, tileW, tileH, drawTile, guides = []) {
  const perRow = Math.max(2, Math.min(PER_ROW, Math.floor(2400 / (tileW + GAP))));
  const cols = Math.min(perRow, count), rows = Math.ceil(count / perRow);
  const w = Math.max(cols * (tileW + GAP) + GAP, textWidth(title) + 2 * GAP);
  const h = 30 + rows * (tileH + LABEL + GAP) + GAP;
  const img = canvas(w, h);
  text(img, GAP, 8, title);
  for (let r = 0; r < rows; r++) {
    const oy = 30 + r * (tileH + LABEL + GAP) + LABEL;
    for (const [y, col] of guides) hline(img, 0, w - 1, oy + y, col, 6);
    for (let k = 0; k < perRow; k++) {
      const i = r * perRow + k;
      if (i >= count) break;
      drawTile(img, i, GAP + k * (tileW + GAP), oy);
    }
  }
  return img;
}

function guidesFor(actor, cropTop) {
  const a = c.actors[actor];
  if (!a || a.align !== 'feet') return [];
  const g = [[a.pivot[1] - cropTop, INK.ground], [a.pivot[1] - a.design_height - cropTop, INK.design]];
  if (a.crouch_height) g.push([a.pivot[1] - a.crouch_height - cropTop, INK.crouch]);
  return g;
}

const present = Object.keys(c.clips).filter((id) => src.frames(id));
const label = (img, x, y, s, maxW) => text(img, x, y - LABEL + 4, s.length * 12 > maxW ? s.slice(0, Math.max(3, Math.floor(maxW / 12))) : s);

// ---- lineups ----
for (const actor of Object.keys(c.actors)) {
  const clips = present.filter((id) => c.clips[id].actor === actor);
  if (!clips.length) continue;
  const a = c.actors[actor];
  const firsts = clips.map((id) => src.frames(id)[0]).filter(Boolean);
  const [x0, y0, x1, y1] = cropOf(firsts, a.pivot, a.design_height + 8);
  const tw = x1 - x0 + 1, th = y1 - y0 + 1;
  const img = sheet(`${actor} lineup: frame 0 of every clip. red ground, blue design height${a.crouch_height ? ', yellow crouch height' : ''}`,
    clips.length, Math.max(tw, 120), th, (img, i, ox, oy) => {
      const id = clips[i];
      paste(img, src.frames(id)[0], ox, oy, { sx: x0, sy: y0, w: tw, h: th });
      label(img, ox, oy, id.replace(`${actor}_`, ''), Math.max(tw, 120));
    }, guidesFor(actor, y0));
  save(`lineup_${actor}.png`, img);
}

// ---- strips and onion skins ----
for (const id of present) {
  const spec = c.clips[id], frames = src.frames(id);
  const pivot = pivotOf(c, id);
  const character = isCharacter(c, id);
  const extraTop = character ? c.actors[spec.actor].design_height + 8 : 0;
  const [x0, y0, x1, y1] = cropOf(frames, pivot, extraTop);
  const tw = x1 - x0 + 1, th = y1 - y0 + 1;
  const guides = character ? guidesFor(spec.actor, y0) : [];
  const strip = sheet(`${id}: ${frames.length} frames, ${spec.ms.join('/')} ms${spec.loop ? ', loops' : ''}`, frames.length, Math.max(tw, 96), th, (img, i, ox, oy) => {
    paste(img, frames[i], ox, oy, { sx: x0, sy: y0, w: tw, h: th });
    cross(img, ox + pivot[0] - x0, oy + pivot[1] - y0, 6, INK.pivot);
    label(img, ox, oy, `f${i}${character ? ' ' + classOf(c, id, i) : ''}`, Math.max(tw, 96));
  }, guides);
  save(`strip_${id}.png`, strip);
  if (frames.length > 1) {
    const pairs = frames.map((_, i) => i).slice(1).map((i) => [i - 1, i]);
    if (spec.loop) pairs.push([frames.length - 1, 0]);
    const onion = sheet(`${id} onion: earlier frame blue, later frame orange`, pairs.length, Math.max(tw, 96), th, (img, k, ox, oy) => {
      const [p, q] = pairs[k];
      paste(img, frames[p], ox, oy, { sx: x0, sy: y0, w: tw, h: th, tint: [70, 120, 255], alpha: 0.6 });
      paste(img, frames[q], ox, oy, { sx: x0, sy: y0, w: tw, h: th, tint: [255, 140, 40], alpha: 0.6 });
      label(img, ox, oy, `f${p}-f${q}`, Math.max(tw, 96));
    }, guides);
    save(`onion_${id}.png`, onion);
  }
}

// ---- body + whip composites ----
for (const id of present) {
  const spec = c.clips[id];
  if (!spec.sync || !src.frames(spec.sync)) continue;
  const body = src.frames(id), whip = src.frames(spec.sync), w = c.clips[spec.sync];
  const sockets = (src.sockets && src.sockets[id]) || [];
  const [W, H] = c.whip.canvas, pv = c.whip.pivot;
  const comps = body.map((b, i) => {
    const img = canvas(W, H, [0, 0, 0, 0]);
    paste(img, b, 0, 0);
    if (whip[i]) paste(img, whip[i], 0, 0);
    return img;
  });
  const [x0, y0, x1, y1] = cropOf(comps, pv, c.actors.hero.design_height + 8);
  const tw = x1 - x0 + 1, th = y1 - y0 + 1;
  const low = /crouch/.test(id);
  const sheetImg = sheet(`${id} + ${spec.sync}: cyan cross = hand socket, yellow box = hitbox on active frames`, comps.length, tw, th, (img, i, ox, oy) => {
    const bg = canvas(tw, th);
    paste(bg, comps[i], 0, 0, { sx: x0, sy: y0, w: tw, h: th });
    paste(img, bg, ox, oy);
    if (sockets[i]) cross(img, ox + sockets[i][0] - x0, oy + sockets[i][1] - y0, 7, INK.socket);
    if (w.active.includes(i)) {
      const hy0 = low ? -48 : -82, hy1 = low ? -20 : -46;
      rect(img, ox + pv[0] + 80 - x0, oy + pv[1] + 2 * hy0 - y0, ox + pv[0] + 336 - x0, oy + pv[1] + 2 * hy1 - y0, INK.hitbox);
    }
    label(img, ox, oy, `f${i}${w.active.includes(i) ? ' active' : w.coiled.includes(i) ? ' coiled' : ''}`, tw);
  }, guidesFor('hero', y0));
  save(`composite_${id}.png`, sheetImg);
}

// ---- audit on the same frames ----
const result = runAudit(c, src, { allowMissing: true });
writeFileSync(join(out, 'audit.json'), JSON.stringify({ defects: result.defects, flags: result.flags, findings: result.findings }, null, 1));
const findingLines = result.findings.map((f) => `- **${f.rule} ${f.severity}** \`${f.clip ?? '-'}\`${f.frame != null ? ` f${f.frame}` : ''}: ${f.msg}`);
writeFileSync(join(out, 'audit.md'), `# Art audit\n\n**${result.defects} DEFECT, ${result.flags} FLAG** over ${result.clips} clips.\n\n${findingLines.join('\n')}\n`);

// ---- derivations and index ----
const derivPath = join(root, 'derivations.json');
const deriv = existsSync(derivPath) ? JSON.parse(readFileSync(derivPath, 'utf8')) : {};
const missing = Object.keys(c.clips).filter((id) => !present.includes(id));
const lineups = written.filter((f) => f.startsWith('lineup_'));
const index = [
  '# Art review pack', '',
  `Frames: \`${resolve(root)}\` · contract ${c.contract_version} · ${present.length} clips present${missing.length ? `, ${missing.length} missing` : ''}.`, '',
  'Follow `prompts/ART_REVIEW.md`. Do the steps in this order and do not read `audit.md` or the clip intents until step 3.', '',
  '1. **Blind description.** For each lineup, then each strip, write what you see in plain words before anything else.',
  ...lineups.map((f) => `   - \`${f}\``),
  '2. **Motion.** Read every `onion_*.png`: does each pair read as one continuous movement of the same body?',
  '3. **Intent and checks.** Now read the contract and `audit.md`, compare, and adjudicate every FLAG.',
  '4. **Attacks.** `composite_*.png`: whip held in the fist (cyan cross), reach covers the yellow hitbox on active frames.', '',
  `Audit: **${result.defects} DEFECT, ${result.flags} FLAG** (see \`audit.md\`).`, '',
  '## Derived clips (ART_CONTRACT §11)', '',
  ...(Object.keys(deriv).length ? Object.entries(deriv).map(([k, v]) => `- \`${k}\`: ${v.kind} of \`${v.source}\` (${v.method}); reason: ${v.reason}. Confirm it reads as the intended action.`) : ['None declared (`derivations.json` absent or empty).']), '',
  ...(missing.length ? ['## Missing clips', '', ...missing.map((m) => `- \`${m}\``), ''] : []),
  '## Files', '', ...written.map((f) => `- \`${f}\``),
];
writeFileSync(join(out, 'index.md'), index.join('\n') + '\n');
console.log(`REVIEW PACK: ${written.length} images in ${out} (audit: ${result.defects} DEFECT, ${result.flags} FLAG)`);

#!/usr/bin/env node
// Checks contract/art_contract.json for internal consistency and against
// docs/ASSET_BRIEFS.md (frame counts, per-frame durations, canvases, pivots).
// Exit 0 = consistent, 1 = disagreement found.
//
//   node tools/contract-check.mjs [--contract contract/art_contract.json] [--briefs docs/ASSET_BRIEFS.md]
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadContract, classOf, canvasOf, heightBand } from './lib/contract.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const arg = (name, dflt) => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : dflt;
};
const c = loadContract(arg('--contract', resolve(repo, 'contract/art_contract.json')));
const briefs = readFileSync(arg('--briefs', resolve(repo, 'docs/ASSET_BRIEFS.md')), 'utf8');

const problems = [];
const bad = (msg) => problems.push(msg);
const sum = (xs) => xs.reduce((a, b) => a + b, 0);

// ---- internal consistency ----
for (const [id, s] of Object.entries(c.clips)) {
  const known = c.actors[s.actor] || s.actor === 'whip' || s.actor === 'vfx';
  if (!known) { bad(`${id}: unknown actor "${s.actor}"`); continue; }
  if (!Array.isArray(s.ms) || !s.ms.length) bad(`${id}: ms must be a non-empty array`);
  if (c.actors[s.actor]) {
    if (Array.isArray(s.pose) && s.pose.length !== s.ms.length) bad(`${id}: pose list has ${s.pose.length} entries for ${s.ms.length} frames`);
    for (let i = 0; i < s.ms.length; i++) {
      if (!c.pose_classes[classOf(c, id, i)]) bad(`${id} f${i}: unknown pose class "${classOf(c, id, i)}"`);
    }
  }
  if (s.sync) {
    const w = c.clips[s.sync];
    if (!w) bad(`${id}: sync clip ${s.sync} missing`);
    else {
      if (w.body !== id) bad(`${s.sync}: body should be ${id}`);
      if (JSON.stringify(w.ms) !== JSON.stringify(s.ms)) bad(`${id} and ${s.sync}: frame durations differ`);
    }
    if (!s.hand_sockets) bad(`${id}: synchronised attack must require hand_sockets`);
  }
  if (s.actor === 'whip') {
    for (const k of [...(s.coiled || []), ...(s.active || [])]) if (k < 0 || k >= s.ms.length) bad(`${id}: frame index ${k} out of range`);
    if (sum(s.ms) !== 500) bad(`${id}: whip clip must total 500 ms (SPEC §5), has ${sum(s.ms)}`);
  }
  if (s.actor === 'vfx') {
    const [w, h] = s.canvas;
    if (s.anchor[0] < 0 || s.anchor[0] >= w || s.anchor[1] < 0 || s.anchor[1] >= h) bad(`${id}: anchor outside canvas`);
    if (s.max_extent_px > Math.max(w, h) - 2 * c.vfx.border_px) bad(`${id}: max_extent_px larger than the usable canvas`);
  }
}
for (const [name, a] of Object.entries(c.actors)) {
  if (!c.clips[a.reference.clip]) bad(`actor ${name}: reference clip ${a.reference.clip} not in clips`);
  const [w, h] = a.canvas;
  if (a.pivot[0] >= w || a.pivot[1] >= h) bad(`actor ${name}: pivot outside canvas`);
  if (a.align === 'feet' && a.design_height > a.pivot[1]) bad(`actor ${name}: design height ${a.design_height} does not fit above the pivot`);
}
if (c.whip.pivot.join() !== c.actors.hero.pivot.join()) bad('whip pivot must equal hero pivot (hand sockets are shared coordinates)');

// Every height a clip is allowed to reach must fit on its canvas, or the art is clipped
// by construction (the first implementation clipped the pursuer's rear-up and boss frames).
for (const [id, s] of Object.entries(c.clips)) {
  const a = c.actors[s.actor];
  if (!a) continue;
  const room = a.align === 'feet'
    ? a.pivot[1] - c.measurement.edge_px
    : 2 * Math.min(a.pivot[1], a.canvas[1] - 1 - a.pivot[1]) - 2 * c.measurement.edge_px;
  for (let i = 0; i < s.ms.length; i++) {
    const band = heightBand(c, id, i);
    if (band && band[1] > room) { bad(`${id} f${i}: allowed height ${band[1].toFixed(0)} px does not fit the canvas (${room} px of room)`); break; }
  }
}

// ---- cross-check against ASSET_BRIEFS.md ----
// Rows look like: | `hero_idle` | 8 × 125 ms (1000) | ...
//                 | `vfx_whip_impact` | 192×192 | 6 × [40,40,40,50,50,60] (280) [P3] | ...
//                 | `hero_attack_air` | 8 × same (500) | ...   ("same" = previous explicit list)
const rowRe = /^\|\s*`([a-z0-9_]+)`\s*\|(.*)$/;
const timingRe = /(\d+)\s*×\s*(?:\[([\d.,\s]+)\]|(\d+(?:\.\d+)?)\s*ms|(same))\s*\((\d+(?:\.\d+)?)/;
const canvasRe = /\|\s*(\d+)×(\d+)\s*\|/;
const briefClips = new Map();
let lastList = null;
for (const line of briefs.split('\n')) {
  const m = rowRe.exec(line);
  if (!m) continue;
  const t = timingRe.exec(m[2]);
  if (!t) continue;
  const n = Number(t[1]);
  let ms;
  if (t[2]) { ms = t[2].split(',').map(Number); lastList = ms; }
  else if (t[3]) ms = Array(n).fill(Number(t[3]));
  else ms = lastList;
  const cv = canvasRe.exec(m[2]) || /canvas (\d+)×(\d+)/.exec(m[2]);
  briefClips.set(m[1], { n, ms, total: Number(t[5]), canvas: cv ? [Number(cv[1]), Number(cv[2])] : null });
}

for (const [id, b] of briefClips) {
  if (b.ms && b.ms.length !== b.n) bad(`ASSET_BRIEFS ${id}: ${b.n} frames but ${b.ms.length} durations`);
  if (b.ms && Math.abs(sum(b.ms) - b.total) > 0.01) bad(`ASSET_BRIEFS ${id}: durations sum ${sum(b.ms)} ≠ stated total ${b.total}`);
  const s = c.clips[id];
  if (!s) {
    if (!(c.engine_drawn && c.engine_drawn[id])) bad(`${id}: in ASSET_BRIEFS but not in the contract`);
    continue;
  }
  if (s.ms.length !== b.n) bad(`${id}: contract has ${s.ms.length} frames, ASSET_BRIEFS ${b.n}`);
  else if (b.ms && JSON.stringify(s.ms) !== JSON.stringify(b.ms)) bad(`${id}: durations ${JSON.stringify(s.ms)} ≠ ASSET_BRIEFS ${JSON.stringify(b.ms)}`);
  if (b.canvas && s.actor === 'vfx' && canvasOf(c, id).join() !== b.canvas.join()) bad(`${id}: canvas ${canvasOf(c, id)} ≠ ASSET_BRIEFS ${b.canvas}`);
}
for (const id of Object.keys(c.clips)) {
  if (c.clips[id].note && /style-lock/.test(c.clips[id].note)) continue;
  if (!briefClips.has(id)) bad(`${id}: in the contract but not in ASSET_BRIEFS`);
}

// Section headers carry actor canvases and pivots, e.g.
// "## 4. Ground pursuer — canvas 320×192 [P3], ground pivot (128, 160) [P3]"
const sections = { hero: /## 2\. Hero body/, whip: /## 3\. Whip layer/, pursuer: /## 4\./, swooper: /## 5\./, ranged: /## 6\./, boss: /## 7\./ };
for (const [name, re] of Object.entries(sections)) {
  const line = briefs.split('\n').find((l) => re.test(l));
  if (!line) { bad(`ASSET_BRIEFS: section for ${name} not found`); continue; }
  const cv = /canvas (\d+)×(\d+)/.exec(line), pv = /\((\d+),\s*(\d+)\)/.exec(line);
  const want = name === 'whip' ? { canvas: c.whip.canvas, pivot: c.whip.pivot } : c.actors[name];
  if (cv && `${cv[1]},${cv[2]}` !== want.canvas.join()) bad(`${name}: canvas ${want.canvas} ≠ ASSET_BRIEFS ${cv[1]}×${cv[2]}`);
  if (pv && `${pv[1]},${pv[2]}` !== want.pivot.join()) bad(`${name}: pivot ${want.pivot} ≠ ASSET_BRIEFS (${pv[1]}, ${pv[2]})`);
}

const clipCount = Object.keys(c.clips).length;
const frameCount = sum(Object.values(c.clips).map((s) => s.ms.length));
if (problems.length) {
  console.log(`CONTRACT CHECK: FAIL (${problems.length} problem${problems.length > 1 ? 's' : ''})`);
  for (const p of problems) console.log(`  - ${p}`);
  process.exit(1);
}
console.log(`CONTRACT CHECK: PASS — ${clipCount} clips, ${frameCount} frames, ${briefClips.size} brief rows cross-checked`);

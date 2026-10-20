#!/usr/bin/env node
// Proves the art audit can fail (docs/ART_CONTRACT.md §10).
// Builds a correct synthetic frame set for the whole contract, checks the audit passes it,
// then applies one known defect at a time and checks the audit reports the expected rule.
// Exit 0 = every check behaved; 1 = the audit missed a defect or rejected correct art.
//
//   node tools/selftest.mjs [--write <dir>]   (--write also saves the correct set as PNGs)
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadContract } from './lib/contract.mjs';
import { synthesise, defectFrame } from './lib/synth.mjs';
import { runAudit } from './lib/audit.mjs';
import { memorySource, dirSource } from './lib/source.mjs';
import { blank, encodePNG, decodePNG } from './lib/png.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const c = loadContract(resolve(repo, 'contract/art_contract.json'));
const t0 = Date.now();
const good = synthesise(c);
const { heroFrame, whipFrame, vfxFrame } = defectFrame;

const clone = (s) => ({
  frames: Object.fromEntries(Object.entries(s.frames).map(([k, v]) => [k, v.map((f) => ({ ...f, data: new Uint8Array(f.data) }))])),
  meta: JSON.parse(JSON.stringify(s.meta)),
  sockets: JSON.parse(JSON.stringify(s.sockets)),
});
const n = (clip) => c.clips[clip].ms.length;
const redraw = (set, clip, opt, which = null) => {
  set.frames[clip] = set.frames[clip].map((f, i) => (which && !which.includes(i) ? f : heroFrame(c, clip, i, n(clip), opt).img));
};
const paint = (img, x0, y0, w, h, rgba) => {
  for (let y = y0; y < y0 + h; y++) for (let x = x0; x < x0 + w; x++) img.data.set(rgba, (y * img.width + x) * 4);
};
const HERO = '^(hero_|style_hero|whip_)';

// [id, defect it reproduces, expected rule, clip filter, mutation]
// The expected rule is the one aimed at the defect; other rules firing too is fine.
const CASES = [
  ['torso-idle', 'DA-2 standing idle is a waist-up torso stretched to full height', 'A-07', HERO, (s) => redraw(s, 'hero_idle', { torso: true })],
  ['torso-hands-low', 'DA-2 variant: hands hang below the belt and mimic feet; the lower-body proxy is fooled, the head rule is not', 'A-08', HERO, (s) => redraw(s, 'hero_idle', { torso: 'hands-low' })],
  ['torso-reference', 'DA-2 the identity reference itself is a torso', 'A-08', HERO, (s) => redraw(s, 'style_hero_neutral', { torso: true })],
  ['boss-torso', 'DA-6 boss idle is a torso (no robe exemption)', 'A-07', '^boss_', (s) => redraw(s, 'boss_idle', { torso: true })],
  ['crouch-shrink', 'DA-3 crouch drawn as a smaller man', 'A-08', HERO, (s) => { redraw(s, 'hero_crouch_idle', { scale: 0.88 }); redraw(s, 'hero_crouch_enter', { scale: 0.88 }); }],
  ['walk-scale', 'DA-1 walk sheet generated 14% small', 'A-05', HERO, (s) => redraw(s, 'hero_walk', { scale: 0.86 })],
  ['clip-scale-subtle', 'DA-1 idle sheet 7% large: inside every per-frame band', 'A-12', HERO, (s) => redraw(s, 'hero_stop_move', { scale: 1.07 })],
  ['frame-drift', 'DA-8 one attack frame drawn 12% large', 'A-06', HERO, (s) => redraw(s, 'hero_attack_ground', { scale: 1.12 }, [4])],
  ['debris', 'DA-7 a detached speck left by extraction', 'A-04', HERO, (s) => paint(s.frames.hero_walk[3], 60, 60, 6, 6, [80, 60, 40, 255])],
  ['clipped', 'DA-7 figure cut off at the canvas edge', 'A-03', HERO, (s) => redraw(s, 'hero_turn', { dx: 236 }, [1])],
  ['opaque-bg', 'DA-7 background left opaque', 'A-02', HERO, (s) => { const f = s.frames.hero_idle[0]; for (let i = 0; i < f.width * f.height; i++) if (!f.data[i * 4 + 3]) f.data.set([20, 18, 30, 255], i * 4); }],
  ['key-residue', 'DA-7 chroma-key fringe left on the art', 'A-02', HERO, (s) => paint(s.frames.hero_walk[0], 250, 300, 3, 40, [255, 0, 255, 255])],
  ['floating', 'feet lifted off the pivot line', 'A-09', HERO, (s) => redraw(s, 'hero_idle', { float: 10 }, [2])],
  ['empty-frame', 'blank frame in a clip', 'A-01', HERO, (s) => { s.frames.hero_walk[5] = blank(512, 512); }],
  ['wrong-canvas', 'frame delivered at the wrong canvas size', 'A-01', HERO, (s) => { s.frames.hero_idle[0] = blank(512, 480, [0, 0, 0, 0]); }],
  ['missing-frame', 'clip delivered one frame short', 'A-14', HERO, (s) => { s.frames.hero_fall.pop(); }],
  ['wrong-timing', 'delivered durations differ from the contract', 'A-14', HERO, (s) => { s.meta.hero_idle.ms = s.meta.hero_idle.ms.map(() => 100); }],
  ['whip-detached', 'DA-4 whip floats beside an empty fist', 'W-01', HERO, (s) => { s.frames.whip_attack_ground[2] = whipFrame(c, 'whip_attack_ground', 2, s.sockets.hero_attack_ground[2], { detach: true }).img; }],
  ['whip-giant-coil', 'DA-4 coiled whip as big as the hero', 'W-03', HERO, (s) => { s.frames.whip_attack_air[0] = whipFrame(c, 'whip_attack_air', 0, s.sockets.hero_attack_air[0], { bigCoil: true }).img; }],
  ['whip-short', 'whip never reaches the hitbox', 'W-04', HERO, (s) => { for (const i of [2, 3]) s.frames.whip_attack_crouch[i] = whipFrame(c, 'whip_attack_crouch', i, s.sockets.hero_attack_crouch[i], { short: true }).img; }],
  ['whip-snap', 'DA-5 whip jumps back mid-extension', 'W-05', HERO, (s) => { const w = s.frames.whip_attack_ground; [w[1], w[2]] = [w[2], w[1]]; const k = s.sockets.hero_attack_ground; [k[1], k[2]] = [k[2], k[1]]; }],
  ['whip-blank', 'blank whip frame during the attack', 'W-06', HERO, (s) => { s.frames.whip_attack_air[3] = blank(768, 512); }],
  ['vfx-rectangle', 'DA-7 effect shows a hard rectangle edge', 'V-01', '^vfx_', (s) => { s.frames.vfx_enemy_defeat[3] = vfxFrame(c, 'vfx_enemy_defeat', 3, 8, { rect: true }).img; }],
  ['vfx-pop', 'DA-5 impact effect pops between sizes', 'V-03', '^vfx_', (s) => { s.frames.vfx_whip_impact = s.frames.vfx_whip_impact.map((_, i) => vfxFrame(c, 'vfx_whip_impact', i, 6, { pop: true }).img); }],
  ['engine-effect-as-art', 'DA-7 screen vignette delivered as keyed art', 'V-04', '^vfx_', (s) => { s.frames.vfx_damage_indicator = [blank(128, 128), blank(128, 128)]; }],
];

let failed = 0;
const say = (ok, msg) => { if (!ok) failed++; console.log(`${ok ? 'ok  ' : 'FAIL'} ${msg}`); };

// 1. The correct set must pass, including through PNG files on disk.
const full = runAudit(c, memorySource(good));
say(full.defects === 0, `correct synthetic set (${Object.keys(good.frames).length} clips): ${full.defects} DEFECT, ${full.flags} FLAG`);
if (full.defects) for (const f of full.findings.filter((x) => x.severity === 'DEFECT').slice(0, 10)) console.log(`       ${f.rule} ${f.clip} f${f.frame}: ${f.msg}`);

const wi = process.argv.indexOf('--write');
const dir = wi > 0 ? resolve(process.argv[wi + 1]) : mkdtempSync(join(tmpdir(), 'art-selftest-'));
for (const [clip, frames] of Object.entries(good.frames)) {
  mkdirSync(join(dir, clip), { recursive: true });
  frames.forEach((f, i) => writeFileSync(join(dir, clip, `f${String(i).padStart(3, '0')}.png`), encodePNG(f)));
}
writeFileSync(join(dir, 'clips.json'), JSON.stringify(good.meta, null, 1));
writeFileSync(join(dir, 'hand_sockets.json'), JSON.stringify(good.sockets, null, 1));
const sample = good.frames.hero_attack_ground[2];
const round = decodePNG(encodePNG(sample));
say(Buffer.compare(Buffer.from(round.data), Buffer.from(sample.data)) === 0, 'PNG encode/decode round trip is lossless');
const disk = runAudit(c, dirSource(dir), { only: HERO });
say(disk.defects === 0 && disk.clips > 0, `correct hero set read back from PNG files: ${disk.clips} clips, ${disk.defects} DEFECT`);
if (wi < 0) rmSync(dir, { recursive: true, force: true });

// 2. Every defect must be caught by the expected rule.
for (const [id, what, rule, only, mutate] of CASES) {
  const s = clone(good);
  mutate(s);
  const r = runAudit(c, memorySource(s), { only });
  const hit = r.findings.some((f) => f.rule === rule && f.severity === 'DEFECT');
  const rules = [...new Set(r.findings.filter((f) => f.severity === 'DEFECT').map((f) => f.rule))].join(', ') || 'none';
  say(hit, `${id.padEnd(22)} ${rule} expected; DEFECT rules reported: ${rules}  — ${what}`);
}

console.log(`\nSELFTEST: ${failed ? 'FAIL' : 'PASS'} — ${CASES.length} defect cases, ${failed} problem(s), ${((Date.now() - t0) / 1000).toFixed(1)} s`);
process.exit(failed ? 1 : 0);

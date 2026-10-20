// Synthetic art for the self-test: simple procedural actors drawn to the contract,
// so every audit rule can be shown passing on correct frames and failing on a known defect.
// These are test fixtures, not art. Shapes are flat polygons and capsules.
import { blank } from './png.mjs';
import { classOf, canvasOf } from './contract.mjs';

const COL = {
  hero: [92, 70, 48, 255], boss: [76, 88, 102, 255], pursuer: [169, 164, 145, 255],
  swooper: [110, 106, 97, 255], ranged: [59, 45, 32, 255], whip: [59, 45, 32, 255],
  vfx: [227, 163, 74, 255], proj: [140, 192, 132, 255],
};

// ---- raster primitives (canvas coordinates) ----
function fillCapsule(img, ax, ay, bx, by, r, col) {
  const x0 = Math.max(0, Math.floor(Math.min(ax, bx) - r)), x1 = Math.min(img.width - 1, Math.ceil(Math.max(ax, bx) + r));
  const y0 = Math.max(0, Math.floor(Math.min(ay, by) - r)), y1 = Math.min(img.height - 1, Math.ceil(Math.max(ay, by) + r));
  const dx = bx - ax, dy = by - ay, L = dx * dx + dy * dy;
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
    const px = x + 0.5, py = y + 0.5;
    const t = L ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / L)) : 0;
    const qx = ax + t * dx - px, qy = ay + t * dy - py;
    if (qx * qx + qy * qy <= r * r) img.data.set(col, (y * img.width + x) * 4);
  }
}

function fillPoly(img, pts, col) {
  const xs = pts.map((p) => p[0]), ys = pts.map((p) => p[1]);
  const y0 = Math.max(0, Math.floor(Math.min(...ys))), y1 = Math.min(img.height - 1, Math.ceil(Math.max(...ys)));
  const x0 = Math.max(0, Math.floor(Math.min(...xs))), x1 = Math.min(img.width - 1, Math.ceil(Math.max(...xs)));
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
    const px = x + 0.5, py = y + 0.5;
    let inside = false;
    for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      const [xi, yi] = pts[i], [xj, yj] = pts[j];
      if ((yi > py) !== (yj > py) && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi) inside = !inside;
    }
    if (inside) img.data.set(col, (y * img.width + x) * 4);
  }
}

// A figure is a list of shapes in local units (feet at 0,0; y up is negative), drawn with
// scale, rotation about the origin, then translation to the pivot.
function draw(img, shapes, { pivot, scale = 1, angle = 0, col, dx = 0, sx = 1, sy = 1, about = [0, 0] }) {
  const ca = Math.cos(angle), sa = Math.sin(angle);
  const T = ([x0, y0]) => {
    const x = x0 * sx - about[0], y = y0 * sy - about[1];
    return [pivot[0] + dx + scale * (x * ca - y * sa + about[0]), pivot[1] + scale * (x * sa + y * ca + about[1])];
  };
  for (const s of shapes) {
    if (s.cap) { const [a, b] = [T(s.cap[0]), T(s.cap[1])]; fillCapsule(img, a[0], a[1], b[0], b[1], s.r * scale, col); }
    else fillPoly(img, s.poly.map(T), col);
  }
  return T;
}

// Move the lowest ink row onto the pivot line (what an extraction pipeline does for feet actors).
function settle(img, pivotY, alignCentre = false) {
  let top = -1, bot = -1;
  for (let y = 0; y < img.height && top < 0; y++) for (let x = 0; x < img.width; x++) if (img.data[(y * img.width + x) * 4 + 3]) { top = y; break; }
  for (let y = img.height - 1; y >= 0 && bot < 0; y--) for (let x = 0; x < img.width; x++) if (img.data[(y * img.width + x) * 4 + 3]) { bot = y; break; }
  if (bot < 0) return 0;
  const dy = alignCentre ? Math.round(pivotY - (top + bot) / 2) : pivotY - bot;
  if (!dy) return 0;
  const out = new Uint8Array(img.data.length);
  for (let y = 0; y < img.height; y++) {
    const sy = y - dy;
    if (sy < 0 || sy >= img.height) continue;
    out.set(img.data.subarray(sy * img.width * 4, (sy + 1) * img.width * 4), y * img.width * 4);
  }
  img.data = out;
  return dy;
}

// ---- humanoid (hero, boss) ----
// h: standing height in px. bend: 0 standing … 1 full crouch (head top at 0.625 h).
// stride: leg spread. arm: right-hand target in units of h, or null for hanging.
function humanoid(h, { bend = 0, stride = 0, arm = null, tuck = 0, broad = 1 } = {}) {
  const d = 0.375 * h * bend, W = broad;
  const S = [];
  const hr = 0.085 * h;
  S.push({ cap: [[0, -h + hr + d], [0, -h + hr + d]], r: hr });
  S.push({ cap: [[0, -h + 2 * hr + d], [0, -0.79 * h + d]], r: 0.03 * h });
  S.push({ poly: [[-0.13 * h * W, -0.80 * h + d], [0.13 * h * W, -0.80 * h + d], [0.09 * h * W, -0.52 * h + d], [-0.09 * h * W, -0.52 * h + d]] });
  const skirtBottom = Math.min(-0.32 * h + d, -0.03 * h);
  S.push({ poly: [[-0.10 * h * W, -0.53 * h + d], [0.10 * h * W, -0.53 * h + d], [0.13 * h * W, skirtBottom], [-0.13 * h * W, skirtBottom]] });
  const hipY = -0.48 * h + d;
  for (const side of [-1, 1]) {
    const hip = [side * 0.05 * h, hipY];
    let knee, ankle;
    if (tuck) {
      knee = [side * 0.05 * h + 0.10 * h, hipY + 0.10 * h];
      ankle = [side * 0.03 * h, hipY + 0.24 * h];
    } else if (bend > 0) {
      const fold = bend;
      knee = [hip[0] + 0.16 * h * fold, hipY + (0.22 * h) * (1 - fold) + 0.02 * h];
      ankle = [side * 0.06 * h, -0.05 * h];
    } else {
      knee = [side * (0.055 * h + stride * 0.06 * h), -0.26 * h];
      ankle = [side * (0.06 * h + stride * 0.12 * h), -0.05 * h];
    }
    S.push({ cap: [hip, knee], r: 0.035 * h }, { cap: [knee, ankle], r: 0.035 * h });
    S.push({ cap: [[ankle[0] - 0.01 * h, ankle[1] + 0.025 * h], [ankle[0] + 0.04 * h, ankle[1] + 0.025 * h]], r: 0.025 * h });
  }
  const sh = (side) => [side * 0.15 * h * W, -0.78 * h + d];
  S.push({ cap: [sh(-1), [-0.17 * h * W, -0.64 * h + d]], r: 0.03 * h }, { cap: [[-0.17 * h * W, -0.64 * h + d], [-0.16 * h * W, -0.50 * h + d]], r: 0.03 * h });
  const hand = arm ? [arm[0] * h, arm[1] * h + d] : [0.16 * h * W, -0.50 * h + d];
  const elbow = [(sh(1)[0] + hand[0]) / 2 + 0.02 * h, (sh(1)[1] + hand[1]) / 2];
  S.push({ cap: [sh(1), elbow], r: 0.03 * h }, { cap: [elbow, hand], r: 0.03 * h });
  return { shapes: S, hand };
}

// Waist-up torso stretched to h — the DA-2 defect. As shipped: head, chest, hands resting
// above a wide belt line that is the lowest thing in the frame. handsLow: hands hang below the
// belt, which reads like two feet to the lower-body proxy (the head rule still catches it).
function torsoOnly(h, handsLow = false) {
  const k = h / 0.55;
  const { shapes } = humanoid(k, handsLow ? {} : { arm: [0.10, -0.60] });
  const keep = shapes.filter((s) => {
    const ys = s.cap ? s.cap.map((p) => p[1]) : s.poly.map((p) => p[1]);
    return Math.max(...ys) <= -0.50 * k + 1;
  });
  // Coat body to the belt, as in the shipped defect (measured there: boot ratio 0.71-0.86, leg dip 0.59-0.77).
  if (!handsLow) keep.push({ poly: [[-0.13 * k, -0.80 * k], [0.13 * k, -0.80 * k], [0.13 * k, -0.45 * k], [-0.13 * k, -0.45 * k]] });
  return handsLow ? keep : keep.filter((x) => !(x.cap && x.cap.some((p) => p[0] < -0.15 * k && p[1] > -0.62 * k)));
}

// Strike arm path per phase (units of h, relative to feet), facing right.
const STRIKE_ARM = [[-0.10, -1.05], [-0.04, -1.08], [0.40, -0.74], [0.42, -0.72], [0.36, -0.62], [0.30, -0.56], [0.24, -0.52], [0.18, -0.50]];

function heroFrame(c, clip, i, n, opt = {}) {
  const a = c.actors[c.clips[clip].actor];
  const img = blank(...a.canvas);
  const cls = classOf(c, clip, i);
  const h = a.design_height * (opt.scale || 1);
  const col = COL[c.clips[clip].actor] || COL.hero;
  const broad = c.clips[clip].actor === 'boss' ? 1.25 : 1;
  let fig, angle = 0, slump = 0;
  const t = n > 1 ? i / (n - 1) : 0;
  if (opt.torso) fig = { shapes: torsoOnly(h, opt.torso === 'hands-low'), hand: null };
  else if (cls === 'stand') fig = humanoid(h, { broad });
  else if (cls === 'stride') fig = humanoid(h, { stride: [0, 0.5, 1, 0.5, 0, -0.5, -1, -0.5, 0, 0.5][i % 10], broad });
  else if (cls === 'crouch') fig = humanoid(h, { bend: 1, broad });
  else if (cls === 'crouch_strike') fig = humanoid(h, { bend: 1, arm: STRIKE_ARM[i].map((v, k) => (k ? Math.max(v, -0.62) : v)), broad });
  else if (cls === 'transition') {
    const enter = /crouch_enter|land/.test(clip), exit = /crouch_exit|takeoff/.test(clip);
    const b = enter ? (i + 1) / n : exit ? 1 - i / n : 0.5;
    fig = humanoid(h, { bend: Math.min(1, b), broad });
  } else if (cls === 'strike') fig = humanoid(h, { stride: 0.8, arm: STRIKE_ARM[i % 8], broad });
  else if (cls === 'air') fig = humanoid(h, { tuck: 1, arm: /attack/.test(clip) ? STRIKE_ARM[i % 8].map((v, k) => (k ? Math.max(v, -0.95) : v)) : null, broad });
  else if (cls === 'impact') { fig = humanoid(h, { broad }); angle = (/knockdown/.test(clip) ? -(0.3 + 1.2 * t) : /get_up/.test(clip) ? -(1.5 - 1.2 * t) : -0.25); }
  else if ((cls === 'collapse' || cls === 'dissolve') && c.clips[clip].actor === 'boss') { fig = humanoid(h, { bend: Math.min(1, (i + 1) / 6), broad }); slump = Math.min(i + 1, 9); }
  else if (cls === 'collapse' || cls === 'dissolve') { fig = humanoid(h, { broad }); angle = cls === 'dissolve' ? -Math.PI / 2 : -Math.min(Math.PI / 2, (i + 1) * 0.25); }
  else fig = humanoid(h, { broad });
  const T = draw(img, fig.shapes, { pivot: a.pivot, angle, col, dx: opt.dx || 0, sy: 1 - 0.05 * slump, sx: 1 + 0.04 * slump });
  const dy = settle(img, a.pivot[1] - (opt.float || 0));
  let socket = null;
  if (fig.hand) { const p = T(fig.hand); socket = [Math.round(p[0]), Math.round(p[1] + dy)]; }
  return { img, socket };
}

function creatureFrame(c, clip, i, n) {
  const spec = c.clips[clip], a = c.actors[spec.actor];
  const img = blank(...a.canvas);
  const h = a.design_height, col = COL[spec.actor];
  const cls = classOf(c, clip, i);
  let shapes, angle = 0, sx = 1, sy = 1, about = [0, 0], centre = a.align === 'centre';
  if (spec.actor === 'pursuer') {
    shapes = [{ poly: [[-0.8 * h, -1.0 * h], [0.8 * h, -1.0 * h], [0.9 * h, -0.55 * h], [-0.8 * h, -0.55 * h]] },
      { cap: [[1.05 * h, -0.62 * h], [1.05 * h, -0.62 * h]], r: 0.14 * h }];
    for (const x of [-0.65, -0.45, 0.55, 0.75]) shapes.push({ cap: [[x * h, -0.6 * h], [x * h + 0.05 * h * Math.sin(i), -0.04 * h]], r: 0.05 * h });
    if (clip === 'pursuer_alert') { angle = -0.07 * (i + 1); about = [-0.65 * h, 0]; }
    if (/lunge/.test(clip)) { sx = 1.25; sy = 0.78; }
  } else if (spec.actor === 'swooper') {
    const flap = Math.sin((i / n) * 2 * Math.PI);
    const fold = clip === 'swooper_dive_telegraph' ? (i + 1) / n : 0;
    const span = (1 - 0.6 * fold) * 0.9 * h, lift = (0.60 + 0.10 * flap) * h * (1 - fold * 0.3);
    shapes = [{ cap: [[-0.2 * h, 0], [0.2 * h, 0]], r: 0.16 * h },
      { poly: [[-0.1 * h, -0.05 * h], [-span, -lift], [-0.3 * h, 0.30 * h]] },
      { poly: [[0.1 * h, -0.05 * h], [span, -lift], [0.3 * h, 0.30 * h]] }];
  } else {
    shapes = [{ cap: [[0, -0.88 * h], [0, -0.88 * h]], r: 0.10 * h },
      { poly: [[-0.12 * h, -0.80 * h], [0.12 * h, -0.80 * h], [0.20 * h, -0.02 * h], [-0.20 * h, -0.02 * h]] },
      { cap: [[0.08 * h, -0.95 * h + 0.06 * h], [0.08 * h, -0.98 * h]], r: 0.05 * h }];
    if (/aim|fire/.test(clip)) shapes.push({ cap: [[0.10 * h, -0.70 * h], [0.30 * h, -0.72 * h]], r: 0.03 * h });
  }
  if (cls === 'collapse' || cls === 'dissolve') { const k = Math.min(i + 1, 4); sy = 1 - 0.12 * k; sx = 1 + 0.04 * k; }
  draw(img, shapes, { pivot: a.pivot, angle, col, sx, sy, about });
  settle(img, a.pivot[1], centre);
  return { img };
}

// Whip frame: grip at the socket, a tapered thong whose tip distance follows `reach`.
function whipFrame(c, clip, i, socket, opt = {}) {
  const w = c.whip, spec = c.clips[clip];
  const img = blank(...w.canvas);
  const [sx, sy] = opt.detach ? [socket[0] + 30, socket[1] - 30] : socket;
  fillCapsule(img, sx - 8, sy + 3, sx + 8, sy - 3, 5, COL.whip);
  const coilR = opt.bigCoil ? 110 : 26;
  if (spec.coiled.includes(i)) {
    for (let k = 0; k < 3; k++) {
      const r = coilR - k * (coilR / 4);
      for (let a = 0; a < 2 * Math.PI; a += 0.05) fillCapsule(img, sx + 10 + r * Math.cos(a), sy + 10 + r * Math.sin(a), sx + 10 + r * Math.cos(a + 0.05), sy + 10 + r * Math.sin(a + 0.05), 2.5, COL.whip);
    }
    fillCapsule(img, sx, sy, sx + 10, sy + 10 - coilR, 3, COL.whip);
    return { img };
  }
  const reachTo = opt.short ? 150 : 360;
  const tipDist = { 1: 120, 2: reachTo, 3: reachTo + 8, 4: 240, 5: 170, 6: 110 }[i] ?? 80;
  const dir = i >= 4 ? 0.35 : 0.06;
  const ex = sx + tipDist * Math.cos(dir), ey = sy + tipDist * Math.sin(dir) - (i === 1 ? 40 : 0);
  const segs = 24;
  for (let k = 0; k < segs; k++) {
    const t0 = k / segs, t1 = (k + 1) / segs;
    const sag = (t) => 18 * Math.sin(Math.PI * t);
    const p0 = [sx + (ex - sx) * t0, sy + (ey - sy) * t0 + sag(t0)], p1 = [sx + (ex - sx) * t1, sy + (ey - sy) * t1 + sag(t1)];
    const r = 4.2 * (1 - t0) + 1.2 * t0;
    fillCapsule(img, p0[0], p0[1], p1[0], p1[1], r, COL.whip);
  }
  return { img };
}

function vfxFrame(c, clip, i, n, opt = {}) {
  const s = c.clips[clip];
  const img = blank(...s.canvas);
  if (opt.rect) { for (let k = 0; k < img.width * img.height; k++) img.data.set(COL.vfx, k * 4); return { img }; }
  const peak = Math.floor((n - 1) / 2);
  let k = s.size_curve ? (i <= peak ? (i + 1) / (peak + 1) : 1 - (i - peak) / (n - peak)) : 1;
  if (opt.pop) k = i % 2 ? 1 : 0.3;
  const room = Math.min(s.max_extent_px / 2 - 12, s.canvas[0] / 2 - 12, s.anchor_mode === 'base' ? s.anchor[1] - 12 : s.canvas[1] / 2 - 12);
  const R = Math.max(4, k * room);
  const col = clip.startsWith('projectile') ? COL.proj : COL.vfx;
  const [ax, ay] = s.anchor;
  if (s.anchor_mode === 'base') fillPoly(img, [[ax - R, ay], [ax + R, ay], [ax + R * 0.4, ay - Math.min(R * 1.2, ay - 4)], [ax - R * 0.4, ay - Math.min(R * 1.2, ay - 4)]], col);
  else if (clip.startsWith('projectile')) fillPoly(img, [[ax, ay - R], [ax + R * 0.6, ay], [ax, ay + R], [ax - R * 0.6, ay]], col);
  else for (let a = 0; a < 2 * Math.PI; a += Math.PI / 6) fillCapsule(img, ax, ay, ax + R * Math.cos(a), ay + R * Math.sin(a), Math.max(2, R * 0.08), col);
  return { img };
}

// Build a complete, correct frame set for every clip in the contract.
export function synthesise(c) {
  const frames = {}, meta = {}, sockets = {};
  for (const [clip, spec] of Object.entries(c.clips)) {
    const n = spec.ms.length;
    meta[clip] = { ms: [...spec.ms], loop: !!spec.loop };
    if (spec.actor === 'whip') continue;
    if (spec.actor === 'vfx') { frames[clip] = Array.from({ length: n }, (_, i) => vfxFrame(c, clip, i, n).img); continue; }
    const humanoidActor = spec.actor === 'hero' || spec.actor === 'boss';
    const out = Array.from({ length: n }, (_, i) => (humanoidActor ? heroFrame(c, clip, i, n) : creatureFrame(c, clip, i, n)));
    frames[clip] = out.map((o) => o.img);
    if (spec.hand_sockets) sockets[clip] = out.map((o) => o.socket);
  }
  for (const [clip, spec] of Object.entries(c.clips)) {
    if (spec.actor !== 'whip') continue;
    frames[clip] = spec.ms.map((_, i) => whipFrame(c, clip, i, sockets[spec.body][i]).img);
  }
  return { frames, meta, sockets };
}

export const defectFrame = { heroFrame, creatureFrame, whipFrame, vfxFrame, canvasOf };

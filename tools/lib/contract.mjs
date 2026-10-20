// Loads contract/art_contract.json and answers per-frame questions about it.
import { readFileSync } from 'node:fs';

export function loadContract(path) {
  const c = JSON.parse(readFileSync(path, 'utf8'));
  c._path = path;
  return c;
}

export const isCharacter = (c, clip) => !!c.actors[c.clips[clip].actor];

export function classOf(c, clip, i) {
  const p = c.clips[clip].pose;
  return Array.isArray(p) ? p[i] : p;
}

const scaled = (expr, a) => {
  if (typeof expr === 'number') return expr;
  const [ref, k] = expr.split('*');
  return (ref === 'crouch' ? a.crouch_height : a.design_height) * Number(k);
};

// Height band in px for a frame, or null when the class has no band.
export function heightBand(c, clip, i) {
  const spec = c.clips[clip], a = c.actors[spec.actor], pc = c.pose_classes[classOf(c, clip, i)];
  if (spec.height) return [spec.height[0] * a.design_height, spec.height[1] * a.design_height];
  if (!pc.height) return null;
  if (pc.height_ref === 'range') return [scaled(pc.height[0], a), scaled(pc.height[1], a)];
  const ref = pc.height_ref === 'crouch' ? a.crouch_height : a.design_height;
  return [pc.height[0] * ref, pc.height[1] * ref];
}

// Size band as multiples of the actor's reference size, or null.
export function sizeBand(c, clip, i) {
  const spec = c.clips[clip], pc = c.pose_classes[classOf(c, clip, i)];
  return spec.size || pc.size || null;
}

export function headRule(c, clip, i) {
  const spec = c.clips[clip], a = c.actors[spec.actor];
  if (!a.head_ratio) return false;
  if (spec.head === false) return false;
  return !!c.pose_classes[classOf(c, clip, i)].head;
}

export function lowerBodyRule(c, clip, i) {
  const a = c.actors[c.clips[clip].actor];
  return !!a.has_legs && !!c.pose_classes[classOf(c, clip, i)].lower_body;
}

export const canvasOf = (c, clip) => {
  const s = c.clips[clip];
  if (s.actor === 'whip') return c.whip.canvas;
  if (s.actor === 'vfx') return s.canvas;
  return c.actors[s.actor].canvas;
};

export const pivotOf = (c, clip) => {
  const s = c.clips[clip];
  if (s.actor === 'whip') return c.whip.pivot;
  if (s.actor === 'vfx') return s.anchor;
  return c.actors[s.actor].pivot;
};

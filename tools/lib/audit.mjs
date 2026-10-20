// The art audit: every automated rule of docs/ART_CONTRACT.md §4–§7.
// Pure function over a frame source so the self-test can run it in memory.
//
// source = {
//   frames(clipId) -> array of {width,height,data} images, or null when the clip is missing
//   meta: { clipId: { ms: [...], loop: bool } } | null   (delivered timing, clips.json)
//   sockets: { heroAttackClipId: [[x,y], ...] } | null   (hand_sockets.json)
// }
import {
  measureFrame, keyResidue, cornersTransparent, touchesEdge, median, inkMask, distanceTo,
} from './measure.mjs';
import {
  classOf, heightBand, sizeBand, headRule, lowerBodyRule, canvasOf, pivotOf, isCharacter,
} from './contract.mjs';

const fmt = (x, d = 1) => (Number.isFinite(x) ? x.toFixed(d) : String(x));

export function runAudit(c, source, opts = {}) {
  const m = c.measurement;
  const findings = [];
  const metrics = {};
  const add = (rule, severity, clip, frame, msg) => findings.push({ rule, severity, clip, frame, msg });
  const only = opts.only ? new RegExp(opts.only) : null;
  const clipIds = Object.keys(c.clips).filter((id) => !only || only.test(id));

  // ---- load and basic checks (A-01, A-14) ----
  const loaded = {};
  if (!source.meta) add('A-14', 'DEFECT', null, null, 'clips.json (delivered durations and loop flags) is missing');
  for (const id of clipIds) {
    const spec = c.clips[id];
    const frames = source.frames(id);
    if (!frames) {
      if (!opts.allowMissing) add('A-01', 'DEFECT', id, null, 'clip missing');
      continue;
    }
    loaded[id] = frames;
    if (frames.length !== spec.ms.length) add('A-14', 'DEFECT', id, null, `${frames.length} frames delivered, contract says ${spec.ms.length}`);
    const meta = source.meta && source.meta[id];
    if (source.meta && !meta) add('A-14', 'DEFECT', id, null, 'no entry in clips.json');
    if (meta) {
      if (JSON.stringify(meta.ms) !== JSON.stringify(spec.ms)) add('A-14', 'DEFECT', id, null, `durations ${JSON.stringify(meta.ms)} ≠ contract ${JSON.stringify(spec.ms)}`);
      if (!!meta.loop !== !!spec.loop) add('A-14', 'DEFECT', id, null, `loop ${!!meta.loop} ≠ contract ${!!spec.loop}`);
    }
    const [cw, ch] = canvasOf(c, id);
    frames.forEach((img, i) => {
      if (img.width !== cw || img.height !== ch) add('A-01', 'DEFECT', id, i, `canvas ${img.width}×${img.height} ≠ ${cw}×${ch}`);
    });
  }
  for (const id of Object.keys(c.engine_drawn || {})) {
    if (source.frames(id)) add('V-04', 'DEFECT', id, null, 'delivered as art; this effect must be drawn in engine code');
  }

  // ---- characters: measure every frame ----
  for (const id of Object.keys(loaded)) {
    if (!isCharacter(c, id)) continue;
    metrics[id] = loaded[id].map((img) => {
      if (img.width !== canvasOf(c, id)[0] || img.height !== canvasOf(c, id)[1]) return null;
      return measureFrame(img, m);
    });
  }

  // ---- actor references (ART_CONTRACT §1 "reference values") ----
  const refs = {};
  for (const [name, a] of Object.entries(c.actors)) {
    const r = metrics[a.reference.clip];
    if (!r) continue;
    const ok = r.filter(Boolean);
    if (!ok.length) continue;
    refs[name] = {
      size: median(ok.map((x) => x.size)),
      height: median(ok.map((x) => x.height)),
      head: median(ok.map((x) => x.headWidth)),
    };
    const ref = refs[name];
    const band = heightBand(c, a.reference.clip, 0);
    if (band && (ref.height < band[0] || ref.height > band[1])) add('A-05', 'DEFECT', a.reference.clip, null, `reference height ${fmt(ref.height)} outside ${fmt(band[0])}–${fmt(band[1])}: every size check for ${name} is anchored on this clip`);
    if (a.head_ratio) {
      const ratio = ref.head / a.design_height;
      if (ratio < a.head_ratio[0] || ratio > a.head_ratio[1]) add('A-08', 'DEFECT', a.reference.clip, null, `reference head width ${fmt(ref.head)} px = ${fmt(ratio, 3)} × design height, outside ${a.head_ratio.join('–')}`);
    }
  }
  const missingRef = new Set();
  for (const id of Object.keys(metrics)) {
    const actor = c.clips[id].actor;
    if (!refs[actor] && !missingRef.has(actor)) {
      missingRef.add(actor);
      add('A-06', 'DEFECT', c.actors[actor].reference.clip, null, `reference clip for ${actor} missing or empty: size and head checks cannot run`);
    }
  }

  // ---- per-frame rules (A-01…A-09) ----
  for (const id of Object.keys(metrics)) {
    const spec = c.clips[id], a = c.actors[spec.actor], ref = refs[spec.actor];
    const headFails = [];
    let headFrames = 0;
    metrics[id].forEach((f, i) => {
      const img = loaded[id][i];
      if (!f) {
        if (img.width === canvasOf(c, id)[0]) add('A-01', 'DEFECT', id, i, 'empty frame (no ink)');
        return;
      }
      const cls = classOf(c, id, i), pc = c.pose_classes[cls];
      if (!cornersTransparent(img)) add('A-02', 'DEFECT', id, i, 'canvas corners are not transparent (opaque or keyed background)');
      const residue = keyResidue(img, m.ink_alpha);
      if (residue > 0) add('A-02', 'DEFECT', id, i, `${residue} px of chroma-key colour left in the art`);
      const edges = touchesEdge(f.bbox, img, m.edge_px).filter((s) => !(spec.bleed || []).includes(s));
      if (edges.length) add('A-03', 'DEFECT', id, i, `figure touches the canvas edge (${edges.join(', ')}): clipped art`);
      if (cls !== 'dissolve' && f.debris.length) add('A-04', 'DEFECT', id, i, `${f.debris.length} debris component(s), largest ${Math.max(...f.debris.map((d) => d.area))} px`);
      const band = heightBand(c, id, i);
      if (band && (f.height < band[0] - 0.5 || f.height > band[1] + 0.5)) add('A-05', 'DEFECT', id, i, `height ${f.height} px outside ${cls} band ${fmt(band[0])}–${fmt(band[1])}`);
      const sb = sizeBand(c, id, i);
      if (sb && ref) {
        const r = f.size / ref.size;
        if (r < sb[0] || r > sb[1]) add('A-06', 'DEFECT', id, i, `size ${fmt(r, 3)} × reference, outside ${cls} band ${sb.join('–')}`);
      }
      if (lowerBodyRule(c, id, i) && f.bootRatio > m.boot_ratio_max && f.legDip > m.leg_dip_max) {
        add('A-07', 'DEFECT', id, i, `no lower body: boot ratio ${fmt(f.bootRatio, 2)} > ${m.boot_ratio_max} and leg dip ${fmt(f.legDip, 2)} > ${m.leg_dip_max} (figure cut off above the legs?)`);
      }
      if (headRule(c, id, i) && ref) {
        headFrames++;
        const r = f.headWidth / ref.head;
        if (Math.abs(r - 1) > m.head_tol) headFails.push([i, r]);
      }
      const pivot = a.pivot;
      if (a.align === 'feet') {
        const off = f.foot - pivot[1];
        if (off < -pc.foot_tol_px) add('A-09', 'DEFECT', id, i, `feet ${-off} px above the pivot line (floating)`);
        else if (off > m.cloth_below_pivot_flag_px) add('A-09', 'DEFECT', id, i, `ink ${off} px below the pivot line`);
        else if (off > pc.foot_tol_px) add('A-09', 'FLAG', id, i, `ink ${off} px below the pivot line (cloth pooling?)`);
      } else {
        const cy = (f.bbox[1] + f.bbox[3]) / 2;
        if (Math.abs(cy - pivot[1]) > 2 * pc.foot_tol_px) add('A-09', 'DEFECT', id, i, `body centre ${fmt(cy - pivot[1])} px from the pivot`);
      }
    });
    if (headFails.length) {
      const isolated = headFails.length === 1 && headFrames >= 4;
      for (const [i, r] of headFails) {
        add('A-08', isolated ? 'FLAG' : 'DEFECT', id, i, `head width ${fmt(r, 3)} × standing reference (±${m.head_tol}): ${isolated ? 'single frame, reviewer adjudicates' : 'body parts changed size'}`);
      }
    }
    // A-11 pops and A-13 loop seam
    const fs = metrics[id];
    const pop = (p, q, i, rule, label) => {
      if (!p || !q) return;
      if (classOf(c, id, i) !== classOf(c, id, i - 1 < 0 ? fs.length - 1 : i - 1)) return;
      const ds = Math.abs(q.size / p.size - 1), dh = Math.abs(q.height / p.height - 1);
      const steady = m.pop_height_classes.includes(classOf(c, id, i));
      if (ds > m.pop_size || (steady && dh > m.pop_height)) add(rule, 'FLAG', id, i, `${label}: size ${fmt(ds * 100)}%, height ${fmt(dh * 100)}%`);
    };
    for (let i = 1; i < fs.length; i++) pop(fs[i - 1], fs[i], i, 'A-11', `jump from frame ${i - 1}`);
    if (spec.loop && fs.length > 1) pop(fs[fs.length - 1], fs[0], 0, 'A-13', 'loop seam from the last frame');
  }

  // ---- A-12 one size per pose class across clips ----
  for (const name of Object.keys(c.actors)) {
    const byClass = {};
    for (const id of Object.keys(metrics)) {
      if (c.clips[id].actor !== name || id === c.actors[name].reference.clip || c.clips[id].size) continue;
      metrics[id].forEach((f, i) => {
        if (!f) return;
        const cls = classOf(c, id, i);
        ((byClass[cls] ||= {})[id] ||= []).push(f.size);
      });
    }
    for (const [cls, clips] of Object.entries(byClass)) {
      const ids = Object.keys(clips);
      if (ids.length < 2) continue;
      const clipMed = Object.fromEntries(ids.map((id) => [id, median(clips[id])]));
      const all = median(Object.values(clipMed));
      for (const id of ids) {
        const dev = clipMed[id] / all - 1;
        if (Math.abs(dev) > m.clip_consistency) {
          const strict = m.clip_consistency_strict_classes.includes(cls);
          add('A-12', strict ? 'DEFECT' : 'FLAG', id, null, `clip median size ${fmt(dev * 100)}% from ${name}'s ${cls} median: drawn at a different scale`);
        }
      }
    }
  }

  // ---- whip (W-01…W-06) ----
  const w = c.whip;
  for (const id of Object.keys(loaded)) {
    const spec = c.clips[id];
    if (spec.actor !== 'whip') continue;
    const sockets = source.sockets && source.sockets[spec.body];
    if (!sockets || sockets.length !== spec.ms.length) {
      add('W-01', 'DEFECT', id, null, `hand_sockets.json has no ${spec.ms.length}-frame entry for ${spec.body}`);
      continue;
    }
    const tipDist = [];
    metrics[id] = [];
    loaded[id].forEach((img, i) => {
      if (img.width !== w.canvas[0] || img.height !== w.canvas[1]) { tipDist.push(null); return; }
      const { width, height } = img;
      const ink = inkMask(img, m.ink_alpha);
      const [sx, sy] = sockets[i];
      let n = 0, x0 = width, y0 = height, x1 = -1, y1 = -1, near = Infinity, tip = 0, tipX = 0, tipY = 0, maxX = -1;
      let gx = 0, gy = 0, gn = 0;
      for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
        if (!ink[y * width + x]) continue;
        n++;
        if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
        const d = Math.hypot(x - sx, y - sy);
        if (d < near) near = d;
        if (d > tip) { tip = d; tipX = x; tipY = y; }
        if (d <= 16) { gx += x; gy += y; gn++; }
        if (x > maxX) maxX = x;
      }
      metrics[id].push(n ? { bbox: [x0, y0, x1, y1], tip, near } : null);
      if (!n) { add('W-06', 'DEFECT', id, i, 'blank whip frame during the attack'); tipDist.push(null); return; }
      tipDist.push(tip);
      if (!cornersTransparent(img)) add('A-02', 'DEFECT', id, i, 'canvas corners are not transparent');
      if (keyResidue(img, m.ink_alpha)) add('A-02', 'DEFECT', id, i, 'chroma-key colour left in the art');
      const edges = touchesEdge([x0, y0, x1, y1], img, m.edge_px);
      if (edges.length) add('A-03', 'DEFECT', id, i, `whip touches the canvas edge (${edges.join(', ')})`);
      if (near > w.socket_contact_px) add('W-01', 'DEFECT', id, i, `nearest whip ink is ${fmt(near)} px from the hand socket (${sx}, ${sy}): not held`);
      else if (gn && Math.hypot(gx / gn - sx, gy / gn - sy) > w.grip_centre_px) add('W-01', 'DEFECT', id, i, `grip centre ${fmt(Math.hypot(gx / gn - sx, gy / gn - sy))} px from the socket`);
      const inside = distanceTo(ink, width, height, 0);
      let rootT = 0, tipT = 0;
      for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
        const k = y * width + x;
        if (!ink[k]) continue;
        const t = 2 * inside[k] - 1;
        const ds = Math.hypot(x - sx, y - sy);
        if (ds >= w.root_zone_px[0] && ds <= w.root_zone_px[1]) rootT = Math.max(rootT, t);
        if (Math.hypot(x - tipX, y - tipY) <= w.tip_zone_px) tipT = Math.max(tipT, t);
      }
      if (rootT > w.root_thickness_max_px) add('W-02', 'DEFECT', id, i, `whip ${fmt(rootT)} px thick near the grip (max ${w.root_thickness_max_px})`);
      if (!spec.coiled.includes(i) && tipT > w.tip_thickness_max_px) add('W-02', 'DEFECT', id, i, `whip ${fmt(tipT)} px thick at the tip (max ${w.tip_thickness_max_px})`);
      if (spec.coiled.includes(i)) {
        const cw = x1 - x0 + 1, ch = y1 - y0 + 1;
        if (cw > w.coil_max_px || ch > w.coil_max_px) add('W-03', 'DEFECT', id, i, `coil ${cw}×${ch} px exceeds ${w.coil_max_px} px (0.55 × standing height)`);
      }
      if (spec.active.includes(i) && maxX - w.pivot[0] < w.active_reach_min_px) add('W-04', 'DEFECT', id, i, `reach ${maxX - w.pivot[0]} px < ${w.active_reach_min_px} px hitbox at an active frame`);
    });
    const t = w.progression_tol_px;
    for (let i = 1; i <= 3 && i < tipDist.length; i++) {
      if (tipDist[i] != null && tipDist[i - 1] != null && tipDist[i] < tipDist[i - 1] - t) add('W-05', 'DEFECT', id, i, `tip retracts ${fmt(tipDist[i - 1] - tipDist[i])} px during the extension (frames 0–3 must extend)`);
    }
    for (let i = 5; i < tipDist.length; i++) {
      if (tipDist[i] != null && tipDist[i - 1] != null && tipDist[i] > tipDist[i - 1] + t) add('W-05', 'DEFECT', id, i, `tip extends ${fmt(tipDist[i] - tipDist[i - 1])} px during the recovery (frames 4–7 must retract)`);
    }
  }

  // ---- effects (V-01…V-03) ----
  for (const id of Object.keys(loaded)) {
    const spec = c.clips[id];
    if (spec.actor !== 'vfx') continue;
    const ext = [];
    metrics[id] = [];
    loaded[id].forEach((img, i) => {
      const { width, height, data } = img;
      if (width !== spec.canvas[0] || height !== spec.canvas[1]) { ext.push(null); return; }
      let border = 0, x0 = width, y0 = height, x1 = -1, y1 = -1;
      for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
        const a = data[(y * width + x) * 4 + 3];
        const onBorder = x < c.vfx.border_px || y < c.vfx.border_px || x >= width - c.vfx.border_px || y >= height - c.vfx.border_px;
        if (onBorder && a > 8) border++;
        if (a >= m.ink_alpha) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      }
      if (border) add('V-01', 'DEFECT', id, i, `${border} px of alpha on the canvas border: the effect shows a rectangle edge`);
      if (x1 < 0) {
        metrics[id].push(null);
        const fade = spec.size_curve && i === loaded[id].length - 1;
        if (!fade) add('A-01', 'DEFECT', id, i, 'empty effect frame');
        ext.push(fade ? 0 : null);
        return;
      }
      if (keyResidue(img, m.ink_alpha)) add('A-02', 'DEFECT', id, i, 'chroma-key colour left in the art');
      const e = Math.max(x1 - x0 + 1, y1 - y0 + 1);
      metrics[id].push({ bbox: [x0, y0, x1, y1], extent: e });
      ext.push(e);
      const ax = (x0 + x1) / 2, ay = spec.anchor_mode === 'base' ? y1 : (y0 + y1) / 2;
      const off = Math.hypot(ax - spec.anchor[0], ay - spec.anchor[1]);
      if (off > c.vfx.anchor_tol_px) add('V-02', 'DEFECT', id, i, `anchor off by ${fmt(off)} px (max ${c.vfx.anchor_tol_px})`);
      if (e > spec.max_extent_px) add('V-03', 'DEFECT', id, i, `extent ${e} px > max ${spec.max_extent_px} px`);
    });
    if (spec.size_curve) {
      const e = ext.map((x) => x ?? 0);
      const peak = e.indexOf(Math.max(...e));
      let small = 0;
      for (let i = 1; i < e.length; i++) {
        const rising = i <= peak;
        const wrong = rising ? e[i] < e[i - 1] : e[i] > e[i - 1];
        if (!wrong) continue;
        const rel = Math.abs(e[i] - e[i - 1]) / Math.max(e[i - 1], 1);
        if (rel > c.vfx.wobble) add('V-03', 'DEFECT', id, i, `size ${rising ? 'drops' : 'jumps back up'} ${fmt(rel * 100)}% (${e[i - 1]} → ${e[i]} px): the effect pops instead of growing then fading`);
        else if (++small > 1) add('V-03', 'DEFECT', id, i, 'more than one wobble in the size curve');
      }
    }
  }

  const defects = findings.filter((f) => f.severity === 'DEFECT').length;
  return { findings, metrics, refs, defects, flags: findings.length - defects, clips: Object.keys(loaded).length };
}

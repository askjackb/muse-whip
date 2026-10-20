// Frame measurements defined in docs/ART_CONTRACT.md §1.
// All coordinates are source pixels on the delivered canvas, y down.

// Binary ink mask: alpha >= threshold.
export function inkMask(img, alphaMin) {
  const { width, height, data } = img;
  const m = new Uint8Array(width * height);
  for (let i = 0; i < width * height; i++) m[i] = data[i * 4 + 3] >= alphaMin ? 1 : 0;
  return m;
}

// 8-connected components. Returns { labels: Int32Array, comps: [{id, area, x0,y0,x1,y1}] }.
export function components(mask, width, height) {
  const labels = new Int32Array(width * height);
  const comps = [];
  const stack = new Int32Array(width * height);
  let next = 0;
  for (let start = 0; start < mask.length; start++) {
    if (!mask[start] || labels[start]) continue;
    next++;
    let sp = 0, area = 0;
    let x0 = width, y0 = height, x1 = -1, y1 = -1;
    stack[sp++] = start;
    labels[start] = next;
    while (sp) {
      const p = stack[--sp];
      const x = p % width, y = (p - x) / width;
      area++;
      if (x < x0) x0 = x; if (x > x1) x1 = x;
      if (y < y0) y0 = y; if (y > y1) y1 = y;
      for (let dy = -1; dy <= 1; dy++) {
        const ny = y + dy;
        if (ny < 0 || ny >= height) continue;
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx;
          if (nx < 0 || nx >= width) continue;
          const q = ny * width + nx;
          if (mask[q] && !labels[q]) { labels[q] = next; stack[sp++] = q; }
        }
      }
    }
    comps.push({ id: next, area, x0, y0, x1, y1 });
  }
  return { labels, comps };
}

// Chamfer (3-4) distance from every pixel to the nearest pixel where src == target.
// Returns Float32Array of approximate Euclidean distances in px.
export function distanceTo(src, width, height, target = 1) {
  const INF = 1e9;
  const d = new Float32Array(width * height);
  for (let i = 0; i < d.length; i++) d[i] = src[i] === target ? 0 : INF;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = y * width + x;
      let v = d[i];
      if (x > 0) v = Math.min(v, d[i - 1] + 3);
      if (y > 0) {
        v = Math.min(v, d[i - width] + 3);
        if (x > 0) v = Math.min(v, d[i - width - 1] + 4);
        if (x < width - 1) v = Math.min(v, d[i - width + 1] + 4);
      }
      d[i] = v;
    }
  }
  for (let y = height - 1; y >= 0; y--) {
    for (let x = width - 1; x >= 0; x--) {
      const i = y * width + x;
      let v = d[i];
      if (x < width - 1) v = Math.min(v, d[i + 1] + 3);
      if (y < height - 1) {
        v = Math.min(v, d[i + width] + 3);
        if (x < width - 1) v = Math.min(v, d[i + width + 1] + 4);
        if (x > 0) v = Math.min(v, d[i + width - 1] + 4);
      }
      d[i] = v;
    }
  }
  for (let i = 0; i < d.length; i++) d[i] /= 3;
  return d;
}

// Figure = largest component plus every component within attachPx of the growing figure.
// Everything else with area >= debrisMin is debris.
export function figureOf(img, m) {
  const { width, height } = img;
  const mask = inkMask(img, m.ink_alpha);
  const { labels, comps } = components(mask, width, height);
  if (!comps.length) return null;
  comps.sort((a, b) => b.area - a.area);
  const inFig = new Set([comps[0].id]);
  let changed = true;
  while (changed) {
    changed = false;
    const fig = new Uint8Array(width * height);
    for (let i = 0; i < labels.length; i++) if (inFig.has(labels[i])) fig[i] = 1;
    const dist = distanceTo(fig, width, height, 1);
    for (const c of comps) {
      if (inFig.has(c.id)) continue;
      for (let y = c.y0; y <= c.y1 && !inFig.has(c.id); y++) {
        for (let x = c.x0; x <= c.x1; x++) {
          const i = y * width + x;
          if (labels[i] === c.id && dist[i] <= m.attach_px) { inFig.add(c.id); changed = true; break; }
        }
      }
    }
  }
  const fig = new Uint8Array(width * height);
  let area = 0, x0 = width, y0 = height, x1 = -1, y1 = -1;
  for (let i = 0; i < labels.length; i++) {
    if (!inFig.has(labels[i])) continue;
    fig[i] = 1; area++;
    const x = i % width, y = (i - x) / width;
    if (x < x0) x0 = x; if (x > x1) x1 = x;
    if (y < y0) y0 = y; if (y > y1) y1 = y;
  }
  const debris = comps.filter((c) => !inFig.has(c.id) && c.area >= m.debris_min_area_px)
    .map(({ area, x0, y0, x1, y1 }) => ({ area, bbox: [x0, y0, x1, y1] }));
  return { mask: fig, inkMask: mask, area, bbox: [x0, y0, x1, y1], debris };
}

// Silhouette and anatomy metrics for one frame (ART_CONTRACT §1).
export function measureFrame(img, m) {
  const f = figureOf(img, m);
  if (!f) return null;
  const { width } = img;
  const [x0, y0, x1, y1] = f.bbox;
  const H = y1 - y0 + 1, W = x1 - x0 + 1;
  const rows = new Float64Array(H);
  for (let y = y0; y <= y1; y++) {
    let c = 0;
    for (let x = x0; x <= x1; x++) c += f.mask[y * width + x];
    rows[y - y0] = c;
  }
  const maxRow = Math.max(...rows);
  const hb = Math.max(1, Math.round(H * m.head_band));
  const bb = Math.max(1, Math.round(H * m.boot_band));
  let headW = 0;
  for (let i = 0; i < hb; i++) headW = Math.max(headW, rows[i]);
  let bootSum = 0;
  for (let i = H - bb; i < H; i++) bootSum += rows[i];
  const lz0 = Math.floor(m.leg_zone[0] * H), lz1 = Math.max(lz0 + 1, Math.floor(m.leg_zone[1] * H));
  let legMin = Infinity;
  for (let i = lz0; i < lz1; i++) legMin = Math.min(legMin, rows[i]);
  return {
    bbox: f.bbox, height: H, width: W, area: f.area, size: Math.sqrt(f.area),
    top: y0, foot: y1, headWidth: headW,
    bootRatio: maxRow ? bootSum / bb / maxRow : 0,
    legDip: maxRow && Number.isFinite(legMin) ? legMin / maxRow : 0,
    debris: f.debris, figure: f,
  };
}

// Count of pixels that look like left-over chroma key (pure magenta or pure green screen).
export function keyResidue(img, alphaMin) {
  const { width, height, data } = img;
  let n = 0;
  for (let i = 0; i < width * height; i++) {
    const r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2], a = data[i * 4 + 3];
    if (a < alphaMin) continue;
    if (r > 200 && b > 200 && g < 80) n++;
    else if (g > 180 && r < 60 && b < 60) n++;
  }
  return n;
}

export function cornersTransparent(img) {
  const { width: w, height: h, data } = img;
  return [0, w - 1, (h - 1) * w, h * w - 1].every((p) => data[p * 4 + 3] === 0);
}

// True when any ink lies within edgePx of the canvas edge.
export function touchesEdge(bbox, img, edgePx) {
  const [x0, y0, x1, y1] = bbox;
  const sides = [];
  if (x0 < edgePx) sides.push('left');
  if (y0 < edgePx) sides.push('top');
  if (x1 > img.width - 1 - edgePx) sides.push('right');
  if (y1 > img.height - 1 - edgePx) sides.push('bottom');
  return sides;
}

export const median = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const n = s.length;
  return n ? (n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2) : NaN;
};

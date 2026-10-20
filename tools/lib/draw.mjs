// Drawing helpers for review sheets: compositing, guide lines, outlines and a 5×7 bitmap font.
import { blank } from './png.mjs';

export const GREY = [118, 118, 118, 255];
export const INK = {
  ground: [235, 64, 52, 255], design: [64, 200, 235, 255], crouch: [240, 210, 60, 255],
  socket: [0, 255, 255, 255], hitbox: [255, 230, 0, 255], text: [255, 255, 255, 255], pivot: [255, 64, 200, 255],
};

export const canvas = (w, h, bg = GREY) => blank(w, h, bg);

// Alpha-composite src (optionally tinted) onto dst at (dx, dy), reading src rect (sx, sy, w, h).
export function paste(dst, src, dx, dy, { sx = 0, sy = 0, w = src.width, h = src.height, tint = null, alpha = 1 } = {}) {
  for (let y = 0; y < h; y++) {
    const ty = dy + y, fy = sy + y;
    if (ty < 0 || ty >= dst.height || fy < 0 || fy >= src.height) continue;
    for (let x = 0; x < w; x++) {
      const tx = dx + x, fx = sx + x;
      if (tx < 0 || tx >= dst.width || fx < 0 || fx >= src.width) continue;
      const s = (fy * src.width + fx) * 4, d = (ty * dst.width + tx) * 4;
      const a = (src.data[s + 3] / 255) * alpha;
      if (!a) continue;
      for (let k = 0; k < 3; k++) {
        const v = tint ? src.data[s + k] * 0.35 + tint[k] * 0.65 : src.data[s + k];
        dst.data[d + k] = Math.round(v * a + dst.data[d + k] * (1 - a));
      }
      dst.data[d + 3] = 255;
    }
  }
}

export function hline(img, x0, x1, y, col, dash = 0) {
  if (y < 0 || y >= img.height) return;
  for (let x = Math.max(0, x0); x <= Math.min(img.width - 1, x1); x++) {
    if (dash && Math.floor((x - x0) / dash) % 2) continue;
    img.data.set(col, (y * img.width + x) * 4);
  }
}

export function vline(img, x, y0, y1, col) {
  if (x < 0 || x >= img.width) return;
  for (let y = Math.max(0, y0); y <= Math.min(img.height - 1, y1); y++) img.data.set(col, (y * img.width + x) * 4);
}

export function rect(img, x0, y0, x1, y1, col) {
  hline(img, x0, x1, y0, col); hline(img, x0, x1, y1, col); vline(img, x0, y0, y1, col); vline(img, x1, y0, y1, col);
}

export function cross(img, x, y, r, col) {
  hline(img, x - r, x + r, y, col); vline(img, x, y - r, y + r, col);
}

const GLYPHS = {
  A: [14, 17, 17, 31, 17, 17, 17], B: [30, 17, 17, 30, 17, 17, 30], C: [14, 17, 16, 16, 16, 17, 14], D: [30, 17, 17, 17, 17, 17, 30],
  E: [31, 16, 16, 30, 16, 16, 31], F: [31, 16, 16, 30, 16, 16, 16], G: [14, 17, 16, 23, 17, 17, 15], H: [17, 17, 17, 31, 17, 17, 17],
  I: [14, 4, 4, 4, 4, 4, 14], J: [7, 2, 2, 2, 2, 18, 12], K: [17, 18, 20, 24, 20, 18, 17], L: [16, 16, 16, 16, 16, 16, 31],
  M: [17, 27, 21, 21, 17, 17, 17], N: [17, 17, 25, 21, 19, 17, 17], O: [14, 17, 17, 17, 17, 17, 14], P: [30, 17, 17, 30, 16, 16, 16],
  Q: [14, 17, 17, 17, 21, 18, 13], R: [30, 17, 17, 30, 20, 18, 17], S: [15, 16, 16, 14, 1, 1, 30], T: [31, 4, 4, 4, 4, 4, 4],
  U: [17, 17, 17, 17, 17, 17, 14], V: [17, 17, 17, 17, 17, 10, 4], W: [17, 17, 17, 21, 21, 21, 10], X: [17, 17, 10, 4, 10, 17, 17],
  Y: [17, 17, 17, 10, 4, 4, 4], Z: [31, 1, 2, 4, 8, 16, 31],
  0: [14, 17, 19, 21, 25, 17, 14], 1: [4, 12, 4, 4, 4, 4, 14], 2: [14, 17, 1, 2, 4, 8, 31], 3: [31, 2, 4, 2, 1, 17, 14],
  4: [2, 6, 10, 18, 31, 2, 2], 5: [31, 16, 30, 1, 1, 17, 14], 6: [6, 8, 16, 30, 17, 17, 14], 7: [31, 1, 2, 4, 8, 8, 8],
  8: [14, 17, 17, 14, 17, 17, 14], 9: [14, 17, 17, 15, 1, 2, 12],
  _: [0, 0, 0, 0, 0, 0, 31], '-': [0, 0, 0, 31, 0, 0, 0], '.': [0, 0, 0, 0, 0, 12, 12], ':': [0, 12, 12, 0, 12, 12, 0],
  '/': [0, 1, 2, 4, 8, 16, 0], '%': [24, 25, 2, 4, 8, 19, 3], '(': [2, 4, 8, 8, 8, 4, 2], ')': [8, 4, 2, 2, 2, 4, 8], ' ': [0, 0, 0, 0, 0, 0, 0],
};

// Draws text in capitals; returns the width used. Each glyph is 5×7 at the given scale, 1 column apart.
export function text(img, x, y, str, col = INK.text, scale = 2) {
  let cx = x;
  for (const ch of String(str).toUpperCase()) {
    const g = GLYPHS[ch] || GLYPHS[' '];
    for (let r = 0; r < 7; r++) for (let b = 0; b < 5; b++) {
      if (!(g[r] & (16 >> b))) continue;
      for (let sy = 0; sy < scale; sy++) for (let sx = 0; sx < scale; sx++) {
        const px = cx + b * scale + sx, py = y + r * scale + sy;
        if (px >= 0 && py >= 0 && px < img.width && py < img.height) img.data.set(col, (py * img.width + px) * 4);
      }
    }
    cx += 6 * scale;
  }
  return cx - x;
}

export const textWidth = (str, scale = 2) => String(str).length * 6 * scale;

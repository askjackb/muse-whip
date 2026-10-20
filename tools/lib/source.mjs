// Frame sources for the audit: a directory on disk, or an in-memory map (self-test).
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { readPNG } from './png.mjs';

const readJSON = (p) => (existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : null);

export function dirSource(root) {
  const cache = new Map();
  return {
    frames(clip) {
      if (cache.has(clip)) return cache.get(clip);
      const dir = join(root, clip);
      let frames = null;
      if (existsSync(dir)) {
        frames = readdirSync(dir).filter((f) => /^f\d{3}\.png$/.test(f)).sort().map((f) => readPNG(join(dir, f)));
      }
      cache.set(clip, frames);
      return frames;
    },
    meta: readJSON(join(root, 'clips.json')),
    sockets: readJSON(join(root, 'hand_sockets.json')),
  };
}

export function memorySource({ frames, meta, sockets }) {
  return { frames: (clip) => frames[clip] || null, meta, sockets };
}

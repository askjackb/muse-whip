# Reference tools

Zero-dependency Node.js (20 or later) tools that check art against [docs/ART_CONTRACT.md](../docs/ART_CONTRACT.md). They read and write PNG with the built-in `zlib`; nothing to install.

| Command | What it does | Gate |
|---|---|---|
| `node tools/contract-check.mjs` | Checks `contract/art_contract.json` for internal consistency and against `docs/ASSET_BRIEFS.md`: frame counts, per-frame durations, canvases, pivots, whip timing, and that every height a clip may reach fits its canvas | V0 |
| `node tools/selftest.mjs [--write <dir>]` | Synthesises a correct frame set for every clip (must pass), then 25 known defects one at a time (each must be caught by the rule aimed at it). About 40 s. `--write` keeps the correct set as PNGs, a working example of the frames layout | must pass before any art is audited |
| `node tools/audit-art.mjs --frames <root> [--out <dir>] [--only <regex>] [--allow-missing]` | Runs every automated rule; writes `audit.json` and `audit.md`; exit 1 on any DEFECT | V2 |
| `node tools/review-pack.mjs --frames <root> [--out <dir>]` | Builds the images the independent reviewer judges: lineups, strips, onion skins, body+whip composites, plus the audit and an index | V1, V3 |

## Frames layout

```
<root>/
  clips.json            { "<clip_id>": { "ms": [...], "loop": true|false } }   delivered timing
  hand_sockets.json     { "hero_attack_ground": [[x, y], ...one per frame], ... }   source px
  derivations.json      optional: { "<clip_id>": { "kind", "source", "method", "reason" } }
  style_hero_neutral/f000.png
  hero_idle/f000.png … f007.png
  …one folder per clip id in contract/art_contract.json, frames at the contract canvas size
```

Frames are the delivered, normalised frames before atlas packing: RGBA PNG at the exact contract canvas, the figure placed on the contract pivot.

## Limits, stated plainly

- The automated rules are tripwires. They measure silhouettes, not drawings: they cannot tell a face changed, a costume drifted, or a pose reads wrong. That is the reviewer's job (ART_CONTRACT §9), and a PASS from the audit alone never approves art.
- The anatomy proxies (head width, lower-body ratios) are heuristics calibrated on one real art set. The self-test shows one way to fool the lower-body proxy (hands hanging below a cut-off torso); the head rule catches that case. New defect classes found in production get a self-test case first.
- Thresholds live in `contract/art_contract.json`, not in code. Change them there, with a reason in `docs/DECISIONS.md`.

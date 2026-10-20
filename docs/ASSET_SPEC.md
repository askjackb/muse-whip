# Game asset specification — proposed production contract

All dimensions below are proposed and must be calibrated before production. This document is the authority for visual scale; SPEC.md owns gameplay timing. Neither a generated sprite sheet nor this document constitutes a tested engine import.

## 1. Coordinate spaces and delivery

| Property | Proposed contract |
|---|---|
| Logical viewport | 1280×720 game units; positive x right, positive y down |
| Terrain module | 64×64 game units |
| Art density | 2 source pixels per game unit; imported visual scale 0.5 |
| Hero height | 112 game units standing (224 source px); hair/equipment accents may exceed within canvas |
| Hero frame | 512×512 source px → 256×256 game units |
| Hero foot pivot | (256, 448) source px from top-left; local game origin (0, 0) at that pivot |
| Facing | Right in source frames; mirror around foot origin for left |
| Sprite source | Lossless RGBA PNG, actual transparent alpha, sRGB |
| Terrain source | 128×128 source px per 64-unit module; larger props use documented multiples |
| Atlas | Target maximum 2048×2048 px per page; split by animation/layer as needed |
| Sampling | Painted branch: linear filtering; no lossy source compression; verify halo-free alpha |

Do not confuse source pixels, logical game units, and displayed screen pixels. Cropped runtime regions must retain original canvas size, trim offset, and pivot. Packing may trim transparent space; generation/export must preserve alignment metadata. Do not automatically rescale each animation frame to fit its visible bounding box.

## 2. Hero and whip are separate visual layers

Hero body frames use the fixed canvas above. Whip frames use a 768×512 source-pixel canvas with foot-origin anchor (256, 448), allowing up to 256 game units to the right of the shared origin. Each synchronized pose records the hand socket relative to the hero origin. The whip root must meet that socket. Source-space socket coordinates are converted using the density before placement.

Both layers share animation time and facing. A one-piece full-body-plus-whip render is an optional reference, not the required runtime deliverable. The separate weapon avoids shrinking the hunter or clipping long attacks to fit a small frame. No baked floor shadows or hitbox outlines in production frames.

Start with a standing collision body of approximately 40×104 game units, centered at (0, -52), subject to engine collision review. This is gameplay geometry, not the visible sprite silhouette. Whip hitboxes come from SPEC.md and must be reviewed with an overlay; they must not include anticipation/recovery frames or deal damage twice per target per strike.

## 3. Animation inventory

The authoritative state/frame/timing contract is [ANIMATION_SPEC.md](ANIMATION_SPEC.md). Full animation for every supported action is a confirmed requirement. Do not substitute a single still, translate a static cutout, or reuse one pose across walking/jumping/damage/death.

Ground, air, and crouched attacks each use eight proposed body frames and eight synchronized whip frames with durations [75,75,50,50,62.5,62.5,62.5,62.5] ms. Frames 0–1 anticipate, 2–3 are active, and 4–7 recover. This preserves SPEC.md's 500 ms combat timeline. Full character acting must remain visible throughout all phases.

Grounded idle/attack foot baseline must not drift by more than 2 source px. Walk feet follow intentional contact phases; world translation belongs to gameplay. Keep face, costume seams, armor count, anatomy, and weapon identity stable. Crouch changes visible posture and collision deliberately; do not resize the entire sprite to simulate crouching.

Enemy and boss coverage must follow the same no-static-substitute rule. Each brief defines its own sizes, pivots, complete state set, frame timing, tells, sockets, and collision; do not reuse the hunter's frame size by default.

## 4. Terrain and environment

Initial terrain kit: top-left/top-middle/top-right caps; exposed left/right sides; center fill; bottom corners/edge; inner corners; isolated platform ends/middle; one-way-platform appearance only if later approved. Build and inspect a repeated 3×3 patch and multiple silhouette shapes. Decorative cracks never change collision.

Separate foreground decoration, collidable terrain, midground architecture, distant silhouette, sky, and fog. Decorative assets must declare `collision: none`. Walkable top edges sit exactly on the module boundary. Horizontal backgrounds declare whether they tile and their seam axis; otherwise supply sufficient width and camera bounds. Foreground cannot obscure required landing zones or attack tells.

## 5. UI, effects, and audio inventory

UI: health full/empty, left/right/jump/whip/crouch/pause buttons with normal/pressed states, checkpoint indicator, death/retry, victory/exit, rotate prompt. Text remains live UI text; do not generate lettering into textures. Each icon must be legible at its actual touch target size.

VFX: whip impact, enemy defeat, player damage indicator, checkpoint activation. Brief each effect's timing, frame bounds, anchor, and compositing; keep telegraphs readable. No rapid flashing as a substitute for readable damage feedback.

Audio is a later scoped asset task: whip swing/hit, jump/land, damage/death, enemy tell, checkpoint, boss tell, one ambience loop, one music loop. Deliver original/licensed sources with sample rate, channels, loop points, and peak/headroom requirements specified before production. No audio production or franchise soundtrack extraction in this planning phase.

## 6. Naming, manifest, and provenance

Stable IDs: lowercase snake_case. Candidate names: `{asset_id}__rNN__fNNN.png`; versions immutable after review. Proposed future layout: `art/source/`, `art/candidates/`, `art/approved/`, `art/previews/`, and `art/manifests/`. These paths are conventions, not existing art deliveries.

Each manifest must include ID, state (`candidate`, `approved`, `rejected`), revision, brief and style-lock references, tool/model/seed when known, prompt/reference records, canvas/pivot/density, frame paths and durations, sockets/events/collision references, alpha/color space, provenance, review results, and rejection reasons. File hashes should be added when real files exist. [The JSON example](../templates/asset-manifest.example.json) is illustrative and intentionally lists paths to assets that do not exist yet.

## 7. Quality gate

**Since 2026-10-12 the measurable gate is [ART_CONTRACT.md](ART_CONTRACT.md)**, run by `tools/audit-art.mjs` and confirmed by the independent reviewer (ART_CONTRACT §9). The order below still describes what is checked; the contract says how, with which tolerances, and what a failure blocks.

Check in order: technical dimensions/alpha → identity and scale → frame alignment/temporal consistency → attack socket/hitbox sync → tiling/seams → phone-size readability → future engine import and mobile budget. Failure at any stage keeps the asset out of `approved`.

A contact sheet alone cannot prove animation quality. Require timed playback, an origin/socket overlay, dark and light alpha-edge previews, the actual-scale scene, and a recorded reviewer verdict. Tool-produced claims of transparency or frame count are not verification. Never conceal a defective frame with interpolation, aggressive blur, or frame-by-frame stretching.

# Lessons from the first implementation

One complete build of this specification exists: [askjackb/gothic-whip-game](https://github.com/askjackb/gothic-whip-game) (playable at https://askjackb.github.io/gothic-whip-game/), with its production log in [askjackb/gothic-whip](https://github.com/askjackb/gothic-whip) (`docs/REVIEW_RECORD.md`, `docs/SPRITE_TESTING.md`). It used Godot 4.7.2, 64 clips / 357 AI-painted frames, and was built autonomously in two days (2026-10-08 to 2026-10-09). It then needed five rounds of fixes, every one triggered by a person looking at the running game.

This file records what that build proved about the specification, so that the next implementation does not pay for the same lessons. Each lesson points to the rule that now encodes it.

## Art

| # | What happened | What the spec lacked | Now encoded in |
|---|---|---|---|
| L1 | Clips generated as separate sheets came out at different scales (walk −14%, crouch taller than standing). A per-actor scale did not fix it, and neither did a per-clip median | A per-frame size rule; a size measure that survives pose changes | ART_CONTRACT A-05, A-06, A-12, G-03 |
| L2 | The standing idle was a waist-up torso stretched to 224 px. Three audits passed it, because a stretched torso has the right bounding box | Anatomy rules; a reviewer forced to describe what it sees | ART_CONTRACT A-07, A-08, §9 |
| L3 | Crouch transitions were drawn as a smaller man (head 31–33 px against 38), so crouching read as zooming out | "Rigid parts keep their size" | ART_CONTRACT A-08 in the crouch and transition classes |
| L4 | The whip floated beside an empty fist, and its coil was the hero's height | Hand socket, grip, thickness and coil-size rules | ART_CONTRACT W-01…W-06 |
| L5 | The whip jumped between unrelated shapes (coil, coil, arc, straight bar); impact effects jumped from 102 to 256 px and back | Motion-progression and effect-size-curve rules | ART_CONTRACT W-05, V-03 |
| L6 | The boss had the torso defect too; the leg check had exempted "robe" characters | One anatomy rule applied to every actor with legs | ART_CONTRACT §2 "has legs" column |
| L7 | A full-screen red vignette went through green-screen keying and came out fully transparent: the damage flash never rendered | Screen effects belong in engine code | ART_CONTRACT V-04 |
| L8 | Specks, cell-border rectangles and a detached hand survived extraction; some frames were cut off by too small an extraction canvas | Extraction rules | ART_CONTRACT A-03, A-04, G-05 |
| L9 | Each fix claimed "verified" and was wrong three times, because every check measured extents | Checks proven to fail on the defect | ART_CONTRACT §10, `tools/selftest.mjs` |
| L10 | A fast motion (the 500 ms whip) cannot be judged from browser screenshots, which took ~1.3 s each in headless Chromium | Motion review from frame data | Onion-skin sheets (§9); engine frame-step test (VALIDATION V3) |
| L11 | When the image service failed mid-fix, an idle was rebuilt from another clip's frame plus a scripted breathing loop | A policy for fallbacks | ART_CONTRACT §11 (allowed, labelled, reviewed) |

## Gameplay

| # | What happened | What the spec lacked | Now encoded in |
|---|---|---|---|
| L12 | Crouching under a thin one-way platform trapped the hunter permanently: the clearance check counted the one-way slab as a ceiling, so neither standing, jumping nor moving was possible | What one-way platforms do to clearance; a no-trap rule | GAMEPLAY_RULES §6.1 |
| L13 | Ordinary crouching never switched to the 40×60 crouch body (only one landing path did), so crouch did not dodge anything. Every test passed | A test tied to each rule | VALIDATION "Rule-to-test traceability" |
| L14 | The jump rose 133.4 u, not the analytic 128 u, from discrete integration | A tolerance for measured motion | GAMEPLAY_RULES §6.1 note; VALIDATION V3 |

## Pipeline and verification

| # | What happened | Now encoded in |
|---|---|---|
| L15 | After repacking atlas PNGs, Godot kept sampling its old import cache, and the whip briefly drew a swooper wing | TECHNICAL_SPEC §7: re-import after every repack; compare packed atlases against source frames pixel by pixel |
| L16 | Proving the live site matched the local build needed a checksum of the downloaded `.pck` | TECHNICAL_SPEC §7 |
| L17 | All runtime evidence came from desktop Chromium with software rendering; the iPhone 17 target was never tested | VALIDATION: device gates stay PENDING and are reported as such in every handoff |

## What worked and should be kept

- Treating state machines as authoritative and sprites as passive (the whip frame is locked to attack time, not to animation playback).
- Archiving every pre-fix frame, which made each fix reversible and let each new check be proven against the old defect.
- Writing what was *not* tested in every review entry.
- The gameplay numbers: every constant in the shipped code equals this specification's, and the derived proofs (jump envelope, whip timing, boss punish windows) held in play.

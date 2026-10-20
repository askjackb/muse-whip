# Art contract — measurable acceptance for sprite art

**Status: CONFIRMED method (user, 2026-10-12); tolerances PROPOSED, calibrated from one real implementation.** This document turns "fully animated, same character in every frame" (D18) into rules a machine can check and an independent reviewer can confirm. It is authoritative for *how sprite art is measured and accepted*. [ASSET_BRIEFS.md](ASSET_BRIEFS.md) stays authoritative for inventory, canvases, pivots and durations; [contract/art_contract.json](../contract/art_contract.json) is the machine-readable form of both, and `tools/contract-check.mjs` fails if it disagrees with the briefs.

Production of art is **fully autonomous** (D21): no human approves frames. The protection that replaces the human is this contract, the reference tools in [tools/](../tools/README.md), and an **independent reviewer** (§9) who did not make the art.

## 0. Why this exists — defects a real build shipped

A complete implementation of this specification ([LESSONS.md](LESSONS.md)) passed its own audits and still shipped every defect below. A human found each one by eye, and fixing them took five rounds. Each rule in this contract names the defect it prevents.

| ID | Shipped defect | Why the checks of the day missed it | Rule(s) |
|---|---|---|---|
| DA-1 | Hero changed size between actions; walk −14%, crouch **taller** than standing | Each clip generated as its own sheet at its own scale; only a target height existed | A-05, A-06, A-12 |
| DA-2 | Standing idle was a **waist-up torso** stretched to full height | Every check measured bounding boxes or area; the torso was exactly 224 px tall | A-07, A-08, §9 blind description |
| DA-3 | Crouch read as **shrinking**, not bending; standing up read as growing | Nothing said rigid body parts keep their size when the pose changes (head 38 → 31 px) | A-08 |
| DA-4 | Whip not held; coil as big as the hero | Only the whip's reach was specified | W-01…W-06 |
| DA-5 | Whip snapped between unrelated shapes; impact effects popped | No rule for how a motion progresses or how an effect grows and fades | A-11, W-05, V-03 |
| DA-6 | Boss had the same torso defect | The anatomy check had been relaxed for "robe" characters | A-07 applies to every actor with declared legs |
| DA-7 | Debris specks, art cut off at the canvas edge, a blank damage flash | The cut-out (chroma key) step had no rules | A-01…A-04, G-04, G-05 |
| DA-8 | Within one clip, frames at different sizes (land: 239/209/169/260 px, median exactly on target) | The audit compared a clip's median, not each frame | A-05, A-06 per frame |

The lesson their own audit wrote down is the controlling rule here: **a check that has never failed proves nothing** (§10), and **numbers alone cannot approve art** (§9).

## 1. Terms and measurement

All measurements are on the delivered frame PNG, in source pixels, before atlas packing.

- **Ink**: pixels with alpha ≥ 40 (of 255).
- **Figure**: the largest 8-connected ink component, plus every other component within 8 px of it (cloth, hair, coiled whip and similar near parts). Any other component is **debris** unless the clip declares it a *satellite* (a separate thrown object, an ash particle).
- **Height H**, **width W**: the figure's bounding box.
- **Size S** = √(figure ink area). S changes in proportion to scale but barely moves when a pose redistributes the same body. Height swings with the pose; S does not. Use S, not the bounding box, for "is this the same size of character".
- **Foot line**: the lowest figure row. **Pivot line**: the contract pivot's y.
- **Head width**: the widest figure row within the top 12% of H, measured only in frames whose pose class marks the head as the topmost feature (§3). Raised arms and a coiled whip occupy the top band in some poses; those frames skip the rule and §9 covers them.
- **Lower-body ratios** (anatomy proxies, from the shipped integrity gate):
  - *boot ratio* = mean row width over the bottom 8% of H ÷ widest row. A figure that tapers to feet reads low; one cut off at the waist reads high.
  - *leg dip* = narrowest row between 55% and 94% of H ÷ widest row. Legs and a gap between them read low.
- **Reference values**: an actor's nominal S, head width and ratios are **measured on its approved reference frames** (the style lock, ART_BIBLE §8–9) and written into the manifest. They are not invented in this document. The contract fixes the tolerances and the bands a reference must fall in.

## 2. Actor proportion sheet

| Actor | Alignment | Design height (standing class) | Crouch height | Head ÷ standing height | Has legs (A-07 applies) |
|---|---|---|---|---|---|
| hero | feet on pivot | 224 px (112 u) | 140 px (70 u) = 0.625 × | 0.14–0.20 (non-chibi, non-tiny) | yes |
| pursuer | feet on pivot | 112 px at the shoulder line in patrol | — | not checked (head hung low by design) | yes (four) |
| swooper | body centre on pivot | 170 px cruise envelope | — | — | no (flight) |
| ranged | base on pivot | 300 px (150 u, matches its 72×150 u contact body) | — | — | no (robe to ground) |
| boss | feet on pivot | 352 px (176 u) | — | helmet, checked as head | yes (plate legs under the shroud) |

The crouch value fixes a gap the first spec left open: crouch collision is 60 u against 104 u standing (0.577), and "well below the standing silhouette" is not measurable. 140 px is inside 0.60–0.65 and was validated by play.

## 3. Pose classes

Every frame of every character clip carries one pose class, given per clip in `art_contract.json` (and per frame where a clip changes class). The class selects the rules.

| Class | Used for | Height band (× design) | S band (× reference S) | Feet on pivot | Head rule | Lower body |
|---|---|---|---|---|---|---|
| `stand` | idle, turn neutral, hurt recoil | 0.97–1.03 | 0.92–1.08 | ±2 px | yes, ±5% | required |
| `stride` | walk, start/stop | 0.94–1.03 | 0.92–1.08 | ±2 px | yes, ±5% | required |
| `strike` | grounded attacks, wind-ups | 0.90–1.20 | 0.92–1.08 | ±2 px | skip (arm above head) | required |
| `crouch` | crouch idle, crouched attack | crouch height ±5% | 0.80–1.00 | ±2 px | yes, ±5% **of standing** | — |
| `transition` | crouch enter/exit, land, takeoff | crouch −5% … design +3% | 0.80–1.08 | ±2 px | yes, ±5% of standing | — |
| `air` | rise, apex, fall, air attack | 0.70–1.15 | 0.90–1.10 | lowest ink on pivot ±2 px | skip | — |
| `impact` | knockback, knockdown, get-up | 0.25–1.05 | 0.85–1.12 | ±2 px | skip | — |
| `collapse` | death up to the final settle | 0.15–1.05 | 0.70–1.12 | ±2 px | skip | — |
| `dissolve` | ash and settle frames at the end of a death | no band | no band | ±6 px | skip | — |
| `creature` | non-humanoid locomotion and poses | per clip `height_band` | 0.88–1.12 | per actor alignment | skip | per actor |

The head rule in `crouch` and `transition` compares against the **standing** head width. That is what makes "bend, don't shrink" (DA-3) a hard rule. A clip may override its height or size band in `art_contract.json` (for example the pursuer's rear-up tell, or folded wings that show less area), always with a note saying why. Loosening a band beyond what the pose needs is a contract amendment recorded in [DECISIONS.md](DECISIONS.md).

## 4. Per-frame rules (automated: `tools/audit-art.mjs`)

Each rule prints its ID on failure. A **DEFECT** blocks approval; a **FLAG** goes to the reviewer's list with the frame named.

| ID | Rule | Severity |
|---|---|---|
| A-01 | Frame exists, has the contract canvas size, is RGBA, and is not empty (some ink present) | DEFECT |
| A-02 | Real transparency: all four corner pixels have alpha 0; no pixel of the key colour remains (G-04) | DEFECT |
| A-03 | No figure ink within 2 px of the canvas edge (clipping), unless the clip declares `bleed` on that edge | DEFECT |
| A-04 | No debris: no ink component of 24 px or more outside the figure. Frames of class `dissolve` may carry loose ash particles | DEFECT |
| A-05 | Height in the frame's pose-class band | DEFECT |
| A-06 | S in the frame's pose-class band against the actor's reference S | DEFECT |
| A-07 | Lower body present in classes that require it: fails when boot ratio > 0.60 **and** leg dip > 0.50 | DEFECT |
| A-08 | Head width within ±5% of the actor's standing reference, where the head rule applies | DEFECT; a single isolated frame (hair swing) is a FLAG |
| A-09 | Foot line on the pivot line within the class tolerance; cloth pooling up to 6 px below is a FLAG | DEFECT |
| A-10 | Facing: the source faces right. Checked by the reviewer on the lineup sheet (no reliable automated test) | review |

## 5. Clip and cross-clip rules

| ID | Rule | Severity |
|---|---|---|
| A-11 | No pop: between adjacent frames of the same pose class, S changes by ≤ 6%; in steady classes (`stand`, `stride`, `crouch`, `creature`) height also changes by ≤ 12%. Transitions, impacts and collapses change height by design, so only their size is watched | FLAG (reviewer adjudicates against the onion-skin sheet) |
| A-12 | One character, one size: each clip's median S is within 6% of the actor's median S for the same pose class across all clips (clips with a declared size override, such as folded wings, are judged by their own band instead). Combined with A-06 (every frame against the reference), this catches both a whole sheet drawn at the wrong scale and single frames that stray (DA-1, DA-8) | DEFECT for `stand`, `stride`, `crouch`; FLAG for other classes |
| A-13 | Loop seam: in looping clips, last → first frame obeys A-11 | FLAG |
| A-14 | Frame count, per-frame durations and loop flag equal the contract | DEFECT |
| A-15 | Every gameplay state maps to an existing clip, and every clip is reachable from some state (GAMEPLAY_RULES §4 / §8). Checked in engine (VALIDATION V3) | DEFECT |

## 6. Whip layer (DA-4, DA-5)

Every attack body frame records a **hand socket** in source px. The whip frame with the same index must satisfy:

| ID | Rule | Severity |
|---|---|---|
| W-01 | Some whip ink lies within 3 px of the hand socket, and the grip's centre within 6 px of it | DEFECT |
| W-02 | Thickness: the thong is ≤ 10 px across within 40 px of the grip and ≤ 4 px across in its last 20 px | DEFECT |
| W-03 | Coiled frames (wind-up and rest): coil bounding box ≤ 0.55 × standing height (123 px) on both axes | DEFECT |
| W-04 | Reach: during the active frames (2–3), the tip is at least 336 px right of the pivot x (168 u) | DEFECT |
| W-05 | Progression: tip distance from the socket does not decrease over frames 0→3 and does not increase over frames 4→7 | DEFECT |
| W-06 | No blank whip frame while an attack plays | DEFECT |

## 7. Effects (DA-5, DA-7)

| ID | Rule | Severity |
|---|---|---|
| V-01 | No alpha on the canvas border ring (2 px): an effect never shows a rectangle edge | DEFECT |
| V-02 | The anchor stays put: the ink bounding box's centre (or bottom centre, for base-anchored effects) is within 4 px of the brief's anchor in every frame | DEFECT |
| V-03 | Size curve: for one-shot bursts, the larger side of the ink bounding box rises to one peak, then falls (one wobble of ≤ 10% allowed). In every effect it never exceeds the brief's `max_extent_px` | DEFECT |
| V-04 | Full-screen and screen-edge effects (vignettes, flashes, fades, the damage indicator) are **drawn in engine code**, never generated or chroma-keyed | DEFECT if delivered as art |

## 8. Generation and extraction requirements

The art method is AI-painted key frames under these rules (D22). The tools check the output, not the generator, so any image model may be used.

| ID | Requirement | Prevents |
|---|---|---|
| G-01 | Every generation request includes the approved identity reference image **and** a guide image: the contract canvas with the ground line, the pivot, and horizontal lines at the design and crouch heights. The prompt states "full body, top of head to soles of boots, feet on the ground line" | DA-2, DA-1 |
| G-02 | Generate key poses one at a time against the reference, then in-betweens using their neighbours as references. A whole-clip sheet is allowed only if every cell passes A-05…A-08 unedited | DA-1, DA-8 |
| G-03 | Normalise per frame: one uniform scale about the pivot, factor within 0.85–1.18. A frame that needs more than that is **regenerated**, never stretched. The factor is recorded in the manifest | DA-1 |
| G-04 | Key colour: magenta `#FF00FF` by default. The key colour must be at least 60° of hue away from every swatch the asset uses. Green keys are forbidden for enemies, whose palette contains Decay Green and Grave Phosphor | DA-7 |
| G-05 | Extract on a canvas large enough for the whole pose, then place it on the contract canvas. Debris removal is logged per frame | DA-7 |
| G-06 | Keep every rejected and pre-fix frame, in an archive or a `rejected/` folder, so a check can be shown failing on it (§10) | — |

## 9. Visual review — the independent reviewer gate

Numbers are tripwires; looking is the acceptance. Because no human approves art (D21), a **reviewer that did not make the art** approves it. The protocol is [prompts/ART_REVIEW.md](../prompts/ART_REVIEW.md):

- **Who.** A fresh model session or agent. It receives only the review pack below, this contract, ART_BIBLE, and the style-lock references. It does not receive the builder's verdicts, audit summaries or reasoning. The builder may never approve its own art.
- **Blind description first.** For each actor's lineup sheet, and for each clip strip, the reviewer first writes a plain description of what it sees ("a man in a long coat, full body, standing", "a waist-up figure with no legs"). Only then does it read the clip's intended pose and give a verdict. The torso defect (DA-2) survived three audits and would not have survived one honest description.
- **What it judges.** Identity stays the same across frames; the full body is present; size is consistent; bending is not shrinking; the whip is held in the fist; facing; motion reads at playback speed (on the onion-skin sheets); every FLAG from the audit; and anything the automated rules cannot see.
- **Outcome.** A PASS or FAIL per clip, with the failing frames named. Any FAIL blocks release. After a fix, a **new** reviewer instance re-reviews, never the same one.

**Review pack** (built by `tools/review-pack.mjs`, plus engine captures):

1. `lineup_<actor>.png`: one frame of every clip, side by side on a shared ground line, with guide lines at the design and crouch heights. This single sheet would have shown DA-1, DA-2, DA-3 and DA-6 at a glance.
2. `strip_<clip>.png`: every frame at native resolution, with the pivot cross, the canvas border and frame numbers.
3. `onion_<clip>.png`: each pair of adjacent frames overlaid in two tints, so motion continuity can be judged from stills.
4. `composite_<attack>.png`: body and whip together, with the hand socket marked.
5. `audit.json` / `audit.md`: every DEFECT and FLAG.
6. Engine captures (implementer's harness): standing, walking, crouching, mid-strike, mid-air and the boss, at actual phone display size.

## 10. Checks must be proven able to fail

A check is accepted only once it has been seen failing on the defect it targets.

- `tools/selftest.mjs` builds a synthetic actor, generates a correct clip set plus one broken variant per defect class (torso-only, shrunken crouch, per-frame size drift, debris, canvas clipping, opaque background, leftover key colour, floating feet, detached whip, oversized coil, whip reach short, effect with a rectangle edge, popping effect). It asserts that the audit passes the correct set and reports the expected rule ID on each broken one. It takes about 40 s and must pass before any art is audited.
- The self-test also documents a limit: a torso whose hands hang below the belt looks like two feet to the lower-body proxy (A-07). The head rule (A-08) still catches it, which is why no single anatomy proxy is trusted alone, and why the blind description in §9 is required.
- When production finds a new defect class, add a fixture for it first and watch the audit fail on it; only then fix the art. Re-run the audit on the archived pre-fix frames (G-06): it must fail there and pass on the fix.

## 11. Allowed derivations (D23)

Shortcuts are allowed, labelled, and checked like any other frame:

- **Reversed clips** (crouch exit = crouch enter reversed; get-up = knockdown reversed).
- **Scripted fallback**: when image generation fails, a frame or clip may be derived by script from approved frames (for example a breathing idle built from a neutral stand).
- **Mirrored or reused frames** across clips.

Each derived clip records `derivation: {kind, source, method, reason}` in its manifest. It passes every rule in §4–§7 and is listed separately in the review pack, where the reviewer must confirm it reads as the intended action (a reversed fall must read as getting up). Scripted fallbacks are listed in the release handoff as known quality debt.

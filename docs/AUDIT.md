# Gap / contradiction audit

Date: 2026-10-08. Scope: documents only — `SPEC.md`, `docs/DECISIONS.md`, `docs/ANIMATION_SPEC.md`, `docs/ASSET_SPEC.md`, `docs/ART_DIRECTION.md`, `docs/TECHNICAL_CONSTRAINTS.md`, `docs/VALIDATION.md`, `docs/WORK_PACKAGES.md`, `templates/asset-manifest.example.json`. No game, engine project, or asset exists or was created for this audit.

Method: every shared number was traced to its single authoritative source and re-derived by hand; the manifest example was parsed as JSON; all relative Markdown links were resolved programmatically. Only checks actually performed are claimed below. Runtime behavior (import, playback, touch, performance) remains **NOT-TESTED** per [VALIDATION.md](VALIDATION.md).

Severity key: **blocking-for-production** (must be resolved before building/shipping), **blocking-for-package** (blocks a named work package in [WORK_PACKAGES.md](WORK_PACKAGES.md)), **note** (recorded; proceeded on a marked proposal or harmless).

## A. Verified consistent (arithmetic shown)

**A1. Jump envelope — consistent.** SPEC §4 proposes initial jump velocity −640 u/s against gravity 1600 u/s², top speed 240 u/s.

- Time to apex = 640 / 1600 = **0.4 s** ✓ (SPEC: 0.4 s)
- Rise = 640² / (2 × 1600) = 409600 / 3200 = **128 u** ✓ (SPEC: 128 u)
- Same-height air time = 2 × 0.4 = 0.8 s; travel = 240 × 0.8 = **192 u** ✓ (SPEC: 192 u)
- SPEC's conservative stage limits sit inside the envelope: mandatory gap ≤ 112 u leaves 192 − 112 = **80 u headroom** (0.33 s at full speed); mandatory up-step ≤ 64 u is exactly **50% of the 128 u rise**; minimum landing platform 128 u = exactly 2 terrain modules on the proposed 64 u grid (D11). No contradiction.

**A2. Whip timeline — consistent across three documents.** SPEC §5: 150 ms anticipation + 100 ms active + 250 ms recovery = 500 ms. ASSET_SPEC §3 frame durations [75, 75, 50, 50, 62.5, 62.5, 62.5, 62.5]: frames 0–1 sum to **150** (anticipation), frames 2–3 to **100** (active), frames 4–7 to **250** (recovery), total **500 ms**. Active interval is therefore [150, 250) ms. The manifest example (`templates/asset-manifest.example.json`) parses as JSON, carries the identical duration list, declares `total_ms: 500` and `active_interval_ms: [150, 250]` — all three sources agree.

**A3. Crouch collision vs standing body — consistent.** ASSET_SPEC §2: standing body 40×104 centered (0, −52) → spans y [−104, 0]. ANIMATION_SPEC: crouch body 40×60 centered (0, −30) → spans y [−60, 0]. Widths identical (40 u); **foot origin y = 0 in both** — the crouch lowers only the top edge, exactly as ANIMATION_SPEC requires ("preserving the foot origin", "no shrinking the artwork or moving the origin downward"). The crouched whip band (SPEC §5: y −48..−20) lies inside the crouch span [−60, 0]; the standing band (y −82..−46) lies inside [−104, 0]. Note only: the crouched band is not a pure translation of the standing band (top edge 34 u lower, bottom edge 26 u lower; heights 36 u vs 28 u) — SPEC defines it as its own interval, so this is a definition, not a discrepancy.

**A4. Canvas / pivot / density arithmetic — consistent.** ASSET_SPEC §1: 512×512 source px at 2 px per game unit → 256×256 u canvas; hero height 112 u = 224 source px ✓. Whip canvas 768×512 with foot-origin anchor at source x 256 leaves (768 − 256) / 2 = **256 u of room to the right** of the origin; the SPEC hitbox reaches x +168 < 256 ✓ (left-facing mirrors around the same origin). Landing platform minimum (128 u, A1) equals 2 terrain modules ✓.

**A5. Knockdown cycle fits inside i-frames — consistent.** ANIMATION_SPEC clips: knockdown 6 × 60 ms = 360 ms; get_up 6 × 75 ms = 450 ms; full sequence 810 ms. SPEC §5 invulnerability is 1 s = 1000 ms ≥ 810 ms, so the hunter cannot be re-hit during get-up. [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) relies on this.

**A6. Links and review-record claims — re-verified.** All 18 relative Markdown links in the repo resolve (0 broken), confirming the 2026-10-07 review record's link claim. All numeric claims in `REVIEW_RECORD.md` (frame totals 113 + 24 = 137; 500 ms sum; active interval [150, 250)) re-derived and confirmed above.

## B. Contradictions, tensions, and gaps

**B1. Identity vs distribution rights — RESOLVED by user decision (2026-10-08).** *Was: blocking-for-production.*
As handed off, D02 confirmed "Simon Belmont in Castlevania's world" and D12 forbade substituting an original hunter, while D15 confirmed publication to a new public repository with a public web build and a later Android APK. A named Konami character and world cannot be licensed by this project, so no public build could ever ship under D02/D12 — the contradiction was total and could only be resolved by the user.
**Resolution (user, 2026-10-08):** "Switch to an original hunter (shippable)." The protagonist and world are now an **original hunter in an original gothic world**. Castlevania remains a design *reference* for tone and mechanics only — whip-led combat, restrained jump, dark gothic horror, no visible pixels (D03–D06 substance unchanged). [DECISIONS.md](DECISIONS.md) has been amended for D02/D12 accordingly.
*Follow-up edits required (enumerated when this audit was written; **completed by the B1 wording pass, 2026-10-08** — see REVIEW_RECORD "B1 wording consistency"; each file received its own consistency check in that pass):*
- `SPEC.md` §1 (two identity sentences) and §2 (signature moment naming Simon).
- `README.md` line 3 ("starring Simon Belmont…").
- `AGENTS.md` "Preserve confirmed user intent" bullet.
- `docs/ART_DIRECTION.md` "Visual grammar" paragraph (Simon/costume wording → original hunter design language).
- `docs/ASSET_SPEC.md` §2 and §3 ("shrinking Simon", "Simon's frame size").
- `prompts/ASSET_GENERATION.md` (identity paragraph + "approved Simon design reference" example) and `prompts/NEXT_LLM.md` (protagonist sentence).
- `docs/WORK_PACKAGES.md` P0 row (D12 reframed: original hunter design reference is now a P2 deliverable; D13 is resolved).
- `docs/REVIEW_RECORD.md` "Open at publication" paragraph is a dated 2026-10-07 record and is **not** rewritten; it is superseded by the 2026-10-08 entry appended in this pass.

**B2. Texture budget: hero frames alone exceed the slice budget — RECONCILED ON PAPER in P3 (2026-10-08); amendment RATIFIED 2026-10-08 under user-delegated judgement; unresolved in fact until measured.** *Was: blocking-for-package (P3, P5); remains blocking-for-production if measurement (V2/V8) later breaks the amended model.*
Recomputed: one 512×512 RGBA8 body frame = 1 MiB → 113 frames = **113 MiB**; one 768×512 whip frame = 1.5 MiB → 24 frames = **36 MiB**; hero total **149 MiB** against the ≤128 MiB whole-slice resident budget in [TECHNICAL_CONSTRAINTS.md](TECHNICAL_CONSTRAINTS.md) — **21 MiB (16.4%) over before any enemy, boss, terrain, UI, or background art**. Two aggravating factors: (a) the 128 MiB figure is stated "before mipmaps/overhead" — a 2048×2048 RGBA8 page is 16 MiB raw, ≈21.3 MiB with a full mip chain, so the budget buys at most six fully-mipmapped pages; (b) trimming transparent space will shrink the hero substantially, but no packed-occupancy number exists anywhere yet. ANIMATION_SPEC already flags this and forbids solving it by cutting action coverage.
**P3 reconciliation ([TEXTURE_BUDGET.md](TEXTURE_BUDGET.md)):** the full slice inventory (278.97 MiB untrimmed) under stated trim/packing assumptions needs 8 pages all-resident — 170.7 MiB mipmapped, 128.0 MiB without mips — so **the budget does not hold as written**. TEXTURE_BUDGET proposes the smallest contract change (no mip chains on slice art + peak-concurrency residency ≤7 pages, swap at the boss gate → 112.0 MiB peak, 16 MiB headroom), marked PROPOSED for P6/user ratification; neither ASSET_SPEC nor TECHNICAL_CONSTRAINTS numbers were edited. Sensitivity: trim factors 10 points worse break even the amended model (144 MiB), so the verdict must be re-measured on the first real packed art (VALIDATION V2/V8) before production proceeds.

**B3. D09 stomp/contact rule — RESOLVED 2026-10-08.** The user confirmed the baseline: no stomp kills; contact (including landing on an enemy) hurts; the whip is the only weapon. P1's assumption stands; no revision needed. *Was: note for now; blocking-for-package only if reversed after P1.*
DECISIONS D09 (PROPOSED, "Not answered by user") and SPEC §5 agree on the baseline — contact, including landing on an enemy, hurts the hunter; no stomp kills — but the user has never confirmed it. [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) is written against this baseline and marks it at every contact rule. If the user later wants stomp kills, the pursuer/swooper briefs, the enemy-contact rules, and VALIDATION V7's "reachable without … stomp kills" question all change. No other package depends on D09.

**B4. D14 device matrix — RESOLVED by user decision (2026-10-08), with P5 follow-ups.** *Was: blocking-for-package (P5).*
**Resolution (user, 2026-10-08):** the target device is **iPhone 17, browser play in iOS Safari**. Recorded in [DECISIONS.md](DECISIONS.md). Consequences, all deferred to P5 (TECHNICAL_CONSTRAINTS.md is **not** rewritten in this pass):
- The proposed performance anchor "an agreed mid-range Android phone" (60 fps, 95th-percentile frame ≤20 ms, ≤30 MiB cold payload, ≤12 s load) is superseded: P5 must re-derive and re-anchor the device/browser matrix and every performance hypothesis on iPhone 17 / iOS Safari. Those numbers are currently unanchored hypotheses, not targets anyone has validated.
- iOS Safari is a **must-support** target, not an exploratory check; the D14 either/or is closed.
- The single-threaded web-export baseline (D10, PROPOSED) aligns well with Safari's constraints; P5 should still verify the pinned Godot version's WebGL2/WASM behavior on the actual device.
- Android APK remains DEFERRED (D16) and is unaffected by this resolution.
**P5 follow-up delivered (2026-10-08):** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) pins Godot 4.7.2-stable (verified at the official godotengine.org download archive on the check date), anchors the device/browser matrix and performance protocol on iPhone 17 / iOS Safari, and keeps the APK section DEFERRED with prerequisites. All performance targets remain PROPOSED and NOT-TESTED; the stale "mid-range Android phone" anchor text in TECHNICAL_CONSTRAINTS.md is superseded by TECHNICAL_SPEC.md and left unedited as history.

**B5. D13 horror intensity — RESOLVED by user decision (2026-10-08).** *Was: blocking-for-package (P2).*
**Resolution (user, 2026-10-08):** the proposed treatment is confirmed — dread, decay, silhouettes; **no explicit gore**. Recorded in [DECISIONS.md](DECISIONS.md). P2 (art bible) may now fix content limits against this line.

**B6. Knockback magnitude is nowhere specified — gap, filled by P1 proposal.** *Blocking-for-package (P4).*
SPEC §5 and ANIMATION_SPEC require animated knockback and give the clip length (4 × 75 ms = 300 ms) but no displacement or velocity in any document. Stage design (P4) cannot certify that a knockback on a minimum 128 u platform won't force a pit fall without a number. [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) proposes 160 u/s for 300 ms ≈ 48 u — less than the 64 u half-width of a minimum platform — as a **PROPOSED** value pending greybox playtest (VALIDATION V6).

**B7. Which boss hits are "heavy" is unspecified — gap, filled by P1 proposal.** *Note.*
SPEC §5 distinguishes ordinary damage (knockback) from "heavy boss hits" (knockdown + get-up), but never says which of the boss's two attacks (SPEC §3: one close-range, one ground hazard) is heavy. [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) proposes: close-range strike = heavy (knockdown); ground hazard = ordinary (knockback). All enemy hits cost 1 health either way (SPEC §5 prices only "ordinary contact" at one unit; the heavy/ordinary distinction is the *reaction*, and no document prices any hit above one unit).

**B8. Swooper hit-points ambiguous — gap, filled by P1 proposal.** *Note.*
SPEC §5: "one hit to kill basic enemies, two for the ranged enemy, and eight for the boss." The three archetypes (SPEC §3) are pursuer, swooper, ranged; §5 names only "basic" and "ranged". [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) reads "basic" as pursuer + swooper (1 HP each), the only reading that prices all three archetypes. Marked PROPOSED pending user confirmation alongside D07.

**B9. Respawn before the first checkpoint is undefined — gap, filled by P1.** *Note.*
SPEC §5 defines checkpoint restart (health + encounter state restored) but the stage has one checkpoint mid-stage (SPEC §3 beats) and says nothing about dying before reaching it. [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) defines the stage-start spawn as the default respawn until the checkpoint is touched.

**B10. Enemy inside the whip dead zone — gap, filled by P1.** *Note.*
The whip's active region starts at x +40; no document states what resolves an enemy that closes inside 40 u. P1 rule (proposal): contact damage + knockback separates hunter and attacker, and the 1 s i-frames prevent an instant re-trigger, so the dead zone can never soft-lock a fight.

**B11. Stale identity wording outside DECISIONS.md — RESOLVED by the B1 wording pass (2026-10-08).**
Separate from B1's resolution: `AGENTS.md`, `README.md`, `SPEC.md`, `docs/ART_DIRECTION.md`, `docs/ASSET_SPEC.md`, and both files under `prompts/` previously instructed future contributors to preserve "Simon Belmont in Castlevania's world" (enumerated in B1). That pass is now made: a grep over the seven files finds "Simon" only in `prompts/NEXT_LLM.md`, describing the superseded interview-era identity. All seven files now present the original-hunter identity, with Castlevania as design reference for tone/mechanics only.

**B12. Transfer size vs resident size — note, no contradiction.**
TECHNICAL_CONSTRAINTS pairs a ≤30 MiB *transferred* cold-cache payload with the ≤128 MiB *resident* RGBA budget. These measure different things (compressed download vs decoded GPU memory) and do not conflict; P5 should keep both and state the decompression assumption explicitly. Recorded so a future reader doesn't "fix" either number.

## C. Open items left for the user

1. **D09** — RESOLVED 2026-10-08: user confirmed the no-stomp baseline ("no stomp. whip is the weapon"). See DECISIONS.md Amendments.
2. **D07–D11** — CONFIRMED AS BASELINES 2026-10-08 under user-delegated judgement ("use your judgement"); derived values in [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) and later packages are tunable baselines, revisable on greybox evidence. See DECISIONS.md Amendments (R3).
3. B2 (texture residency) and the B4 follow-ups (iPhone 17 performance matrix) were P3/P5 specification work and are now delivered ([TEXTURE_BUDGET.md](TEXTURE_BUDGET.md), [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)). The texture amendment was **ratified 2026-10-08** under user-delegated judgement (see DECISIONS.md Amendments, R1); it still needs measured validation (V2/V8) once real art exists, and no production art or build should start without the separate implementation assignment.

# Readiness review — Package P6

Date: 2026-10-08. Scope: documents only. This review re-checks every shared value across the full document set (SPEC.md, [DECISIONS.md](DECISIONS.md), [ANIMATION_SPEC.md](ANIMATION_SPEC.md), [ASSET_SPEC.md](ASSET_SPEC.md), [ART_DIRECTION.md](ART_DIRECTION.md), [TECHNICAL_CONSTRAINTS.md](TECHNICAL_CONSTRAINTS.md), [VALIDATION.md](VALIDATION.md), [WORK_PACKAGES.md](WORK_PACKAGES.md), [AUDIT.md](AUDIT.md), [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md), [STAGE_DESIGN.md](STAGE_DESIGN.md), [ART_BIBLE.md](ART_BIBLE.md), [ASSET_BRIEFS.md](ASSET_BRIEFS.md), [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md), [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md), `prompts/`, `templates/`), applies the "definition of specification-ready" from [WORK_PACKAGES.md](WORK_PACKAGES.md), and restates the [VALIDATION.md](VALIDATION.md) acceptance matrix. No game, engine project, art, or build exists; nothing in this review is runtime evidence. Per [AGENTS.md](../AGENTS.md), production requires a separate explicit implementation assignment — **this review does not grant it.**

Method: all shared numbers re-derived by hand and, where tabulated, recomputed programmatically; the manifest example re-parsed as JSON; every relative Markdown link re-resolved (60 links, 0 broken); greps for stale identity wording, engine pins, and the open D09. Only checks actually performed are claimed (§6). Two genuine inconsistencies in the newer package docs were found and fixed in this pass (SW-1, SW-2); nothing in `DECISIONS.md` was edited and no confirmed requirement was rewritten.

## 1. Contradiction sweep

Verdicts: **AGREE** (values match across sources) / **DISAGREE** (with disposition). "PQ" = the P1–P5 package docs.

### 1.1 Movement, combat, and collision values

| # | Shared value | Sources | Verdict |
|---|---|---|---|
| 1 | Jump: 240 u/s, gravity 1600 u/s², v₀ −640 u/s → apex 0.4 s, rise 128 u, same-height travel 192 u | SPEC §4; GAMEPLAY_RULES §1; AUDIT A1 (re-derived: 640/1600 = 0.4; 640²/3200 = 128; 240 × 0.8 = 192) | AGREE |
| 2 | Conservative stage limits: gap ≤ 112 u, up-step ≤ 64 u, landing ≥ 128 u | SPEC §4; STAGE_DESIGN §1/§4 (all 20 mandatory elements tabulated; none exceeds a limit; six exactly at one; every gap is 64 u) | AGREE |
| 3 | Whip timeline: 150 + 100 + 250 = 500 ms; active [150, 250) ms | SPEC §5; ASSET_SPEC §3; GAMEPLAY_RULES §1/§4; ASSET_BRIEFS §2–3; manifest example (`total_ms: 500`, `active_interval_ms: [150, 250]`, durations sum 500 — re-parsed) | AGREE |
| 4 | Attack frame durations [75,75,50,50,62.5,62.5,62.5,62.5] | ASSET_SPEC §3; ASSET_BRIEFS §2–3 (all three attacks); manifest example | AGREE |
| 5 | Whip active region: x +40..+168; standing y −82..−46; crouched y −48..−20 (left mirrors x) | SPEC §5; GAMEPLAY_RULES §1/§4; ASSET_BRIEFS §2–3; ART_BIBLE §3 (168 u full extension), §8 Brief 2 | AGREE |
| 6 | Health 5; every hit costs 1 (ordinary and heavy alike) | SPEC §5; GAMEPLAY_RULES §1/§5; AUDIT B7 | AGREE |
| 7 | Enemy HP: basic 1, ranged 2, boss 8 (swooper = basic) | SPEC §5; GAMEPLAY_RULES §1/§8 (B8 reading); STAGE_DESIGN §5 (1/1/2/8); ASSET_BRIEFS §4–7 | AGREE |
| 8 | Invulnerability 1 s ⊇ knockdown 360 ms + get_up 450 ms = 810 ms | SPEC §5; ANIMATION_SPEC (6 × 60, 6 × 75); GAMEPLAY_RULES §4–5; ASSET_BRIEFS §2; AUDIT A5 | AGREE |
| 9 | Knockback 160 u/s × 300 ms ≈ 48 u < 64 u (half the 128 u minimum landing) | GAMEPLAY_RULES §5 [P1 proposal]; AUDIT B6; STAGE_DESIGN §4 | AGREE |
| 10 | Collision bodies: standing 40×104 @ (0, −52) → y [−104, 0]; crouch 40×60 @ (0, −30) → y [−60, 0]; foot origin y = 0 both | ASSET_SPEC §2; ANIMATION_SPEC; GAMEPLAY_RULES §1/§6; ASSET_BRIEFS §2; AUDIT A3 | AGREE |
| 11 | Boss mapping: close strike = heavy → knockdown; ground hazard = ordinary → knockback; hazard ≤ 46 u tall, 160 u zone | SPEC §3/§5; GAMEPLAY_RULES §5/§8.4; ASSET_BRIEFS §7/§11; AUDIT B7 | AGREE |
| 12 | Swooper windows: patrol 175–190 u; dive band 46–82 u ≡ standing whip band; jump-whip band at apex 128 + 46..82 = 174–210 u contains patrol altitude | GAMEPLAY_RULES §8.2 (re-derived); STAGE_DESIGN §3/§5; ASSET_BRIEFS §5 | AGREE |

### 1.2 Scale, canvases, and frame counts

| # | Shared value | Sources | Verdict |
|---|---|---|---|
| 13 | Logical view 1280×720 u; terrain module 64 u; density 2 px/u; import scale 0.5; hero height 112 u = 224 px | ASSET_SPEC §1; SPEC §6; GAMEPLAY_RULES §1; ART_BIBLE header; ASSET_GENERATION master prompt; D11 (PROPOSED) | AGREE |
| 14 | Hero body canvas 512×512, foot pivot (256, 448); whip canvas 768×512, anchor (256, 448); whip right room (768 − 256)/2 = 256 u > 168 u reach | ASSET_SPEC §1–2; ASSET_BRIEFS §2–3; ASSET_GENERATION hero example; manifest example; AUDIT A4 | AGREE |
| 15 | Hero frames: 113 body + 24 whip = 137 | ANIMATION_SPEC table (21 body clips re-summed to 113; whip 3 × 8); ASSET_BRIEFS §2–3 (re-summed clip by clip); REVIEW_RECORD 2026-10-07; AUDIT A6 | AGREE |
| 16 | Enemy/boss frames (proposed in P3): pursuer 46, swooper 36, ranged 31 + projectile 3, boss 70; clip durations sum to each stated total and to the GAMEPLAY_RULES tells (alert 300, wind-up 350, telegraph 600, aim 900 / fire 200 / recover 700, boss 700 / 1100 / 1200 + 400 / hurt 200 ms) | ASSET_BRIEFS §4–7 (re-summed); GAMEPLAY_RULES §8; TEXTURE_BUDGET §3 (same counts) | AGREE |
| 17 | Terrain kit: 14 tiles at 128×128 (3 caps, 2 sides, 1 fill, 3 bottom, 2 inner, 3 platform) | ASSET_SPEC §4 kit list; ASSET_BRIEFS §8; TEXTURE_BUDGET §3 | AGREE |
| 18 | Backgrounds 4 (sky 1024×1024, distant 2048×384, midground 2048×768, foreground 2048×256); stage props 4 (effigy, checkpoint ×2 frames, gate, exit) | ASSET_BRIEFS §9; TEXTURE_BUDGET §3 (opaque 3,407,872 px = 13.00 MiB; foreground 524,288 px = 2.00 MiB; props 258,048 px — recomputed) | AGREE |
| 19 | VFX: 6 clips; itemized 2,097,152 px = 8.00 MiB | ASSET_BRIEFS §11; TEXTURE_BUDGET §3 (recomputed) | AGREE |
| 20 | UI inventory count | ASSET_BRIEFS §10 table enumerates **13 asset IDs / 19 frames** (six buttons × 2 states); TEXTURE_BUDGET §3's UI pixels (286,720 = 1.09 MiB) are computed from those 19 frames | **DISAGREE → FIXED (SW-1)** |

### 1.3 Budgets, stage, engine, devices, decisions

| # | Shared value | Sources | Verdict |
|---|---|---|---|
| 21 | Slice textures: 73,129,984 px = 278.97 MiB untrimmed → 26,917,683 px = 102.68 MiB trimmed (stated trim factors, 0.85 packing) | TEXTURE_BUDGET §3; ANIMATION_SPEC (hero 113 + 36 = 149 MiB untrimmed); AUDIT B2 — recomputed exactly in this pass | AGREE |
| 22 | Page math: 2048² page = 16.00 MiB raw, 21.33 MiB mipmapped; 128 MiB = 8 raw / 6 mipmapped pages | TEXTURE_BUDGET §2; TECHNICAL_CONSTRAINTS | AGREE |
| 23 | Residency readings: all-resident 8 pages = 128.0 no-mips / 170.7 mipmapped (over by 42.7); boss-arena peak 7 = 112.0 / 149.3; mixed-beat peak 6 = 96.0 / 128.0; sensitivity (+10 trim points) = 9 pages / 144 MiB | TEXTURE_BUDGET §4/§6 — all four recomputed in this pass | AGREE |
| 24 | Transfer targets: ≤ 30 MiB cold payload, ≤ 12 s at 20 Mbps / 50 ms RTT (30 MiB ÷ 12 s = 20 Mbps — internally consistent) | TECHNICAL_CONSTRAINTS; TECHNICAL_SPEC §5; AUDIT B12 | AGREE |
| 25 | Stage: 104 modules = x 0–6656; checkpoint module 64; boss gate 87; arena modules 88–101 (896 u); boss spawn 97; exit 102–103; pure traversal 6656/240 ≈ 27.7 s | STAGE_DESIGN §2–3/§6 (module arithmetic re-checked); TEXTURE_BUDGET §4 (gate as page-swap point) | AGREE |
| 26 | Engine pin: Godot **4.7.2-stable**, GDScript (not .NET), Compatibility renderer, single-threaded web export | TECHNICAL_SPEC §1/§3/§6; D10 (PROPOSED — the pin is delivered as the proposal D10 calls for; ledger unchanged) | AGREE |
| 27 | Performance anchor: iPhone 17 / iOS Safari, must-support | DECISIONS D14 (CONFIRMED 2026-10-08); TECHNICAL_SPEC §4 (M1) / §5 | **DISAGREE in one source → SW-3** |
| 28 | Decision statuses: CONFIRMED D01, D03–D06, D13, D14, D15, D18; SUPERSEDED D02, D12; PROPOSED D07–D11, D17, D19; DEFERRED D16; unanswered D09 | DECISIONS.md + 2026-10-08 amendments; SPEC §1; GAMEPLAY_RULES header; AUDIT B1/B3–B5 | AGREE |

### 1.4 Disagreements and notes

- **SW-1 — UI count (FIXED in this pass).** [ASSET_BRIEFS.md](ASSET_BRIEFS.md) §10 stated "18 assets", but its own table enumerates 13 asset IDs / 19 frames, and [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md)'s UI pixel total is computed from the 19 frames. §10 now reads "13 assets, 19 frames". The P3 entry in [REVIEW_RECORD.md](REVIEW_RECORD.md) repeats the old "18 UI assets" figure; it is a dated record, left unedited per this repo's convention and superseded by this entry.
- **SW-2 — Stage lane vs safe zone (FIXED in this pass).** [STAGE_DESIGN.md](STAGE_DESIGN.md) §5 said R1's "lane covers ground modules 66–78", overlapping §6's guarantee that the checkpoint apron (modules 63–66) is a safe zone no projectile lane reaches. §3 already establishes that from the platform the shots pass 198–223 u above the ground route and cannot hit a ground hunter; the §5 cell now says exactly that. §§3/6 unchanged.
- **SW-3 — Performance/device anchor (DISAGREE in text; resolved by documented supersession; no edit).** [TECHNICAL_CONSTRAINTS.md](TECHNICAL_CONSTRAINTS.md) still says "an agreed mid-range Android phone", and [VALIDATION.md](VALIDATION.md) V5 still says "agreed Android hardware". Both are superseded: D14 (user-confirmed 2026-10-08) names iPhone 17 / iOS Safari, [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §4–5 re-anchors the matrix (M1) and the V5 protocol there, and AUDIT B4 records the supersession. The two files are retained as history by deliberate choice; the operative targets are TECHNICAL_SPEC §5's — still PROPOSED and NOT-TESTED. Whoever runs the implementation assignment should either update VALIDATION.md's V5 wording or cite TECHNICAL_SPEC §4 as the anchor in every V5 record.
- **Note (AGREE, conservative reading).** GAMEPLAY_RULES §8.3's "cycle 900 + 700 = 1600 ms" excludes ASSET_BRIEFS §6's 200 ms `ranged_fire` clip, so the full cycle is 1800 ms and the derived 384 u unopposed advance is a lower bound, not an overpromise. No conflict; no edit.
- **Note (AGREE, distinct quantities).** The pursuer's 52 u figure ([ASSET_BRIEFS.md](ASSET_BRIEFS.md) §4, [P3] collision body) vs ~56 u shoulder (ART_BIBLE §4, visual) is the collision-vs-silhouette distinction [ASSET_SPEC.md](ASSET_SPEC.md) §2 mandates; GAMEPLAY_RULES §8.1's jump-clearance math uses the larger, conservative number.

**Sweep result: 25 AGREE, 3 DISAGREE — two fixed in the package docs (SW-1, SW-2), one resolved by recorded supersession without editing history (SW-3).** No disagreement touches a user-confirmed requirement, and none required user authority to fix.

## 2. "Definition of specification-ready" checklist

From [WORK_PACKAGES.md](WORK_PACKAGES.md). PASS here means the document set supports the act on paper; it is not evidence about any build, art, or device (that is §3).

| # | A reviewer can… | Verdict | Evidence |
|---|---|---|---|
| 1 | Explain the entire first minute | **PASS** | [STAGE_DESIGN.md](STAGE_DESIGN.md) §7 maps SPEC §3's five first-minute lessons, in order, to modules 0–19 and the module-34 pit, each with its failure cost; §3 (B1) gives the geometry, including the recoverable-gap floor and the two 64 u recovery steps |
| 2 | Enumerate all required slice assets | **PASS** (after SW-1) | [ASSET_BRIEFS.md](ASSET_BRIEFS.md) §§2–12 lists every asset ID with canvas, pivot, frames, durations, sockets, collision reference, and dependencies; totals reconcile in [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) §3 (hero 113 + 24; pursuer 46; swooper 36; ranged 31 + 3; boss 70; terrain 14; backgrounds 4; props 4; UI 13/19; VFX 6; audio as deferred ID inventory) |
| 3 | Distinguish rendering from collision | **PASS** | [ASSET_SPEC.md](ASSET_SPEC.md) §2 ("gameplay geometry, not the visible sprite silhouette"); [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §1 collision table; every ASSET_BRIEFS asset carries a `collision_reference` and art "never defines collision"; [STAGE_DESIGN.md](STAGE_DESIGN.md) §4 keeps walkable lines on module boundaries |
| 4 | Derive attack timing without inspecting art | **PASS** | SPEC §5 states 150/100/250 ms and the active region numerically; [ASSET_SPEC.md](ASSET_SPEC.md) §3 gives per-frame durations; `templates/asset-manifest.example.json` carries `total_ms`, `active_interval_ms`, and per-frame `duration_ms`; GAMEPLAY_RULES §2/§5 derive windows, hit IDs, and interruption purely from these numbers |
| 5 | Identify exact target devices | **PASS** (as specified; untested) | [DECISIONS.md](DECISIONS.md) D14 (iPhone 17 / iOS Safari, must-support, user-confirmed 2026-10-08); [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §4 matrix M1–M5 with roles and record requirements |
| 6 | Tell which decisions remain proposals | **PASS** | DECISIONS.md statuses and the 2026-10-08 amendment record; status headers on every package doc; [AUDIT.md](AUDIT.md) §C; §4 below |

P6 completion criterion ([WORK_PACKAGES.md](WORK_PACKAGES.md)): "No unresolved production-blocking decisions; all proposed choices identified." Every proposed choice in the set is identified as such; the items that remain before production are **ratifications by the user** (§4), not further drafting. On paper, the specification is complete. Formally, gate V0 in [VALIDATION.md](VALIDATION.md) is the specification gate this package serves; its evidence is §1–§2, and its sign-off folds into §4.

## 3. Revised acceptance matrix — VALIDATION V1–V9

All gates are **PENDING**. No implementation, art, or device run exists, so nothing can be marked tested; each row states the evidence that would close it (per [VALIDATION.md](VALIDATION.md), recorded in its handoff evidence format).

| Gate | Status | Evidence that would close it |
|---|---|---|
| V1 art calibration | PENDING | The five style-pack pieces briefed in [ART_BIBLE.md](ART_BIBLE.md) §8 actually produced; approval recorded in the §9 register with a style-lock revision; logical-view (1280×720) and phone-size scene review showing one consistent treatment, readable hero/threats/terrain, no visible pixels. No candidate art exists today. |
| V2 sprite technical | PENDING | Automated dimensions/alpha/frame-inventory checks over real files against [ASSET_BRIEFS.md](ASSET_BRIEFS.md) canvases/pivots; the first real packed atlas measured and [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) §3 re-run with measured trim/packing factors (replacing the §2 assumptions), confirming or revising the §4 verdict. |
| V3 animation | PENDING | Timed reels of every clip, contact sheets, and pivot/socket/hitbox overlays per ANIMATION_SPEC's completeness proof, plus in-engine recordings of each action; covers all states/transitions, ≤ 2 source px grounded drift, attached whip, correct active windows. |
| V4 terrain | PENDING | The repeated 3×3 patch and representative platforms with collision overlays ([ASSET_SPEC.md](ASSET_SPEC.md) §4); no seams; decoration never misrepresents collision; top edges on module boundaries. |
| V5 touch controls | PENDING | Screen recording and observation on M1 — iPhone 17 / iOS Safari per D14 and [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §4–5 (VALIDATION.md's "agreed Android hardware" wording is superseded, SW-3); move+jump+whip and crouch+whip together; recovery from cancellation/focus loss; touch targets ≥ 64 CSS px. |
| V6 feel | PENDING | At least three unfamiliar players on the short onboarding; at least two complete the first mixed jump/whip encounter within three attempts without control confusion; failures recorded, including the two probes [STAGE_DESIGN.md](STAGE_DESIGN.md) names (at-limit 64 u steps; the B2 pre-checkpoint pit). |
| V7 stage | PENDING | A complete playthrough of the built stage: no impossible mandatory jumps (checked against the §4 table), checkpoint/death/retry/boss/exit all exercised, no stuck states or off-screen unavoidable hits. |
| V8 browser / performance | PENDING | [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §5 protocol executed on M1 with engine build, export preset, device/OS/browser, viewport, and thermal state recorded: 60 fps with p95 frame ≤ 20 ms over a 3-minute warmed run; cold payload ≤ 30 MiB; ≤ 12 s load at 20 Mbps / 50 ms RTT; resident textures ≤ 7 pages / 112 MiB under the R1 amendment ratified 2026-10-08 (see §4). All figures remain PROPOSED until measured. |
| V9 future APK | PENDING (deferred with D16) | After D16 activates: debug APK install and touch/resume test on real hardware, prerequisites and versions recorded per [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §6. |

## 4. Ratification list — RESOLVED 2026-10-08 (kept for the record)

Production (Godot project, greybox, style-pack generation, any art or build) requires a **separate explicit implementation assignment** per [AGENTS.md](../AGENTS.md) and production gate 1 in [WORK_PACKAGES.md](WORK_PACKAGES.md); no ratification below substitutes for that assignment, and this package did not request it. All three items were put to the user on 2026-10-08 and resolved the same day; the resolutions are recorded in [DECISIONS.md](DECISIONS.md) Amendments.

- **R1 (joint, production-blocking): RATIFIED 2026-10-08 under user-delegated judgement** ("use your judgement"; recorded in DECISIONS.md as the assistant's judgement exercised at the user's direction). [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) §5 together with [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §2's mip setting: (a) slice art atlases ship **without mip chains**; (b) residency is accounted by **peak concurrent page set ≤ 7 pages** (core + one encounter set, swapped at the boss gate), giving a 112.0 MiB peak against the 128 MiB budget with 16.0 MiB headroom; (c) import settings (linear filtering, sRGB, lossless, mips off) follow. Without (a)+(b) the budget fails as written (170.7 MiB all-resident mipmapped, §1 #23). It stays unvalidated until V2/V8 measure real art, and TEXTURE_BUDGET §6's sensitivity bound (144 MiB if trims run 10 points worse) stands as the warning.
- **R2: D09 — RESOLVED 2026-10-08 by direct user statement:** no stomp kills; contact, including landing on an enemy, hurts; the whip is the only weapon. The baseline every package assumes stands confirmed; no P1 revision needed.
- **R3: the D07–D11 baselines and their derivatives — CONFIRMED AS TUNABLE BASELINES 2026-10-08 under user-delegated judgement** ("use your judgement"; same recorded caveat as R1). Slice shape (D07), controls (D08), engine baseline (D10, pinned to Godot 4.7.2-stable in [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §1), and view/grid/density (D11) stand; derived numbers (GAMEPLAY_RULES [P1 proposal]s, STAGE_DESIGN [P4 proposal]s, ART_BIBLE designs subject to V1 review, ASSET_BRIEFS counts, TECHNICAL_SPEC performance targets) are tunable baselines rather than open questions, each revisable on greybox/device evidence without reopening the baselines.
- **R4 (first production spend, after the implementation assignment): the style pack.** Authorize production of the five calibration pieces ([ART_BIBLE.md](ART_BIBLE.md) §8) and their V1 review; the resulting `style_lock_r01` is the reference every P3 brief waits on. Listed here so the ratification conversation is complete, not as a request to start it.

## 5. AUDIT.md roll-up (B1–B12)

Status key: **resolved-on-paper** (closed at the document level; factual validation, where applicable, belongs to §3's gates) / **open-with-owner** (named owner must act).

| Item | Subject | Status | Owner / where it landed |
|---|---|---|---|
| B1 | Identity vs distribution rights | resolved-on-paper | User decision 2026-10-08 (original hunter); DECISIONS amendments; wording pass re-verified by grep in this pass — "Simon" survives only in the DECISIONS supersession record, REVIEW_RECORD's dated entries, AUDIT's own text, and NEXT_LLM's supersession sentence |
| B2 | Texture budget overrun | reconciled on paper; **amendment ratified 2026-10-08** (user-delegated judgement); open only for measurement | Implementation phase (V2/V8 measured re-run) — [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) §4–6 |
| B3 | D09 stomp/contact unconfirmed | **resolved 2026-10-08** | User confirmed no-stomp baseline directly ("no stomp. whip is the weapon") |
| B4 | Device matrix undefined | resolved-on-paper | User decision 2026-10-08 (iPhone 17 / iOS Safari); [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §4–5 delivered; device evidence itself is V5/V8 (implementation phase) |
| B5 | Horror intensity undefined | resolved-on-paper | User decision 2026-10-08 (dread/decay/silhouettes, no explicit gore); enforceable limits in [ART_BIBLE.md](ART_BIBLE.md) §6 |
| B6 | Knockback magnitude unspecified | resolved-on-paper | [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §5 (160 u/s ≈ 48 u), certified against stage minima in [STAGE_DESIGN.md](STAGE_DESIGN.md) §4; feel confirmation belongs to V6 |
| B7 | Which boss hits are "heavy" | resolved-on-paper | [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §8.4 proposal (strike heavy, hazard ordinary); consistent in [ASSET_BRIEFS.md](ASSET_BRIEFS.md) §7 |
| B8 | Swooper hit-points ambiguous | resolved-on-paper; baseline-confirmed 2026-10-08 under R3 | [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §1 (swooper = basic, 1 HP) |
| B9 | Respawn before first checkpoint | resolved-on-paper | [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §7 (stage-start spawn); [STAGE_DESIGN.md](STAGE_DESIGN.md) checkpoint-at-module-64 layout consistent |
| B10 | Enemy inside the 40 u whip dead zone | resolved-on-paper | [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §5 (contact + knockback separation + 1 s i-frames) |
| B11 | Stale identity wording outside DECISIONS.md | resolved-on-paper | B1 wording pass; re-verified by grep in this pass (see B1 row) |
| B12 | Transfer vs resident size confusion | resolved-on-paper | Note only; both figures retained and restated side by side in [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) §5 |

No audit item remains open with a package: everything still open belongs to the user (B2 ratification, B3) or to the implementation phase's measurements (B2, B4, B6 via §3's gates).

## 6. Checks actually run in this pass

- Read in full: SPEC.md, DECISIONS.md, ANIMATION_SPEC.md, ASSET_SPEC.md, ART_DIRECTION.md, TECHNICAL_CONSTRAINTS.md, VALIDATION.md, WORK_PACKAGES.md, AUDIT.md, GAMEPLAY_RULES.md, STAGE_DESIGN.md, ART_BIBLE.md, ASSET_BRIEFS.md, TEXTURE_BUDGET.md, TECHNICAL_SPEC.md, README.md, AGENTS.md, REVIEW_RECORD.md; skimmed `prompts/` and `templates/`.
- Parsed `templates/asset-manifest.example.json` as JSON: 8 frame durations sum to 500 ms = `total_ms`, active interval [150, 250] — matches SPEC §5 / ASSET_SPEC §3.
- Resolved every relative Markdown link programmatically: 60 in the pre-existing document set at sweep time, 136 including this review and its REVIEW_RECORD entry — 0 broken either way.
- Recomputed the full texture pipeline programmatically (per-class canvas pixels → MiB → trim factors → packing → page counts → all three residency readings → the +10-point sensitivity case): every figure matches [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) §§2–4 and §6 exactly (278.97 / 102.68 MiB; 8 / 7 / 6 pages; 170.7 / 112.0 / 96.0 MiB; 9 pages / 144 MiB sensitivity).
- Re-summed frame counts from the ANIMATION_SPEC and ASSET_BRIEFS tables (hero 113 body over 21 clips + 24 whip; pursuer 46; swooper 36; ranged 31 + 3; boss 70) and the clip-duration totals against GAMEPLAY_RULES §8's tell/recovery timings.
- Re-derived by hand: jump envelope (0.4 s / 128 u / 192 u), knockdown + get_up 810 ms ≤ 1 s, knockback 48 u < 64 u, whip-canvas reach 256 u > 168 u, stage module arithmetic (104 × 64 = 6656; arena 14 × 64 = 896; traversal ≈ 27.7 s), and the 30 MiB / 12 s / 20 Mbps identity.
- Greps: identity wording (B1/B11 re-verified, §5), Godot version references (4.7.2-stable everywhere; 4.8 only as the excluded dev line), D09 tracking across seven documents (marked unconfirmed everywhere it is used).
- Fixes applied (newer package docs only): SW-1 in [ASSET_BRIEFS.md](ASSET_BRIEFS.md) §10; SW-2 in [STAGE_DESIGN.md](STAGE_DESIGN.md) §5. `DECISIONS.md` untouched; no confirmed requirement rewritten.

Not run, because they cannot be run on documents: engine import, sprite/animation checks, playtests, touch tests, device measurements, exports. VALIDATION V1–V9 remain **PENDING** (§3), and every performance and budget figure in the set remains a proposal until those gates produce evidence.

# Initial handoff review

Date: 2026-10-07. Scope: documents and examples only.

## Completed checks

- All 18 relative Markdown file links in the initial 16-file handoff resolve.
- The example asset manifest parses as JSON.
- The eight example attack-frame durations sum to 500 ms, matching the gameplay and asset contracts; active interval is [150, 250) ms.
- The proposed hero animation table totals 113 body frames plus 24 weapon frames (137 total).
- Untrimmed frame memory is explicitly reconciled as a budget conflict to solve before production: 113 MiB body + 36 MiB weapon exceeds the 128 MiB slice-art target.
- Final interview direction is reflected throughout: primarily Castlevania, no visible pixels, full supported-action animation. Earlier Mario/crossover brainstorming is not a production commitment.
- No existing workspace project, third-party art binary, game implementation, or generated asset was copied into this repository.

## Explicitly not tested

Engine import, sprite quality, animation playback, combat behavior, mobile touch controls, browser export, performance, loading, and Android APK. No implementation or assets exist to test.

## Open at publication

The final identity answer is confirmed: Simon Belmont in Castlevania’s world. Exact costume reference, horror intensity, target hardware, and proposed numerical tuning remain for later specification work. No further interview is required to use this handoff.

---

# Follow-up review — audit + P1 gameplay rules

Date: 2026-10-08. Scope: documents only. This entry appends to, and where noted supersedes, the 2026-10-07 record above; the original entry is retained unedited as history.

## Completed checks

- Cross-document audit written to `docs/AUDIT.md`. All shared numbers re-derived and consistent: jump envelope (640/1600 → 0.4 s apex, 128 u rise, 192 u same-height travel; SPEC's 112 u gap / 64 u step limits sit inside it); whip frame durations [75,75,50,50,62.5,62.5,62.5,62.5] sum to SPEC's 150/100/250 ms phases, 500 ms total, active interval [150, 250) ms; crouch body 40×60 centered (0, −30) vs standing 40×104 centered (0, −52) share the y=0 foot origin; knockdown + get-up (360 + 450 = 810 ms) fits inside the 1 s invulnerability.
- The manifest example still parses as JSON and matches the contracts; all relative Markdown links in the repo were re-resolved programmatically (18 checked, 0 broken before this pass's additions; re-checked after, see commit).
- `docs/GAMEPLAY_RULES.md` (Package P1) completed as a fully PROPOSED baseline: hero state-transition table covering every ANIMATION_SPEC state with interruption priority, input rules (100 ms coyote/buffer, opposing-input neutral, fresh-press whip, focus-loss input clear), damage/knockback/knockdown rules, all crouch-clearance cases, pit/death/checkpoint/retry cases, and briefs for the ground pursuer, airborne swooper, stationary ranged threat, and two-attack boss — each with timing windows shown arithmetically compatible with the 500 ms whip timeline and 128 u jump rise, at SPEC hit-points (1/2/8).
- Three user decisions dated 2026-10-08 recorded in `docs/DECISIONS.md` (Amendments section, ledger resolve format): D02/D12 superseded — protagonist and world are an **original hunter in an original gothic world** (Castlevania retained as design reference only); D13 confirmed — dread, decay, silhouettes, **no explicit gore**; D14 confirmed — target device **iPhone 17 / iOS Safari** (must-support). D09 and all other entries untouched.
- The identity contradiction (D02/D12 vs the public distribution confirmed in D15) is therefore closed. Remaining audit items are an unresolved texture-budget reconciliation (hero frames 149 MiB untrimmed vs the 128 MiB slice budget — P3/P5) and a list of wording follow-ups in SPEC/README/AGENTS/ART_DIRECTION/ASSET_SPEC/prompts that this pass deliberately did not edit (AUDIT B1/B11); TECHNICAL_CONSTRAINTS' Android-phone performance anchor is superseded in substance and owed a P5 rewrite, also not edited here.

## Explicitly not tested

Everything from the 2026-10-07 list still stands: engine import, sprite quality, animation playback, combat behavior, mobile touch controls, browser export, performance, loading, and Android APK. The iPhone 17 / iOS Safari target (D14) has no device evidence yet; VALIDATION gates V1–V9 all remain PENDING. No implementation or assets exist to test.

## Open after this pass

- D09 (stomp kills vs the contact-hurts baseline) is the only remaining user question; P1 proceeds on the proposed baseline.
- D07–D11 remain PROPOSED; `docs/GAMEPLAY_RULES.md` and its [P1 proposal] values need user confirmation or greybox evidence before being treated as settled.
- Follow-up packages unblocked in sequence: wording consistency pass (B1 list), P2 art bible (identity reference now creatable; D13 line fixed), P3 asset briefs with a packed texture-occupancy table (B2), P5 technical/export design anchored on iPhone 17 Safari (B4).

---

# Follow-up review — B1 wording consistency

Date: 2026-10-08. Scope: documents only.

## Completed checks

- B1 wording pass executed across the seven files enumerated in AUDIT B1/B11: `SPEC.md` (§1 identity, §2 signature moment, §5 "hunter's foot pivot" / contact wording), `README.md` (title line), `AGENTS.md` (intent bullet, guardrail meaning preserved), `docs/ART_DIRECTION.md` (visual grammar, Reject section), `docs/ASSET_SPEC.md` (§2, §3), `prompts/ASSET_GENERATION.md` (identity paragraph, hero key-pose example), `prompts/NEXT_LLM.md` (protagonist paragraph). Product identity now reads as an original hunter in an original gothic world; Castlevania appears only as design reference for tone/mechanics. No numbers, timings, or confirmed decisions were changed.
- Post-edit grep over the seven files: the only remaining "Simon" occurrence is in `prompts/NEXT_LLM.md`, explicitly describing the superseded interview-era identity. AUDIT items B1's follow-up list and B11 are closed by this pass (see AUDIT.md status notes).

## Explicitly not tested

Unchanged from prior entries: no implementation, assets, device, or performance evidence exists. VALIDATION gates V1–V9 remain PENDING.

## Open after this pass

- P4 stage design, P2 art bible, P3 asset briefs/texture budget, P5 technical spec (see subsequent entries), P6 readiness review, and user question D09.

---

# Follow-up review — P4 stage design

Date: 2026-10-08. Scope: documents only.

## Completed checks

- `docs/STAGE_DESIGN.md` written as a fully PROPOSED, NOT-TESTED blockout specification: the five SPEC §3 beats laid out over 104 terrain modules (x 0–6656) on the 64 u grid, with terrain layout per beat, an encounter table (effigy, five pursuers, two swoopers, one ranged threat, boss — HP 1/1/2/8 per GAMEPLAY_RULES), safe zones, checkpoint placement (module 64), boss arena bounds (modules 88–101), camera zones, and the first-minute teach sequence mapped to geometry.
- Mandatory-traversal proof is arithmetic, tabulated for all 20 mandatory elements: every gap is 64 u (≤112 u limit, 48 u margin — the only compliant same-level gap on a 64 u grid), every up-step 64 u (at the 64 u limit), every mandatory landing ≥128 u (six elements exactly at a limit, flagged as greybox probes). Conclusion: all mandatory geometry sits inside the proposed envelope; no impossible mandatory jump is specified. The 48 u knockback is shown to be less than half the narrowest mandatory landing (64 u), closing the AUDIT B6 dependency on P4. The no-sub-104 u-passage rule is recorded (no crouch-walk exists).
- Known feel-risks are stated rather than hidden: one pre-checkpoint pit (B2, module 34) on the single-checkpoint layout, and the at-limit steps.

## Explicitly not tested

No greybox, level file, or playtest exists; beat pacing (3–5 min), camera behavior, and all geometry "feel" are unproven. VALIDATION V6/V7 remain PENDING.

## Open after this pass

- P2 art bible, P3 asset briefs/texture budget, P5 technical spec, P6 readiness review, D09.

---

# Follow-up review — P2 art bible

Date: 2026-10-08. Scope: documents only.

## Completed checks

- `docs/ART_BIBLE.md` written (Package P2): a named palette of 17 swatches with proposed hexes mapped one-to-one to ART_DIRECTION's palette roles (plus budgeted signal/material colors for interactables, the enemy projectile, and the hunter), silhouette/material/light rules implementing the upper-left light and five-layer depth stack, an original hunter design brief (silhouette, face/hair, thorn-knot costume construction, layered whip — franchise elements named as rejection reasons), visual briefs for the pursuer, swooper, ranged threat, and boss keyed to GAMEPLAY_RULES §8 tells, environment kit rules, and the D13 line rendered as an enforceable permit/prohibit list for asset review.
- The style-pack calibration plan is written as five filled briefs in `templates/ASSET_BRIEF.md` format (`style_hero_neutral`, `style_hero_attack_key`, `style_enemy_pursuer`, `style_terrain_patch_3x3`, `style_env_mockup`) — briefs and reference requirements only; no images were generated or claimed. Each is marked DRAFT/PENDING per the template's rule that nothing is READY before the style reference exists; the reference register and style-lock process (`style_lock_r01` on approval) are defined.
- Cross-checked against P1: every tell the gameplay rules rely on (pursuer rear-up, swooper wing-fold, ranged charge, boss wind-up and hazard ring) has a matching visual specification; hitbox overlays use SPEC §5 numbers unchanged.

## Explicitly not tested

No candidate art exists; identity, palette, and readability are unverified until the pack is produced and reviewed at logical and phone sizes. VALIDATION V1 remains PENDING.

## Open after this pass

- P3 asset briefs/texture budget, P5 technical spec, P6 readiness review, D09.

---

# Follow-up review — P3 asset production briefs + texture budget

Date: 2026-10-08. Scope: documents only.

## Completed checks

- `docs/ASSET_BRIEFS.md` written (Package P3): complete slice inventory with per-asset ID, canvas, pivot, density, frame counts and durations (each clip's durations sum to its stated total; combat clips reproduce SPEC §5's [75,75,50,50,62.5,62.5,62.5,62.5] = 500 ms, active [150, 250) ms), sockets/events, collision references, dependencies, and rejection rules — hero 113 body + 24 whip frames (ANIMATION_SPEC counts), pursuer 46, swooper 36, ranged 31 + projectile 3, boss 70 (enemy/boss counts proposed here with clip totals tied to GAMEPLAY_RULES tell/recovery timings), 14 terrain tiles, 4 backgrounds, 4 stage props, 18 UI assets, 6 VFX clips, audio deferred as an ID inventory. Manifest field definitions are stated against `templates/asset-manifest.example.json`.
- `docs/TEXTURE_BUDGET.md` reconciles AUDIT B2 with full arithmetic: slice total 278.97 MiB untrimmed → 102.68 MiB trimmed under stated per-class trim factors at 85% packing efficiency = 8 atlas pages all-resident (170.7 MiB mipmapped; 128.0 MiB without mips) — **the 128 MiB budget does not hold as written**. Peak-concurrency readings: boss-arena peak 7 pages (112.0 MiB without mips), mixed-beat peak 6 pages (96.0 MiB). The proposed smallest contract change (no mip chains on slice art + peak-concurrency residency ≤7 pages with the boss-gate swap) is recorded as PROPOSED for P6/user ratification; no ASSET_SPEC or TECHNICAL_CONSTRAINTS number was edited. AUDIT B2 status updated accordingly: reconciled on paper, unresolved in fact until real packed art is measured.

## Explicitly not tested

No art exists to trim, pack, or measure; every trim factor and the 0.85 packing efficiency are planning assumptions. VALIDATION V2/V8 remain PENDING.

## Open after this pass

- P5 technical spec, P6 readiness review (including ratification of the TEXTURE_BUDGET amendment), D09.

---

# Follow-up review — P5 technical / export specification

Date: 2026-10-08. Scope: documents only.

## Completed checks

- `docs/TECHNICAL_SPEC.md` written (Package P5): engine pinned to **Godot 4.7.2-stable** with matching export templates — verified by direct fetch of the official godotengine.org download archive page for 4.7.2-stable on 2026-10-08 (4.8 exists only as dev snapshots and is excluded); GDScript (not .NET) and the Compatibility renderer per D10 and the official web-export documentation; single-threaded web export as the baseline, with the COOP/COEP cross-origin-isolation requirement stated as the reason threaded builds are not the default.
- Scene/input/data boundaries specified per TECHNICAL_CONSTRAINTS' responsibility split (input layer, player state machine, combat hit-IDs, animation event reporting, level data, presentation, per-set asset loading), an 8-item web export checklist, a device/browser matrix anchored on **iPhone 17 / iOS Safari as must-support** (D14) with desktop Chrome/Firefox as dev references, and a performance measurement protocol (60 fps, p95 frame ≤20 ms, ≤30 MiB cold payload, ≤12 s at 20 Mbps/50 ms RTT — all PROPOSED, NOT-TESTED) re-anchored from the superseded Android-phone anchor. Android APK remains DEFERRED with a prerequisites list. AUDIT B4's follow-ups are recorded as delivered.

## Explicitly not tested

No engine project, export, or device run exists. Every performance figure is a hypothesis awaiting the §5 protocol on real hardware; VALIDATION V5–V9 remain PENDING.

## Open after this pass

- P6 readiness review (contradiction sweep + acceptance matrix, including joint ratification of the TEXTURE_BUDGET amendment and this spec's import settings), user confirmation of D07–D11, and D09.

---

# Follow-up review — P6 readiness review

Date: 2026-10-08. Scope: documents only.

## Completed checks

- `docs/READINESS_REVIEW.md` written (Package P6), completing the WORK_PACKAGES sequence P0–P6 on paper. Full contradiction sweep over every shared value in the document set (jump envelope, whip timeline/hitbox, HP and i-frame arithmetic, frame counts 113 + 24 and enemy totals 46/36/31+3/70, stage clearances, texture figures, Godot 4.7.2 pin, iPhone 17 anchor, decision statuses): 25 AGREE, 3 DISAGREE — all values re-derived; the texture pipeline (278.97 MiB untrimmed → 102.68 MiB trimmed; 8/7/6-page residency readings; 144 MiB sensitivity case) recomputed programmatically and matched exactly; the manifest example re-parsed (durations sum 500 ms, active [150, 250]); all relative Markdown links re-resolved (60 in the pre-existing set, 136 including the new documents), 0 broken; stale-identity grep re-run (B1/B11 hold).
- Two genuine inconsistencies in the newer package docs found and fixed: **SW-1** — `ASSET_BRIEFS.md` §10 claimed "18 assets" where its own table enumerates 13 asset IDs / 19 frames (the count TEXTURE_BUDGET's UI pixels are computed from); corrected in ASSET_BRIEFS, and the P3 REVIEW_RECORD entry above repeats the 18 figure — left unedited as dated history, superseded here. **SW-2** — `STAGE_DESIGN.md` §5's R1 "lane covers ground modules 66–78" overlapped §6's safe-zone guarantee for the checkpoint apron (modules 63–66); the §5 cell now states the shots pass 198–223 u above the ground route and cannot hit a ground hunter, per §3. A third disagreement (TECHNICAL_CONSTRAINTS' and VALIDATION V5's Android hardware anchors vs the confirmed D14 iPhone 17 target) is recorded as resolved by the documented supersession in TECHNICAL_SPEC §4–5, without editing the historical files. `DECISIONS.md` was not edited; no confirmed requirement was rewritten.
- The WORK_PACKAGES "definition of specification-ready" applied item by item in READINESS_REVIEW §2: all six PASS on paper (first minute explainable from STAGE_DESIGN §7; full asset enumeration in ASSET_BRIEFS §§2–12; rendering vs collision separated per ASSET_SPEC §2 and per-asset collision references; attack timing derivable from SPEC §5 / ASSET_SPEC §3 / the manifest example alone; exact target device named in D14 + TECHNICAL_SPEC §4; proposal status readable from DECISIONS.md and every package header).
- Revised acceptance matrix (READINESS_REVIEW §3): VALIDATION gates **V1–V9 all remain PENDING**, each with the evidence that would close it. AUDIT roll-up (READINESS_REVIEW §5): B1, B4, B5, B7–B12 resolved-on-paper; B6 resolved-on-paper with greybox confirmation owed (V6); B2 reconciled on paper but open with the user (ratification) and with the implementation phase (measurement, V2/V8); B3 open with the user (D09). No audit item remains open with a package.
- Ratification list stated for the user (READINESS_REVIEW §4): **R1** the TEXTURE_BUDGET §5 amendment (no mip chains; ≤7-page peak-concurrency residency; 112.0 MiB peak) ratified jointly with TECHNICAL_SPEC §2's import settings — without it the 128 MiB budget fails as written (170.7 MiB all-resident mipmapped); **R2** D09 (confirm the contact-hurts/no-stomp baseline or request stomp kills); **R3** confirmation of the D07–D11 PROPOSED baselines and their P1–P5 derivatives; **R4** style-pack authorization at V1, after the implementation assignment. Production — Godot project, greybox, art, builds — requires a **separate explicit implementation assignment** per AGENTS.md and WORK_PACKAGES production gate 1; P6 does not grant or request it.

## Explicitly not tested

Unchanged from every prior entry: no engine project, export, art, animation, playtest, touch test, or device measurement exists. The iPhone 17 / iOS Safari target (D14), the Godot 4.7.2 pin, every performance figure, and every texture-budget number remain PROPOSED/NOT-TESTED hypotheses awaiting VALIDATION V1–V9 evidence.

## Open after this pass

- User ratifications R1–R3 (READINESS_REVIEW §4); D09 remains the only open interview question.
- The specification phase is complete on paper: P0–P6 delivered, AUDIT B1–B12 dispositioned, VALIDATION V0's document-side evidence assembled in READINESS_REVIEW §§1–2. The next step belongs to a future explicit implementation assignment (WORK_PACKAGES production gates 1–5), starting with locking the engine version and the proposed mechanics, then a greybox touch movement + whip test on iPhone 17 hardware.

---

# Follow-up review — art contract and lessons from the first implementation

Date: 2026-10-12. Scope: documents, `contract/art_contract.json`, `tools/`. Trigger: the user reviewed the first implementation (askjackb/gothic-whip-game, built autonomously 2026-10-08/09 from the drafts imported here) and its five rounds of user-found sprite defects, and asked for a specification concrete enough for autonomous full-quality builds. Decisions D20–D25 recorded from a scope interview the same day.

## Completed checks (all actually run)

- `node tools/contract-check.mjs`: PASS, 64 clips / 356 frames, 64 ASSET_BRIEFS rows cross-checked. Shown failing on two seeded mismatches (a changed walk duration in the JSON; a wrong stated total in the briefs).
- The check found four real specification defects on its first runs, all fixed: the ranged canvas (256×320, pivot 288) could not hold its 300 px figure; the pursuer canvas could not hold its rear-up tell; the boss canvas could not hold its wind-up; two ranged/swooper height bands were looser than their designs. The first three are exactly the clipping the first implementation shipped. TEXTURE_BUDGET re-run after the canvas changes: all page readings unchanged (8 / 7 / 6).
- `node tools/selftest.mjs`: PASS. A synthetic correct frame set for every clip audits with 0 DEFECT (also after a PNG round trip on disk), and 25 seeded defects are each reported by the rule aimed at them. Runtime about 40 s.
- `node tools/review-pack.mjs` on the synthetic set: 135 images; lineup and composite sheets inspected by eye (guides, sockets and hitboxes land where expected).
- All 172 relative Markdown links resolve; every JSON file parses.

## Explicitly not tested

- The tools have never been run on real painted art. Their thresholds come from the first implementation's audits, which were calibrated on that art set; the next build is the first real test, and every FLAG/DEFECT pattern it produces should be compared against what a reviewer sees.
- The independent-reviewer protocol (prompts/ART_REVIEW.md) has not been exercised on a real pack.
- Gameplay tests T-01…T-09 are specified, not implemented (they belong to a build).
- No engine, device or browser work was done.

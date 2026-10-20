# Texture budget reconciliation — Package P3 (closes AUDIT B2)

**Status: PROPOSED model; NOT-TESTED.** No production art exists, so every occupancy figure below is a planning estimate built from the canvas/frame inventory in [ASSET_BRIEFS.md](ASSET_BRIEFS.md) and the trim assumptions stated in §2. The verdict in §4 is arithmetic, not measurement: it must be re-run on real packed atlases at the first production art (VALIDATION V2/V8) before anyone treats the budget as validated.

## 1. The open item

[AUDIT.md](AUDIT.md) B2: the hero's 113 body frames at 512×512 RGBA8 plus 24 whip frames at 768×512 total **149 MiB untrimmed**, against the proposed ≤128 MiB whole-slice resident budget in [TECHNICAL_CONSTRAINTS.md](TECHNICAL_CONSTRAINTS.md). This document reconciles that conflict with a full slice inventory, explicit trimming/packing assumptions, and a residency model. Coverage is not cut anywhere — ANIMATION_SPEC forbids solving this by removing actions, and nothing here does.

## 2. Method and assumptions (all [P3 proposal]s, to be measured later)

- Source density 2 px per game unit (ASSET_SPEC §1); all sizes are source pixels; RGBA8 = 4 bytes/px. 1 MiB = 1,048,576 bytes.
- Atlas page = 2048×2048 px (ASSET_SPEC §1 target maximum) = 16.00 MiB raw; a full mip chain adds one third → **21.33 MiB per page mipmapped**. The 128 MiB budget therefore buys **8.0 pages raw or 6.0 pages mipmapped**.
- **Trim factors** (fraction of canvas pixels retained after transparent-space trimming; retained frames keep canvas/pivot metadata per ASSET_SPEC §1): hero body 0.30 (figure is 224 of 512 px tall; widest attack poses set the bound), whip 0.15 (thin diagonal element; only active frames extend), pursuer/ranged/boss 0.45, swooper 0.35 (folded vs spread wings), projectile 0.50, props 0.50, UI 0.60, VFX 0.30 (sparse streaks/particles), foreground framing 0.25; opaque classes (terrain, sky, distant, midground) 1.00. These are estimates with no measured basis yet — §6 tests what happens if they are wrong.
- **Packing efficiency 0.85** (15% of each page lost to rectangle-packing waste) — a standard planning figure, also unmeasured.
- Frame counts: hero 113 + 24 (ANIMATION_SPEC); enemies/boss/UI/VFX/terrain counts from ASSET_BRIEFS.md (proposed there).

## 3. Occupancy table

| Class | Untrimmed px | Untrimmed MiB | Trim | Trimmed px |
|---|---:|---:|---:|---:|
| Hero body (113 × 512²) | 29,622,272 | 113.00 | 0.30 | 8,886,682 |
| Hero whip (24 × 768×512) | 9,437,184 | 36.00 | 0.15 | 1,415,578 |
| Boss (70 × 512×576) | 20,643,840 | 78.75 | 0.45 | 9,289,728 |
| Backgrounds sky + distant + midground (opaque) | 3,407,872 | 13.00 | 1.00 | 3,407,872 |
| Background foreground framing | 524,288 | 2.00 | 0.25 | 131,072 |
| Ranged threat (31 × 256×352) + projectile | 2,805,760 | 10.70 | 0.45/0.50 | 1,263,206 |
| Pursuer (46 × 320×256) | 3,768,320 | 14.38 | 0.45 | 1,695,744 |
| Swooper (36 × 384×256) | 3,538,944 | 13.50 | 0.35 | 1,238,630 |
| VFX set (itemized in ASSET_BRIEFS §11) | 2,097,152 | 8.00 | 0.30 | 629,146 |
| UI set (itemized in ASSET_BRIEFS §10) | 286,720 | 1.09 | 0.60 | 172,032 |
| Stage props (checkpoint, gate, exit, effigy) | 258,048 | 0.98 | 0.50 | 129,024 |
| Terrain kit (14 × 128², opaque) | 229,376 | 0.88 | 1.00 | 229,376 |
| **Total slice** | **76,619,776** | **292.28** | — | **28,488,090 (108.67 MiB)** |

*2026-10-12:* three canvases grew so that every height the art contract allows fits without clipping (`tools/contract-check.mjs` now enforces this): ranged 256×320 → 256×352, pursuer 320×192 → 320×256, boss 512×512 → 512×576. All three were clipped in the first implementation. The page readings below are unchanged: all-resident 33.52 M packed px → 8 pages (7.99, no slack), boss peak 28.58 M → 7, mixed peak 22.59 M → 6. **Measured evidence:** the first implementation, after its scale fixes, packed its full 357-frame inventory into 5 pages / 80 MiB with mips off. Real trims were better than the estimates here, but that was one art set, so the estimates stand as the planning bound.

## 4. Readings against the 128 MiB budget

Packed occupancy divides trimmed pixels by the 0.85 packing efficiency and rounds up to whole pages.

| Residency reading | Pages | Mipmapped | No mip chain | Verdict |
|---|---:|---:|---:|---|
| Everything resident at once | 8 | 170.7 MiB | 128.0 MiB | ✗ over by 42.7 MiB mipmapped; exactly at cap with zero headroom without mips |
| Boss-arena peak (core + boss set; small-enemy set unloaded) | 7 | 149.3 MiB | **112.0 MiB** | ✓ only without mips (16.0 MiB headroom) |
| Mixed-beat peak (core + small-enemy set; boss set unloaded) | 6 | 128.0 MiB | **96.0 MiB** | ✓ without mips; exactly at cap mipmapped |

"Core" = hero body + whip + terrain + backgrounds + props + UI + VFX. The peak sets are real: [STAGE_DESIGN.md](STAGE_DESIGN.md) keeps small enemies out of the boss arena and the boss out of every earlier beat, and the boss gate (module 87) is a natural page-swap point.

**Verdict: the 128 MiB budget does not hold as written.** Under the most conservative reading (all-resident, mipmapped) the slice needs ≈171 MiB. Even the friendliest all-resident reading lands exactly on the cap with zero headroom, which no production should plan against.

## 5. Smallest proposed contract change (PROPOSED — not applied)

This document does **not** edit ASSET_SPEC.md or TECHNICAL_CONSTRAINTS.md. The following amendment is proposed for ratification at P6 (or by the user against DECISIONS D11); until ratified, the 128 MiB figure and this proposal coexist and production art must not start on either assumption alone.

1. **Slice art atlases ship without mip chains.** Justification: art is authored at 2 px/u and imported at a fixed 0.5 scale (ASSET_SPEC §1), and the painted branch already specifies linear filtering; whole-view downscaling to phone resolutions is a viewport transform, and any shimmer risk is a device-check item (VALIDATION V8), not a reason to pre-pay 33% on every page. Sprites never mip in the reference pipeline this contract describes.
2. **Residency is accounted by peak concurrent page set, capped at 7 pages** (core + one encounter set), with the boss gate as the designed swap point — replacing the implicit "everything resident" reading.

With both clauses: peak residency = 7 pages × 16.00 MiB = **112.0 MiB ≤ 128 MiB**, headroom 16.0 MiB (12.5%). No canvas, density, frame count, or coverage changes; no asset is redesigned.

## 6. Sensitivity and honesty bounds

- If real trimming comes in **10 points worse** across the six character classes (e.g., hero body 0.40 instead of 0.30), the boss-arena peak grows to 9 pages = 144 MiB — **over budget even with the §5 amendment**. The amendment is necessary but not sufficient insurance.
- Therefore: the first production batch (style pack + one full hero clip set) must be packed and measured, and this table re-run with measured trim factors, before the budget is called validated (VALIDATION V2/V8). If the re-run fails, fallbacks in increasing order of contract impact: (a) split hero pages by beat residency (walk/idle resident; attack pages swapped like encounter sets); (b) reduce background panel heights (the opaque 3.41 Mpx block is the largest untrimmable term); (c) revisit the 2 px/u density or the 128 MiB figure itself — a D11-level decision for the user, never made silently here.
- The separate ≤30 MiB *transfer* target is untouched by this analysis (AUDIT B12): PNG-compressed download size is a production/P5 measurement, not derivable from resident RGBA figures.

## 7. What remains open

- Ratification of the §5 amendment (P6 or user) and a DECISIONS entry if accepted — this document proposes, it does not decide.
- Measured trim/packing factors from real art (none exists); mip-shimmer check on the D14 device (VALIDATION V8).
- AUDIT B2 status: **reconciled on paper, unresolved in fact** until those measurements exist.

# Asset production briefs — Package P3

**Status: PROPOSED inventory and values; NOT-TESTED.** No asset in this document exists. Hero frame counts come from [ANIMATION_SPEC.md](ANIMATION_SPEC.md) (proposed there); enemy/boss/UI/VFX counts are proposed here, as ANIMATION_SPEC instructs ("exact counts belong in individual briefs"). Canvases, pivots, and durations marked [P3] are new proposals; timings tied to SPEC.md / [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) are quoted, not invented. Production briefs for individual assets are instantiated from these tables using [templates/ASSET_BRIEF.md](../templates/ASSET_BRIEF.md), and each finished asset is registered with a manifest per §1. Pixel totals here feed [TEXTURE_BUDGET.md](TEXTURE_BUDGET.md) — the two documents must stay in sync.

**Shared contract (all classes unless overridden):** density 2 source px per game unit; RGBA PNG, true transparent alpha (opaque only where declared), sRGB; facing right, mirrored around the foot/body origin for left; candidate names `{asset_id}__rNN__fNNN.png` (ASSET_SPEC §6); no baked text, UI, floor shadows, hitbox art, or floor planes in sprite frames; style reference = the approved style pack's `style_lock` revision ([ART_BIBLE.md](ART_BIBLE.md) §8–9) — no production batch starts before that approval.

## 1. Manifest field definitions

Fields per [templates/asset-manifest.example.json](../templates/asset-manifest.example.json) (which parses as JSON and matches SPEC §5 timing — AUDIT A2). A manifest is **complete** when no field needed for approval is null:

| Field | Definition / completion rule |
|---|---|
| `asset_id`, `revision`, `status` | Stable snake_case ID (this document); revision increments per candidate round; status ∈ candidate / approved / rejected |
| `brief` | Path to the instantiated ASSET_BRIEF for this asset |
| `style_lock`, `identity_reference` | Style-lock revision ID and reference file path from ART_BIBLE §9; null = not ready (approval forbidden) |
| `generation` | tool / model / seed / prompt_record / reference_records; unknown values stay null and are recorded as unknown, never invented |
| `canvas_source_px`, `pixels_per_game_unit`, `pivot_source_px` | As specified per asset below; cropped exports must also carry trim offset against these (ASSET_SPEC §1) |
| `facing`, `mirror_for_left` | `right` / true for all character classes in this slice |
| `format`, `color_space`, `alpha` | `RGBA PNG` (or declared opaque), `sRGB`, `transparent` (or declared) |
| `timeline` | `loop`, `total_ms`, `active_interval_ms` where a combat window exists; convention start-inclusive/end-exclusive |
| `frames[]` | index, path, `duration_ms` (must sum to `total_ms`), `hand_socket_game_units` per frame for attack classes (null elsewhere), `sha256` once files exist |
| `collision_reference` | The SPEC/GAMEPLAY_RULES/ASSET_SPEC section that owns this asset's collision — art never defines collision |
| `synchronized_asset` | Paired layer/clip ID (whip ↔ hero attacks; boss hazard clips ↔ hazard VFX) |
| `provenance` | creator, input_sources, usage_basis — original work only; no franchise material (DECISIONS D02 amended) |
| `review` | verdict (PASS/FAIL/NOT-TESTED), evidence paths, rejection_reasons; NOT-TESTED until the ASSET_SPEC §7 evidence exists |

## 2. Hero body — canvas 512×512, pivot (256, 448), foot origin (0,0)

Standing figure 112 u / 224 px (ASSET_SPEC §1). Collision: standing 40×104 @ (0, −52), crouch 40×60 @ (0, −30) (ASSET_SPEC §2, ANIMATION_SPEC) — overlay only, never baked. Dependencies for every clip: approved `style_hero_neutral`, the pack style_lock, and the state table in GAMEPLAY_RULES §4. The coiled whip is part of body art in non-attack clips; the whip layer (§3) exists only for attacks.

| Asset ID | Frames × durations (total) | Loop / hold | Sockets / events | Collision ref |
|---|---|---|---|---|
| `hero_idle` | 8 × 125 ms (1000) | loop | — | ASSET_SPEC §2 |
| `hero_walk` | 10 × 80 ms (800) | loop, playback tuned to 240 u/s | foot-contact frames 0, 5 [P3] | ASSET_SPEC §2 |
| `hero_start_move` | 3 × 50 ms (150) | once | — | — |
| `hero_stop_move` | 3 × 50 ms (150) | once | — | — |
| `hero_turn` | 3 × 50 ms (150) | once | event `facing_flip` at frame 1 | — |
| `hero_crouch_enter` | 4 × 50 ms (200) | once | collision swap at entry (GAMEPLAY_RULES §4) | ANIMATION_SPEC crouch body |
| `hero_crouch_idle` | 6 × 150 ms (900) | loop | — | ANIMATION_SPEC crouch body |
| `hero_crouch_exit` | 4 × 50 ms (200) | once, clearance-gated | collision restore at completion | ANIMATION_SPEC crouch body |
| `hero_jump_takeoff` | 3 × 40 ms (120) | once | velocity applied frame 0 (ANIMATION_SPEC) | — |
| `hero_jump_rise` | 4 × 60 ms (240 nominal) | region-driven (vy < −160, GAMEPLAY_RULES §4) | — | — |
| `hero_jump_apex` | 3 × 50 ms (150 nominal) | region-driven (−160 ≤ vy ≤ +160) | — | — |
| `hero_fall` | 4 × 100 ms (400) | loop | — | — |
| `hero_land` | 4 × 40 ms (160) | once | jump/attack may interrupt (ANIMATION_SPEC) | — |
| `hero_attack_ground` | 8 × [75,75,50,50,62.5,62.5,62.5,62.5] (500) | once; active [150, 250) ms | `hand_socket_game_units` **required per frame**; sync `whip_attack_ground` | SPEC §5 hitbox x +40..+168, y −82..−46 |
| `hero_attack_air` | 8 × same (500) | once; active [150, 250) ms | hand socket per frame; sync `whip_attack_air` | SPEC §5 (pivot-relative) |
| `hero_attack_crouch` | 8 × same (500) | once; active [150, 250) ms | hand socket per frame (lowered); sync `whip_attack_crouch` | SPEC §5 hitbox y −48..−20 |
| `hero_hurt_recoil` | 4 × 50 ms (200) | once | attack cancelled frame 0 | — |
| `hero_knockback` | 4 × 75 ms (300) | once | physical slide 160 u/s ≈ 48 u (GAMEPLAY_RULES §5) | — |
| `hero_knockdown` | 6 × 60 ms (360) | once | ground contact before clip (ANIMATION_SPEC) | — |
| `hero_get_up` | 6 × 75 ms (450) | once | inside 1 s invulnerability (AUDIT A5) | — |
| `hero_death` | 10 × 80 ms (800) | hold final pose | airborne lethal: collapse on ground contact | — |

Body total: **113 frames**. Asset-specific rejection (in addition to §11): grounded foot-baseline drift > 2 source px in idle/attack clips; face, armor count, seam, or hair-mass change between any two frames; crouch achieved by scaling the standing art.

## 3. Whip layer — canvas 768×512, anchor (256, 448), shared foot origin

One clip per attack, synchronized frame-for-frame with §2; the whip root must meet the body frame's recorded hand socket (ASSET_SPEC §2). No blank frame during the active window (ANIMATION_SPEC).

| Asset ID | Frames × durations (total) | Synchronized asset | Sockets / events | Collision ref |
|---|---|---|---|---|
| `whip_attack_ground` | 8 × [75,75,50,50,62.5,62.5,62.5,62.5] (500) | `hero_attack_ground` | whip root = body hand socket per frame | SPEC §5 |
| `whip_attack_air` | 8 × same (500) | `hero_attack_air` | same | SPEC §5 |
| `whip_attack_crouch` | 8 × same (500) | `hero_attack_crouch` | same, lowered arc | SPEC §5 (y −48..−20) |

Whip total: **24 frames**. Rejection: root-to-socket gap visible in composite; whip reading as energy/glow (ART_BIBLE §3); extension visibly shorter than the hitbox overlay at active frames.

## 4. Ground pursuer — canvas 320×256, ground pivot (128, 224)

Visible ≈160×96 u; body ≈56 u at shoulder (ART_BIBLE §4). The canvas holds the `alert` rear-up tell at up to 1.6 × the 112 px patrol height; the first draft's 320×192 canvas could not, and the first implementation clipped those frames. Collision [P3 proposal]: contact body 96×52 u at ground origin, applied via GAMEPLAY_RULES §5 (contact = displacing hit; no stomp, D09 baseline). Dependencies: ART_BIBLE §4, approved `style_enemy_pursuer`.

| Asset ID | Frames × durations (total) | Loop / hold | Events | Behavior ref |
|---|---|---|---|---|
| `pursuer_idle` | 6 × 150 ms (900) | loop | — | GAMEPLAY_RULES §8.1 |
| `pursuer_patrol_walk` | 8 × 90 ms (720) | loop | — | patrol 60 u/s |
| `pursuer_alert` | 4 × 75 ms (300) | once | tell complete at frame 3 | 300 ms rear-up tell |
| `pursuer_approach_walk` | 8 × 70 ms (560) | loop | — | approach 100 u/s |
| `pursuer_lunge_windup` | 4 × [100,100,75,75] (350) | once | `lunge_start` at frame 3 end | 350 ms wind-up |
| `pursuer_lunge` | 3 × 80 ms (240) | once | transit at 260 u/s | — |
| `pursuer_recovery` | 4 × 150 ms (600) | once | — | 600 ms recovery |
| `pursuer_hurt` | 3 × 60 ms (180) | once | interrupts anticipation (§5 P1) | — |
| `pursuer_death` | 6 × 80 ms (480) | hold final | ash-settle per D13 | 1 HP |

Total: **46 frames**. Rejection: reads as a natural animal/pet; alert pose silhouette not distinct from patrol at phone size; any gore (ART_BIBLE §6).

## 5. Airborne swooper — canvas 384×256 [P3], body-center pivot (192, 128) [P3]

Visible ≈192×128 u. Collision [P3 proposal]: circle r 40 u at pivot. Dependencies: ART_BIBLE §4. Flight must articulate — no static gliding poses (ANIMATION_SPEC).

| Asset ID | Frames × durations (total) | Loop / hold | Events | Behavior ref |
|---|---|---|---|---|
| `swooper_perch_idle` | 6 × 150 ms (900) | loop | — | GAMEPLAY_RULES §8.2 |
| `swooper_cruise` | 8 × 90 ms (720) | loop | wingbeat contacts frames 0, 4 [P3] | patrol 175–190 u altitude |
| `swooper_dive_telegraph` | 4 × 150 ms (600) | once | `dive_start` at frame 3 end | 600 ms wing-fold tell |
| `swooper_dive` | 4 × 60 ms (240) | once | low pass through 46–82 u band | dive ≈300 u/s horizontal |
| `swooper_recovery_climb` | 6 × 150 ms (900) | once | — | 900 ms recovery |
| `swooper_hurt` | 3 × 60 ms (180) | once | — | — |
| `swooper_death_fall` | 5 × 70 ms (350) | hold final | falls, ash-settle (D13) | 1 HP |

Total: **36 frames**. Rejection: folded-telegraph silhouette not readable as a distinct shape; wings rigid across cruise; death that reads as gore.

## 6. Stationary ranged threat + projectile — canvas 256×352, base pivot (128, 320)

Visible ≈128×160 u, rooted; figure height 300 px (150 u, matching the contact body). The canvas was 256×320 with the pivot at 288 in the first draft, which left 12 px too little headroom: the first implementation clipped the hood on every frame (contract-check now rejects any canvas that cannot hold its design height). Collision [P3 proposal]: contact body 72×150 u at base. Dependencies: ART_BIBLE §4 (hooded bound figure; Grave Phosphor charge). Projectile speed 280 u/s, despawn 640 u (GAMEPLAY_RULES §8.3).

| Asset ID | Frames × durations (total) | Loop / hold | Events | Behavior ref |
|---|---|---|---|---|
| `ranged_idle` | 6 × 150 ms (900) | loop | breathing/aim sway | GAMEPLAY_RULES §8.3 |
| `ranged_aim` | 6 × 150 ms (900) | once per cycle | charge cue grows frames 0–5 | 900 ms telegraph |
| `ranged_fire` | 3 × [50,50,100] (200) | once | `projectile_spawn` at frame 1 | — |
| `ranged_recover` | 7 × 100 ms (700) | once | — | 700 ms recovery |
| `ranged_hurt` | 3 × 60 ms (180) | once | interrupts aim | — |
| `ranged_death` | 6 × 80 ms (480) | hold final | slump + ash (D13); collapses in place against its post: a full-length fall does not fit the canvas | 2 HP |
| `projectile_grave_shot` | 3 × 80 ms (240); canvas 64×64, center pivot (32, 32) | loop | despawn at 640 u | band y −70..−95 over firer's ground |

Totals: **31 + 3 frames**. Rejection: projectile reading as a bullet/sphere (must be the phosphor diamond, ART_BIBLE §4); charge cue color-only without the shape cue; figure static in idle.

## 7. Boss — canvas 512×576, foot pivot (176, 512)

Visible ≈256×288 u; figure ≈176 u tall [P3, from ART_BIBLE §4]. The canvas holds the wind-up tell, in which the striking arm raises the silhouette to about 1.4 × the standing height; the first draft's 512×512 canvas could not, and the first implementation clipped boss frames at 448 px. Collision [P3 proposal]: body 120×176 u at foot origin; strike danger zone ≈100 u forward during `boss_strike_execute` (GAMEPLAY_RULES §8.4). Dependencies: ART_BIBLE §4; hazard clips synchronize with §11 VFX.

| Asset ID | Frames × durations (total) | Loop / hold | Events | Behavior ref |
|---|---|---|---|---|
| `boss_idle` | 8 × 125 ms (1000) | loop | — | GAMEPLAY_RULES §8.4 |
| `boss_walk` | 8 × 80 ms (640) | loop | advance 70 u/s | — |
| `boss_turn` | 4 × 75 ms (300) | once | telegraphed turn | — |
| `boss_strike_windup` | 7 × 100 ms (700) | once | heavy tell (silhouette +⅓) | 700 ms wind-up |
| `boss_strike_execute` | 4 × 50 ms (200) | once | strike live frames 0–1 [P3] | heavy → knockdown |
| `boss_strike_recover` | 6 × [200,200,200,200,150,150] (1100) | once | two-whip-cycle punish window | 1100 ms recovery |
| `boss_hazard_windup` | 8 × 150 ms (1200) | once | `zone_lock` at frame 7; sync `vfx_hazard_telegraph` | 1200 ms telegraph |
| `boss_hazard_execute` | 4 × 100 ms (400) | once | sync `vfx_hazard_eruption` | 400 ms eruption ≤46 u |
| `boss_hazard_recover` | 6 × 150 ms (900) [P3] | once | — | — |
| `boss_hurt` | 3 × [70,70,60] (200) | once | does not interrupt a live strike | 200 ms flinch |
| `boss_death` | 12 × 90 ms (1080) | hold final | plate settles → ash gutter (D13), collapsing downward in place (a full-length fall does not fit the canvas); triggers exit unlock | 8 HP |

Total: **70 frames**. Rejection: wind-up indistinguishable from idle at phone size; hazard ring not the stage's only floor-level warm signal (ART_BIBLE §4); any gore in death.

## 8. Terrain kit — 128×128 per tile (64 u module), opaque, origin top-left

One kit serves the whole stage (SPEC §3). Collision is level-data-owned: cap/side/fill/platform tiles are solid as placed; decorative variants, if any are ever added, declare `collision: none` (ASSET_SPEC §4). Dependencies: approved `style_terrain_patch_3x3`. All tiles 1 frame, static.

| Asset ID | Role | Collision |
|---|---|---|
| `terrain_cap_left` / `terrain_cap_mid` / `terrain_cap_right` | walkable top surface, left/mid/right | solid; top edge = walkable line |
| `terrain_side_left` / `terrain_side_right` | exposed vertical face | solid |
| `terrain_fill_center` | interior fill | solid |
| `terrain_bottom_left` / `terrain_bottom_mid` / `terrain_bottom_right` | underside/bottom edge | solid |
| `terrain_inner_left` / `terrain_inner_right` | concave inner corners | solid |
| `terrain_plat_end_left` / `terrain_plat_mid` / `terrain_plat_end_right` | thin platform (bridge/walkway of STAGE_DESIGN) | solid |

Total: **14 tiles**. Rejection: seams in a 3×3 repeat; decoration crossing or breaking the top-edge wear line (ART_BIBLE §2); carving that reads as franchise architecture or text.

## 9. Backgrounds and stage props

Backgrounds are opaque (foreground framing has alpha), `collision: none`, layered per ART_BIBLE §2. Dependencies: approved `style_env_mockup`.

| Asset ID | Canvas | Tiling / placement | Notes |
|---|---|---|---|
| `bg_sky` | 1024×1024 | backdrop gradient, non-tiled | Abyss Violet → Crypt Violet; no stars-as-pixels |
| `bg_distant_silhouette` | 2048×384 | tiles horizontally (seam axis x) | Drowned Teal, low contrast; rooftops/spires silhouettes |
| `bg_midground_arch` | 2048×768 | tiles horizontally, declared seam | Cold Slate architecture behind the play plane |
| `bg_foreground_frame` | 2048×256 | non-tiled segments placed by level data | Abyss Violet framing; never over landings/tells (SPEC §6) |

| Asset ID | Canvas / pivot | Frames | Role |
|---|---|---|---|
| `prop_effigy` | 128×256, floor pivot (64, 224) | 1 | Isolated first whip target (STAGE_DESIGN B1); non-hostile, breaks on hit, resets on restart |
| `prop_checkpoint` | 192×320, base pivot (96, 288) | 2 (inactive / active) | Checkpoint marker; active state Ember-lit; pairs with `vfx_checkpoint_activate` |
| `prop_boss_gate` | 128×320, base pivot (64, 288) | 1 | Arena gate (STAGE_DESIGN B5); opens by presentation slide |
| `prop_exit` | 192×320, base pivot (96, 288) | 1 | Exit door; locked/unlocked shown by Ember tint overlay (presentation), unlock on boss defeat |

Rejection (backgrounds/props): fog or foreground over the play plane's tells; checkpoint/exit not findable by the Ember rule within one second at phone size; prop silhouettes confusable with enemies.

## 10. UI set

UI-space assets (not world density). Text is always live UI text — never baked (ASSET_SPEC §5). Buttons must read at the 64 CSS-px target (SPEC §6).

| Asset ID | Canvas | States / frames |
|---|---|---|
| `ui_health_full` / `ui_health_empty` | 64×64 each | 1 each (5-pip health, SPEC §5) |
| `ui_btn_left`, `ui_btn_right`, `ui_btn_jump`, `ui_btn_whip`, `ui_btn_crouch`, `ui_btn_pause` | 128×128 each | 2 each (normal / pressed) = 12 |
| `ui_checkpoint_off` / `ui_checkpoint_on` | 128×96 each | 1 each (HUD checkpoint indicator) |
| `ui_retry` | 128×128 | 1 (death/completion retry affordance icon; label is live text) |
| `ui_victory` | 128×128 | 1 (stage-clear marker icon) |
| `ui_rotate_prompt` | 192×128 | 1 (portrait rotate graphic, SPEC §6; wording is live text) |

Total: **13 assets, 19 frames** (the six buttons carry normal and pressed frames; TEXTURE_BUDGET.md pixel totals count frames). Rejection: icon illegible at actual touch size; lettering baked into the texture; pressed state indistinguishable at a glance.

## 11. VFX set

Briefed per ASSET_SPEC §5: timing, bounds, anchor, compositing. No flashing as a substitute for readable feedback; the damage indicator is non-strobing (SPEC §5).

| Asset ID | Canvas | Frames × durations (total) | Anchor / sync | Purpose |
|---|---|---|---|---|
| `vfx_whip_impact` | 192×192 | 6 × [40,40,40,50,50,60] (280) [P3] | whip-hit point | Strike contact read |
| `vfx_enemy_defeat` | 256×256 | 8 × 70 ms (560) [P3] | enemy center | Ash-dissolution defeat (D13 — no gore) |
| `vfx_checkpoint_activate` | 256×384 | 8 × 90 ms (720) [P3] | `prop_checkpoint` base | Checkpoint capture moment |
| `vfx_hazard_telegraph` | 320×128 | 4 × 300 ms (1200) | floor zone; sync `boss_hazard_windup`, zone 160 u wide (GAMEPLAY_RULES §8.4) | Ember Bright cracked ring |
| `vfx_hazard_eruption` | 320×192 | 6 × [60,60,70,70,70,70] (400) | floor zone; sync `boss_hazard_execute` | Eruption ≤46 u tall |
| `vfx_damage_indicator` | **engine-drawn**, no art file | 2 × 150 ms (300) [P3] | screen-space edge element | Pairs with the hunter's Bone-white tint; steady, non-strobing. Drawn in engine code (ART_CONTRACT V-04): the first implementation generated it as a full-screen vignette, chroma keying made it fully transparent, and the damage flash never rendered |

Rejection: telegraph readable only by color (shape must carry it); strobing above the SPEC §5 comfort line; VFX obscuring the landing or tell it accompanies.

## 12. Audio — DEFERRED inventory only

No audio production in this phase (ASSET_SPEC §5). Proposed IDs for the later scoped task: `sfx_whip_swing`, `sfx_whip_hit`, `sfx_jump`, `sfx_land`, `sfx_hurt`, `sfx_death`, `sfx_enemy_tell`, `sfx_checkpoint`, `sfx_boss_tell`, `mus_ambience_loop`, `mus_stage_loop`. Before production, that task must specify sample rate, channels, loop points, and peak/headroom per file, with original or licensed sources and provenance recorded (manifest §1). Franchise audio extraction is prohibited.

## 13. Shared rejection rules

Applied in ASSET_SPEC §7's order (dimensions/alpha → identity/scale → alignment/temporal → socket/hitbox sync → tiling → phone readability → engine/budget), plus: every ANIMATION_SPEC rejection (static substitutes, one-pose jump/fall/hurt, costume drift, disconnected whip, skating feet, translation-only knockback, instantaneous death, unreachable clips); every ART_BIBLE §7 item (including franchise derivation and D13 gore); canvas/pivot/duration mismatch with this document; per-frame durations not summing to the clip total; missing hand sockets on attack frames; undocumented trim/resize (ASSET_SPEC §1). A failed asset stays `candidate`/`rejected` in its manifest — it is never quietly fixed in the atlas.

## 14. Dependency summary

`style_lock` pack (ART_BIBLE §8) → hero/whip/enemy/terrain/background production. GAMEPLAY_RULES (P1) → all timing, socket, and collision references. STAGE_DESIGN (P4) → terrain/props/background placement and quantities (one stage, one kit; patrol counts do not multiply unique art — P1–P5 and S1–S2 share the §4–§6 clip sets). TEXTURE_BUDGET.md → whether this inventory fits the resident budget and under what amendment. P5 → import settings that realize §1's format claims. Open: D09 (stomp) would add no assets but would change §4–§6 contact expectations if ever reversed.

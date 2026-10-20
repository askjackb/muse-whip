# Gameplay rules — Package P1

**Status: PROPOSED baseline in full.** Nothing in this document is user-confirmed. It is written against the PROPOSED slice (D07), control scheme (D08), no-stomp contact rule (D09, user not yet answered), engine baseline (D10), and view/grid numbers (D11), using the confirmed requirements only for scope boundaries (D01, D03–D06, D18). Enemy names and appearances remain open (SPEC §3); the hero is referred to generically as **the hunter**. Values sourced from SPEC.md, [ANIMATION_SPEC.md](ANIMATION_SPEC.md), and [ASSET_SPEC.md](ASSET_SPEC.md) are quoted with their source; every value invented here is marked **[P1 proposal]** and needs user confirmation or greybox playtest evidence (VALIDATION V6) before it is treated as settled.

All runtime behavior described here is **NOT-TESTED**: no implementation exists. This document is the paper proof that the proposed rules, enemy behaviors, and geometry are mutually compatible; [VALIDATION.md](VALIDATION.md) gates V5–V7 remain pending.

## 1. Shared constants (single authoritative values)

| Constant | Value | Source |
|---|---|---|
| Logical view | 1280×720 units, +x right, +y down | ASSET_SPEC §1 |
| Terrain module | 64×64 units | ASSET_SPEC §1 |
| Hunter standing collision | 40×104, centered (0, −52) → y [−104, 0] | ASSET_SPEC §2 |
| Hunter crouch collision | 40×60, centered (0, −30) → y [−60, 0]; foot origin y=0 unchanged | ANIMATION_SPEC |
| Horizontal top speed | 240 u/s | SPEC §4 |
| Gravity | 1600 u/s² | SPEC §4 |
| Jump initial velocity | −640 u/s (apex 0.4 s, rise 128 u, same-height travel 192 u) | SPEC §4, derived in [AUDIT.md](AUDIT.md) A1 |
| Coyote time / jump buffer | 100 ms each | SPEC §4 |
| Whip timeline | 150 ms anticipation + 100 ms active + 250 ms recovery = 500 ms | SPEC §5; ASSET_SPEC §3 |
| Whip active region (facing right) | x +40..+168; standing y −82..−46; crouched y −48..−20; left-facing mirrors x | SPEC §5 |
| Health | 5 units; every enemy hit costs 1 | SPEC §5 |
| Invulnerability after damage | 1 s, non-strobing tint | SPEC §5 |
| Enemy hit-points | basic 1, ranged 2, boss 8 (swooper counted as basic — see AUDIT B8) | SPEC §5 |

## 2. Interruption priority

From ANIMATION_SPEC, formalized. When several events arrive in the same step, resolve in this order:

1. **Lethal damage** — a damage event (outside invulnerability) that reduces health to 0. Enters `death` from any state. Damage arriving during invulnerability is dropped entirely, so lethal damage can never occur inside the 1 s window. Falling past the stage kill plane is not damage and bypasses invulnerability (see §7).
2. **Nonlethal damage / knockdown** — interrupts anything below, including a committed attack: the outgoing whip hitbox deactivates in the same step (SPEC §4).
3. **Committed attack or heavy recovery** — an attack already started, `knockdown`, or `get_up`. Accepts no interruption except priority 1–2; in practice knockdown/get_up run inside the invulnerability window (810 ms < 1000 ms, AUDIT A5), so they are uninterrupted.
4. **Airborne movement** — `jump_takeoff`, `jump_rise`, `jump_apex`, `fall`, `attack_air`. Landing exits downward in priority, never upward into a ground state mid-frame.
5. **Crouch** — `crouch_enter`, `crouch_idle`, `crouch_exit`, `attack_crouch`.
6. **Grounded movement / idle** — `walk`, `start_move`, `stop_move`, `turn`, `land`, `idle`, `attack_ground`.

Worked combinations:

- **Whip press + jump press, same step, grounded:** the attack starts (priority 3 commitment); the jump press is buffered and expires after 100 ms — the attack runs 500 ms, so no jump occurs. (SPEC §4: jump during a grounded attack obeys the buffer and otherwise expires.)
- **Whip press, airborne:** `attack_air`; trajectory is preserved and no jump is possible (no double jump in this slice, SPEC §4).
- **Damage + whip press, same step:** damage wins (priority 2); the attack never starts and its hitbox never activates.
- **Direction reversal during an attack:** facing is locked until recovery ends (SPEC §4); the reversal is evaluated only after the attack completes, then routes through `turn`.
- **Crouch press during an attack:** ignored until the attack ends; if crouch is still held at that point, `crouch_enter` begins.
- **Landing during `attack_air`:** elapsed combat time and the per-target hit IDs carry over; the body clip switches to the corresponding grounded pose **without restarting the active window** (ANIMATION_SPEC). If the attack's 500 ms ends mid-air instead, play simply continues into the air states.

## 3. Input rules

- Horizontal: left/right from touch buttons or arrows/A–D (SPEC §4). **Opposing inputs resolve to neutral** — neither direction is stored.
- Jump: Space / jump button. Valid while grounded or within 100 ms coyote after leaving ground; a press up to 100 ms before becoming valid is buffered. Fixed height: button duration never changes the jump. No midair reversal: air steering is limited correction toward input × 240 u/s **[P1 proposal: horizontal acceleration 600 u/s² in air, so a full +240 → −240 reversal takes 0.8 s and can never exceed top speed]**.
- Whip: J / whip button. **A fresh press is required** — holding never re-triggers (SPEC §4). A press during an ongoing attack is discarded (no whip buffering) **[P1 proposal]**; a press during `land` interrupts the land clip (ANIMATION_SPEC).
- Crouch: dedicated button / down / S, held. Grounded only; there is no air-crouch state and no crouch-walk (SPEC §4). Move input while crouched is ignored.
- Simultaneous move + jump + whip must register together (SPEC §4, VALIDATION V5).
- **Focus loss, touch cancellation, or pause clears all held inputs**; on resume, nothing is held until freshly pressed (SPEC §4, §6). Pause freezes the simulation, including any in-flight attack timeline **[P1 proposal]**.
- All input is locked during `death`, checkpoint restart, and stage completion.

## 4. Hero state-transition table

Clip names and frame counts are ANIMATION_SPEC's proposed budget; durations at its stated per-frame rates. "Damage →" means the priority-2 routing of §5 (which of `hurt_recoil` / `knockback` / `knockdown` applies), and lethal damage routes any row to `death`.

| State | Enter when | Behavior | Exit to |
|---|---|---|---|
| `idle` (8f loop) | Spawn; `land`/`stop_move`/`crouch_exit` completes with no move input | Stationary; breathing loop | Move → `start_move`; jump → `jump_takeoff`; whip → `attack_ground`; crouch held → `crouch_enter`; walks off ground edge → `fall` |
| `start_move` (3f, 150 ms) | Move input from `idle` | Horizontal motion begins immediately; clip is visual only | Completes or input released → `walk` / `stop_move`; jump/whip/crouch as `idle` |
| `walk` (10f loop, playback tuned to travel speed) | Moving grounded | Up to 240 u/s toward input | Input released → `stop_move`; opposite input → `turn`; jump → `jump_takeoff`; whip → `attack_ground` (horizontal movement stops for the attack); crouch → `crouch_enter`; ground ends → `fall` |
| `stop_move` (3f, 150 ms) | Move input released | Decelerating settle; new input interrupts (ANIMATION_SPEC) | Completes → `idle`; new input → `start_move`; jump/whip/crouch as `idle` |
| `turn` (3f, 150 ms) | Direction input opposes facing while grounded, not attacking | Facing flips at the clip's explicit midpoint event; hitbox never sweeps the rear (ANIMATION_SPEC) | Completes → `walk` if input held, else `idle`; jump/whip interrupt as `idle` |
| `crouch_enter` (4f, 200 ms) | Crouch held while grounded and not attacking | Collision swaps 40×104 → 40×60 at entry **[P1 proposal: swap at entry, so ducking under a descending threat works from the press]** | Completes → `crouch_idle`; crouch released mid-enter → clearance check (§6) |
| `crouch_idle` (6f loop) | `crouch_enter` completes; or exit blocked (§6) | Stationary; move input ignored | Crouch released + clearance → `crouch_exit`; blocked → stays; whip → `attack_crouch`; jump → §6 case 3 |
| `crouch_exit` (4f, 200 ms) | Crouch released **and** standing clearance exists | Plays only with clearance (ANIMATION_SPEC); collision restores to 40×104 at completion **[P1 proposal]** | Completes → `idle`, or `start_move` if move held |
| `jump_takeoff` (3f, 120 ms) | Jump press grounded / in coyote / buffered on landing | vy = −640 applied in the entry step, not after the clip (ANIMATION_SPEC) | → `jump_rise` |
| `jump_rise` (4f) | Rising with vy < −160 **[P1 proposal: velocity-region boundary]** | Gravity; limited air correction (§3) | vy ≥ −160 → `jump_apex`; ceiling contact → vy = 0, `fall`; whip → `attack_air`; ground → `land` |
| `jump_apex` (3f) | −160 ≤ vy ≤ +160 **[P1 proposal]** | Weight-transition region around the 0.4 s apex | vy > +160 → `fall`; whip → `attack_air`; ground → `land` |
| `fall` (4f loop) | vy > +160; stepped off a ledge (no takeoff clip); ceiling cut ascent | Gravity; never adds world translation (ANIMATION_SPEC) | Ground → `land`; whip → `attack_air`; past kill plane → §7 pit sequence |
| `land` (4f, 160 ms) | Ground contact from `jump_rise`/`jump_apex`/`fall` | Compression/recovery; jump and attack interrupt immediately (ANIMATION_SPEC); move input interrupts into `start_move` **[P1 proposal]** | Completes → `idle`/`walk` by input; crouch held on landing → `crouch_enter` after the clip **[P1 proposal]** |
| `attack_ground` (8f, 500 ms) | Whip press, grounded, not crouched | Horizontal velocity 0; facing locked; hitbox live only in [150, 250) ms at x +40..+168, y −82..−46; ≤1 hit per target per attack | Completes → `idle`/`walk` by input (reversal routes via `turn`); damage → §5 (hitbox off same step) |
| `attack_air` (8f, 500 ms) | Whip press airborne | Trajectory preserved; no extra jump height; same timeline/hitbox relative to the foot pivot | Completes → current air state by velocity; landing → grounded continuation (§2); damage → §5 |
| `attack_crouch` (8f, 500 ms) | Whip press from `crouch_idle` **[P1 proposal: also from completed `crouch_enter`]** | Hitbox y −48..−20 (x unchanged); lowered whip socket | Completes → `crouch_idle` if crouch held, else §6 clearance check → `crouch_exit`/`crouch_idle`; damage → §5 |
| `hurt_recoil` (4f, 200 ms) | Non-displacing damage while grounded (rule in §5) | Attack cancelled; control locked | Completes → `idle` (or `fall` if ground vanished beneath) |
| `knockback` (4f, 300 ms) | Displacing damage (§5) | Physical slide, §5 values; articulated reaction, never translation-only (ANIMATION_SPEC) | Completes grounded → `idle`; displaced off ground / still airborne → `fall` |
| `knockdown` (6f, 360 ms) | Heavy hit (§5); airborne heavy hit lands with the knockdown flag set | Heavy-impact fall to ground contact; uninterrupted (inside i-frames) | → `get_up` |
| `get_up` (6f, 450 ms) | `knockdown` completes | Foot/ground alignment preserved; no input except pause | → `idle`; damage impossible (i-frames, §5) |
| `death` (10f, 800 ms) | Health reaches 0 (any state) | Full collapse; airborne lethal damage keeps falling and the collapse plays on ground contact (ANIMATION_SPEC); final pose holds | → §7 restart flow |

Whip overlay clips `whip_ground` / `whip_air` / `whip_crouch` (8f each) run synchronized to the three attack states on the separate weapon layer, hand-socket anchored per ASSET_SPEC §2; the whip layer has no blank frame during the active window (ANIMATION_SPEC). Every state above maps to exactly one ANIMATION_SPEC clip, and every clip is reachable — the state-inventory half of ANIMATION_SPEC's completeness proof.

## 5. Damage, knockback, knockdown, death

- **Taking a hit.** A damage event lands only outside the 1 s invulnerability window. It costs **1 health** (ordinary and heavy alike — AUDIT B7), starts invulnerability immediately (non-strobing tint), cancels any attack and deactivates its hitbox in the same step, and routes by hit class:
  - **Non-displacing** (ranged projectile) while grounded → `hurt_recoil` (200 ms, control locked).
  - **Displacing** (enemy contact, boss ground hazard, any hit while airborne) → `knockback`: horizontal impulse **160 u/s away from the source for the 300 ms clip ≈ 48 u** displacement **[P1 proposal — AUDIT B6]**, gravity normal. 48 u is less than half of a minimum 128 u landing platform (64 u), so a centered knockback cannot by itself push the hunter off a minimum platform. If the slide leaves the ground or ends airborne → `fall`.
  - **Heavy** (boss close-range strike, §9.4) → `knockdown` (360 ms) then `get_up` (450 ms). If a heavy hit lands airborne, knockback physics applies with a knockdown flag; the knockdown clip plays on ground contact.
  - **Lethal** (health reaches 0) → `death` (§4), overriding all of the above; lethal damage can never enter `get_up`.
- **Enemy contact** (baseline D09, unconfirmed): touching an enemy body — including landing on top of one — is a displacing hit on the hunter. There are no stomp kills. Contact also resolves the whip dead zone (AUDIT B10): the knockback separation plus i-frames guarantee the hunter can always re-establish the 40 u spacing.
- **Dealing a hit.** The whip hitbox is live only during [150, 250) ms of an attack, is defined by SPEC §5 geometry (never by sprite pixels), and strikes each target **at most once per attack** (per-attack hit ID, persisting across the air→ground continuation in §2). A hit enemy takes 1 damage and enters its hurt reaction, which interrupts its attack anticipation (boss exception in §9.4).

## 6. Crouch-clearance cases

Standing clearance = at least 104 u of free height above the foot origin (the standing body, ASSET_SPEC §2). Checked continuously, resolved per case:

1. **Release crouch, clearance exists** → `crouch_exit` → stand.
2. **Release crouch, no clearance** → remain in `crouch_idle`; the 40×60 body is kept and the check repeats. The hunter never pops into a ceiling.
3. **Jump pressed while crouched** → exits into a normal jump *only with standing clearance* (SPEC §4): clearance restores the standing body and `jump_takeoff` fires. Without clearance the jump is denied; the press sits in the 100 ms buffer and expires harmlessly (clearance cannot change while stationary).
4. **Damage while crouched** → §5 routing, but the collision body stays 40×60 through `knockback`/`hurt_recoil` until clearance exists **[P1 proposal]**, so a hit in a low passage can't force a stand-up into the ceiling.
5. **Attack from crouch** → `attack_crouch` with the lowered hitbox; afterwards case 1/2 logic decides standing.
6. **Moving into a low ceiling while standing** is ordinary collision blocking (the 104 u body doesn't fit); the hunter must crouch *before* the passage. There is no auto-crouch and no crouch-walk, so a low passage is traversed only if its far side is reachable stationary-crouched or by level design — P4 stage design owns passage placement.
7. **Landing with crouch held** → `land` plays, then `crouch_enter` (§4).

### 6.1 Platforms, clearance and the no-trap rule (added 2026-10-12)

The first implementation shipped a permanent soft-lock: crouching under a thin one-way tread left the hunter unable to stand, jump or move, because the clearance check counted the one-way slab as a ceiling ([LESSONS.md](LESSONS.md) L12). It also never switched to the crouch body on ordinary crouch entry (L13). These rules close both.

1. **Platform kinds.** Every surface in level data is either `solid` (blocks from all sides) or `one_way` (blocks only from above, while falling onto it). Solid is the default. STAGE_DESIGN names every one-way surface explicitly; a surface it does not name is solid.
2. **One-way surfaces never count as ceilings.** The standing-clearance query (§6), the jump-from-crouch check (§6 case 3) and any head-bump test ignore `one_way` surfaces. Only `solid` geometry can deny standing.
3. **Crouch body on every entry.** The 40×60 crouch body is active from the first frame of `crouch_enter` on every path into crouch: pressing crouch, landing with crouch held (§6 case 7), and the air-attack landing continuation. Leaving crouch restores 40×104 only when clearance exists.
4. **No-trap rule.** From every position the hunter can reach, some input sequence moves the hunter at least 64 u or reaches the checkpoint/exit, without taking damage. A space whose clearance is between the crouch body (60 u) and the standing body (104 u) must therefore be unreachable, or have an exit the crouched, stationary hunter can use. There is no crouch-walk, so such a space is almost always a trap; level data should not create one.
5. **Measured motion tolerance.** Engine integration overshoots the analytic jump slightly (the first build measured a 133.4 u rise against 128 u). Tests accept ±6% on jump rise and travel; level geometry still uses the conservative limits of SPEC §4, never the measured overshoot.

The tests for these rules are listed in [VALIDATION.md](VALIDATION.md) "Rule-to-test traceability" (T-01…T-04).

## 7. Failure, checkpoint, retry, completion

- **Pit fall.** Crossing the stage kill plane: `fall` continues, then a visible fade/death transition (ANIMATION_SPEC: no ground-collapse clip on a nonexistent floor) → restart at the current respawn point. A pit is not damage — it bypasses invulnerability and costs no health before the restart.
- **Respawn point.** Stage start until the checkpoint is touched (AUDIT B9); touching the checkpoint (overlap, with its activation indicator from ASSET_SPEC §5) moves the respawn there.
- **Death.** `death` clip completes and the final pose holds **[P1 proposal: 500 ms]** → restart at the respawn point.
- **Restart** (death, pit, or explicit retry) restores health to 5 and resets encounter state — enemies and the boss return to initial state, and a boss-unlocked exit re-locks (SPEC §5). Animation, combat, and input state are fully reset (ANIMATION_SPEC).
- **Boss / completion.** Defeating the boss unlocks the exit (SPEC §5); touching the exit enters the stage-complete state. An explicit retry is available after death and after completion (SPEC §5); retry from completion restarts the whole stage **[P1 proposal: from the stage-start spawn with the checkpoint reset]**.
- No limited lives, no score requirement, no save persistence in this slice (SPEC §5).

## 8. Enemy and boss briefs

General rules for all four: every hit the enemy lands costs the hunter 1 health (§5); every creature has complete idle/locomotion, attack anticipation, execution, recovery, hurt, and death animation — no static substitutes, and fliers articulate flight (ANIMATION_SPEC "Enemies and boss"). Sizes below are **[P1 proposal]** bands for P3 to finalize per-brief; names/appearances are open (SPEC §3). All four are beatable with the base whip and base jump — shown per brief.

### 8.1 Ground pursuer — basic, 1 HP

- **Behavior:** patrols its platform at **[P1 proposal]** 60 u/s; when the hunter is on the same level within **[P1 proposal]** 400 u, `alert` (300 ms rearing tell) then approaches at **[P1 proposal]** 100 u/s; within **[P1 proposal]** 120 u, a 350 ms wind-up tell, then a lunge at **[P1 proposal]** 260 u/s; 600 ms recovery after a lunge, hit or miss. Contact at any time is a displacing hit (§5).
- **Why the hunter wins (math):** the whip is live at x +40..+168 while contact needs roughly x < 40. Crossing that 128 u band at 100 u/s takes **1.28 s = 2.56 whip cycles** (500 ms each), so the hunter gets at least two full attacks before contact is possible. One hit kills (1 HP). The lunge is dodgeable by jumping: at 0.25 s after takeoff the hunter's feet are 640×0.25 − 800×0.25² = **110 u** up, clearing a ground body proposed at ~56 u tall; and a whip pressed at the wind-up tell is active at 150 ms, while the lunge needs (120−20)/260 ≈ 0.38 s to arrive — the strike lands first.
- **Animation coverage:** idle, patrol walk, `alert`, approach walk (distinct gait **[P1 proposal]**), lunge wind-up, lunge, recovery, hurt, death.

### 8.2 Airborne swooper — basic, 1 HP (AUDIT B8)

- **Behavior:** patrols on an articulated flight path at **[P1 proposal]** 175–190 u altitude above the ground lane; telegraphs a dive (600 ms **[P1 proposal]**: hover, wing-fold pose, audio cue) then dives through the hunter's lane, bottoming at **[P1 proposal]** 46–82 u above the ground before climbing out; 900 ms recovery climb **[P1 proposal]**. Contact during the dive is a displacing hit.
- **Reachable-window proof (math):** standing whip covers y 46..82 u above the hunter's feet — the dive's low pass sits exactly in that band while crossing x +40..+168 horizontally at **[P1 proposal]** 300 u/s, i.e. 128/300 ≈ **430 ms inside the band** against a 100 ms active window: the hunter times one press (150 ms anticipation) inside a ~330 ms effective window. Alternatively, a jump (rise 128 u) puts the foot pivot at 128 u at the 0.4 s apex, so the air whip's band covers **174..210 u** above the takeoff ground — the swooper's 175–190 u patrol altitude is inside it, and a full jump's 0.8 s air time brackets the pass. No double jump, stomp, or agile move is needed; SPEC §3's "reachable attack window" is satisfied two ways.
- **Animation coverage:** idle/perch, cruise flight (wing articulation), dive telegraph, dive, recovery climb, hurt, death (falling).

### 8.3 Stationary ranged threat — 2 HP

- **Behavior:** rooted. `aim` telegraph **[P1 proposal]** 900 ms (aiming pose tracks the hunter, visible charge cue), `fire` (one projectile), `recover` **[P1 proposal]** 700 ms, repeat. Projectile: **[P1 proposal]** 280 u/s, flies in the y −70..−95 band above its ground (i.e., above the 60 u crouch top, through the 104 u standing body), dissipates after **[P1 proposal]** 640 u. Contact with the body is a displacing hit.
- **Why the hunter wins (math):** the projectile band passes *over* a crouched hunter (top edge −60) and *through* a standing one — crouch is a complete dodge, and a jump also clears it once the feet pass ~95 u (reached at ≈0.19 s: 640t − 800t² = 95 → t ≈ 0.19 s). Between shots the cycle is 900 + 700 = **1600 ms**, during which the hunter advances 240 × 1.6 = **384 u** unopposed; two whip hits (2 HP) at 500 ms per grounded strike close the fight. Projectile hits are non-displacing (`hurt_recoil`, §5), so a hit never knocks the hunter out of approach range unfairly.
- **Animation coverage:** idle (breathing), aim, fire, recover, hurt (interrupts aim — §5), death. Stationary ≠ static (ANIMATION_SPEC).

### 8.4 Boss — 8 HP, two attacks

- **Behavior:** grounded, advances slowly toward the hunter at **[P1 proposal]** 70 u/s, turns only through a telegraphed turn. Two attacks, separately readable (ANIMATION_SPEC):
  - **Close-range strike (heavy → knockdown):** triggers within **[P1 proposal]** 150 u; 700 ms wind-up tell, strike, then **1100 ms recovery [P1 proposal]**. The strike threatens **[P1 proposal]** the 100 u in front of the boss — inside the hunter's 168 u whip reach, so spacing beats it.
  - **Ground hazard (ordinary → knockback):** 1200 ms telegraphed marked zone **[P1 proposal: 160 u wide]** at the hunter's position, then 400 ms eruption **[P1 proposal: height ≤ 46 u]**, then recovery.
- **Why the hunter wins (math):** the strike's 700 ms tell exceeds the hunter's full 500 ms whip commitment, so even a whip started the instant the tell begins recovers 200 ms before impact. The 1100 ms recovery fits **two full whip cycles** (2 × 500 ms) — a guaranteed punish. The hazard's 1200 ms signal gives 240 × 1.2 = **288 u** of walking escape from a 160 u zone, or a jump: the hunter's feet are above 46 u from t ≈ 0.08 s to t ≈ 0.72 s (**640 ms** of clearance vs the 400 ms eruption). Eight hits at roughly one per attack cycle **[P1 proposal estimate]** puts the fight near a minute of play — to be tuned by playtest, not by this document.
- **Animation coverage:** idle, locomotion, turn, strike anticipation/execution/recovery, hazard anticipation/execution/recovery, hurt (brief flinch **[P1 proposal: 200 ms; boss execution is not interrupted by hurt once the strike itself is live]**), complete death sequence. Defeat triggers the exit unlock (§7).

## 9. What remains open after P1

- D09 (stomp) and the D07–D11 baselines need user confirmation; every **[P1 proposal]** above needs the same or greybox evidence.
- Asset-level work (per-brief canvases, pivots, sockets, packed texture occupancy against AUDIT B2) is P3; stage geometry certification against the 112 u gap / 64 u step envelope and the 48 u knockback is P4; the iPhone 17 Safari device/performance matrix (AUDIT B4) is P5.

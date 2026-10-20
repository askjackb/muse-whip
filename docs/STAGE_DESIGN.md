# Stage design — Package P4

**Status: PROPOSED in full; NOT-TESTED.** This is an annotated blockout *specification* — no level file, greybox, or playtest exists. Geometry is proven on paper against the proposed movement envelope; whether it *feels* right is gated by VALIDATION V6/V7, which remain PENDING. Enemy behavior, timing, and hit-points are [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) (P1, PROPOSED); movement constants are SPEC.md §4 / ASSET_SPEC.md §1 (PROPOSED, D11). Where this document invents a value it is marked **[P4 proposal]**.

## 1. Coordinate conventions

- Distances in game units (u); terrain module = 64×64 u. Module *n* spans x [64n, 64(n+1)).
- Heights are rows relative to the main ground line: row 0 = main ground top surface; +1/+2 = one/two modules above; −2 = two modules below. A "step" is a change of one row between adjacent surfaces.
- The stage is 104 modules wide: x 0–6656, laid out left (spawn) to right (exit).
- Envelope (SPEC §4, derived in [AUDIT.md](AUDIT.md) A1): jump rise 128 u, same-height travel 192 u, top speed 240 u/s. Conservative mandatory limits: **gap ≤ 112 u, up-step ≤ 64 u, landing ≥ 128 u**. On a 64 u grid the only compliant same-level gap is one module (64 u); two modules (128 u) already exceeds the 112 u limit. Every mandatory gap in this design is therefore exactly 64 u.

## 2. Beat map (SPEC §3 pacing beats; boundaries are [P4 proposal])

| Beat | SPEC window | Modules | x span | Content |
|---|---|---:|---:|---|
| B1 tutorial threshold | 0–45 s | 0–19 | 0–1280 | Spawn plaza, isolated whip target, recoverable gap, first pursuer |
| B2 ground patrol court | 45–90 s | 20–39 | 1280–2560 | Two patrolling pursuers, first pit gap + pursuer landing |
| B3 ruined walkway | 90–150 s | 40–62 | 2560–4032 | Stair ascent, elevated broken walkway, first swooper, street recovery |
| B4 checkpoint + mixed | 150–210 s | 63–82 | 4032–5312 | Checkpoint, ranged platform + ground pursuer + swooper combined |
| B5 boss gate / arena | 210–300 s | 83–103 | 5312–6656 | Safe apron, gated arena, boss, exit |

Pure traversal at top speed is 6656 / 240 ≈ 27.7 s; the remaining time is combat, tells, and retries. Whether a successful run lands in the 3–5 min band is a playtest question (V6/V7), not a claim.

## 3. Terrain layout per beat

### B1 — tutorial threshold (modules 0–19)

- **Spawn plaza:** ground modules 0–7 (x 0–512), top row 0. Safe zone (no enemies, no hazards). An isolated, non-hostile **training effigy** [P4 proposal — P3 asset] hangs at module 6 (x 384–448) at whip height, for the first strike.
- **Teach gap:** module 8 (x 512–576) is open at row 0. Landing **bridge platform** modules 9–13 (x 576–896), top row 0.
- **Recovery path (the gap is recoverable, per SPEC's first minute):** a recovery floor at row −2 spans modules 8–13 (x 512–896) beneath the gap and bridge (clearance under the bridge = 2 modules = 128 u ≥ the 104 u standing body). A step block at module 14 tops at row −1 (x 896–960); main ground resumes at module 15, row 0. Falling into the gap costs a 128 u fall onto the recovery floor, a walk right under the bridge, and two 64 u steps back up. No restart, no damage (no fall damage exists in the contracts).
- **First enemy ground:** modules 15–19 (x 960–1280), row 0. Pursuer **P1** patrols modules 16–18 (x 1024–1216) per GAMEPLAY_RULES §8.1.
- **Second gap (combined teach):** module 14 (x 896–960) is also open at row 0 — the main path crosses it from the bridge onto P1's ground, with the recovery step directly below it, so this gap is recoverable by the same floor.

### B2 — ground patrol court (modules 20–39)

- Flat ground, row 0, modules 20–33 (x 1280–2176). Entry safe apron modules 20–21.
- Pursuer **P2** patrols modules 22–26 (x 1408–1728); pursuer **P3** patrols modules 28–32 (x 1792–2112). Patrols do not overlap; each court section gives the spacing read SPEC §2 asks for ("waits out an enemy's approach").
- **First pit gap:** module 34 (x 2176–2240) open at row 0 over a pit (kill plane at row −4, x 2176–2240 only [P4 proposal]). Landing modules 35–39 (x 2240–2560) with pursuer **P4** patrolling modules 36–38 — SPEC's "gap and enemy combined with safe landing space": the landing is 5 modules (320 u) and P4's patrol leaves module 35 as a safe touchdown strip.
- *Difficulty note (honest, for P6):* this pit sits before the stage's only checkpoint, so a fall restarts from stage start (GAMEPLAY_RULES §7). It is the stage's single pre-checkpoint pit; every other pre-checkpoint fall is recoverable by design. If V6 shows frustration, the bounded fix is a recovery floor like B1's — recorded here, not silently changed.

### B3 — ruined walkway (modules 40–62)

- Ground row 0 at module 40 (x 2560–2624). **Ascent treads:** modules 41–42 top row +1 (x 2624–2752), modules 43–44 top row +2 (x 2752–2880) — two 64 u steps with 128 u treads.
- **Walkway W1** modules 45–47 (x 2880–3072), top row +2: rest landing, no enemy.
- **Gap** module 48 (x 3072–3136). **Walkway W2** modules 49–52 (x 3136–3392), top row +2. **Gap** module 53 (x 3392–3456). **Walkway W3** modules 54–56 (x 3456–3648), top row +2.
- **Street recovery:** the street at row 0 runs beneath the walkway, modules 45–56 (x 2880–3648), clearance under the walkway = 128 u ≥ 104 u standing body. Falling from either walkway gap lands on the street (128 u fall). **Re-ascent:** a tread at module 55 tops row +1 (x 3520–3584, stacked beneath W3), then module 56's walkway top (+2) is one more 64 u step. No B3 fall is lethal.
- **Swooper S1** patrols above W2–W3 at 175–190 u above the walkway surface (GAMEPLAY_RULES §8.2 band), dive lane crossing the walkway. W2 (256 u) and W3 (192 u) both satisfy the landing minimum, so the hunter can stand, read the 600 ms telegraph, and whip from the platform.
- **Descent:** the walkway ends at module 56 (x 3648); landing at row 0, modules 57–59 (x 3648–3840, 192 u). Ground continues modules 60–62 (x 3840–4032) to B4.

### B4 — checkpoint + mixed encounter (modules 63–82)

- Ground row 0, modules 63–82 (x 4032–5312). **Checkpoint** at module 64 (x 4096–4160); safe apron modules 63–66 (no enemy patrol reaches it). Respawn follows GAMEPLAY_RULES §7.
- Pursuer **P5** patrols ground modules 67–69 (x 4288–4480).
- **Ranged threat R1** stands on a raised platform: tread module 70 top +1 (x 4480–4544), platform modules 71–72 top +2 (x 4544–4672), tread module 73 top +1 (x 4672–4736). The ground route passes beneath the platform (clearance 128 u ≥ 104 u). R1's projectile band is defined relative to its own platform surface (GAMEPLAY_RULES §8.3), so from the ground route the shots pass at 198–223 u above the main ground — over a standing hunter (top 104 u) — while P5 threatens the ground lane; from the platform route, hunter and R1 share a level and crouch (top 60 u vs band bottom 70 u) is the dodge, exactly as P1 proves. Two readable routes, no agile move required.
- **Swooper S2** patrols above ground modules 74–78 (x 4736–5056) at 175–190 u over the ground lane, after the R1 platform — the mixed encounter sequences ground → elevated → airborne threats without stacking them.
- Ground runs out at module 82 (x 5312).

### B5 — boss gate / arena (modules 83–103)

- **Pre-boss safe apron** modules 83–86 (x 5312–5568): no enemies; the last quiet space.
- **Boss gate** at module 87 (x 5568–5632). **Arena** modules 88–101 (x 5632–6528, 14 modules = 896 u), flat row 0. Arena walls at modules 87 and 102 close during the fight [P4 proposal — gate behavior, presentation-owned]. Boss spawn at module 97 (x 6208–6272); hunter enters at module 88.
- Arena width check: whip reach 168 u + boss strike danger zone ≈100 u in front of the boss (GAMEPLAY_RULES §8.4) + 48 u knockback (P1) = 316 u of the 896 u is the danger geometry; the rest is repositioning room. The boss's 70 u/s advance crosses the arena in ≈12.8 s unopposed, so spacing — not reflexes — sets the pace.
- **Exit vestibule** modules 102–103 (x 6528–6656); the exit door at module 103 unlocks only on boss defeat (SPEC §5). Touching it after the unlock ends the stage (GAMEPLAY_RULES §7).

## 4. Mandatory-traversal clearance proof

Every mandatory jump, step, and landing in §3, checked against the conservative envelope (gap ≤ 112 u, step ≤ 64 u, landing ≥ 128 u). "Margin" is limit minus requirement for gaps/steps, requirement minus limit for landings. Falls (pure drops with no horizontal gap) are listed with their landing check; no fall-damage rule exists in the contracts.

| # | Element (beat) | Requirement | Envelope limit | Margin | Verdict |
|---|---|---|---|---:|---|
| 1 | B1 teach gap, module 8 | gap 64 u | ≤ 112 u | 48 u | ✓ inside |
| 2 | B1 landing, bridge modules 9–13 | landing 320 u | ≥ 128 u | 192 u | ✓ inside |
| 3 | B1 second gap, module 14 | gap 64 u | ≤ 112 u | 48 u | ✓ inside |
| 4 | B1 landing, ground modules 15–19 | landing 320 u | ≥ 128 u | 192 u | ✓ inside |
| 5 | B1 recovery steps, −2 → −1 → 0 (modules 14–15) | steps 64 u, 64 u | ≤ 64 u | 0 u | ✓ at limit |
| 6 | B1 recovery floor landing, modules 8–13 | landing 384 u | ≥ 128 u | 256 u | ✓ inside |
| 7 | B2 pit gap, module 34 | gap 64 u | ≤ 112 u | 48 u | ✓ inside |
| 8 | B2 landing, modules 35–39 | landing 320 u | ≥ 128 u | 192 u | ✓ inside |
| 9 | B3 ascent steps (modules 41, 43) | steps 64 u, 64 u | ≤ 64 u | 0 u | ✓ at limit |
| 10 | B3 tread landings, modules 41–42 and 43–44 | landing 128 u each | ≥ 128 u | 0 u | ✓ at limit |
| 11 | B3 walkway gap, module 48 | gap 64 u | ≤ 112 u | 48 u | ✓ inside |
| 12 | B3 landing W2, modules 49–52 | landing 256 u | ≥ 128 u | 128 u | ✓ inside |
| 13 | B3 walkway gap, module 53 | gap 64 u | ≤ 112 u | 48 u | ✓ inside |
| 14 | B3 landing W3, modules 54–56 | landing 192 u | ≥ 128 u | 64 u | ✓ inside |
| 15 | B3 street fall landing, modules 45–56 (drop 128 u) | landing 768 u | ≥ 128 u | 640 u | ✓ inside |
| 16 | B3 re-ascent steps, street → +1 → walkway (modules 55–56) | steps 64 u, 64 u | ≤ 64 u | 0 u | ✓ at limit |
| 17 | B3 descent, walkway end → modules 57–59 (drop 128 u, no horizontal gap) | landing 192 u | ≥ 128 u | 64 u | ✓ inside |
| 18 | B4 platform steps (modules 70, 71 up; 73 down) | steps 64 u, 64 u, 64 u | ≤ 64 u | 0 u | ✓ at limit |
| 19 | B4 R1 platform landing, modules 71–72 | landing 128 u | ≥ 128 u | 0 u | ✓ at limit |
| 20 | B5 arena entry and exit route | no mandatory jump; flat | — | — | ✓ n/a |

**All 20 mandatory elements are inside the envelope; none exceeds a limit.** Six sit exactly at a limit (all 64 u grid steps and the 128 u platform/treads) — these are grid consequences, flagged so a greybox can confirm the at-limit steps feel right with the 40×104 collision body (VALIDATION V6/V7). Derived safety checks: the 48 u knockback (GAMEPLAY_RULES §5) is less than half of the narrowest mandatory landing (128 / 2 = 64 u), so a centered hit on any mandatory platform cannot by itself cause a fall AUDIT B6 relies on; arena walls bound the slide in B5.

Design rule recorded for future stages: **no mandatory route requires clearance below the 104 u standing body.** Since 2026-10-12 this is joined by the no-trap rule of [GAMEPLAY_RULES.md](GAMEPLAY_RULES.md) §6.1: no *reachable* space, mandatory or not, may have clearance between 60 u and 104 u. Treads and walkway slabs in this document are `solid` unless marked `one_way`; none is marked yet, so the level-data author decides and records each one, and one-way surfaces never count as ceilings. There is no crouch-walk (SPEC §4; GAMEPLAY_RULES §6 case 6), so a sub-104 u passage would be impassable; crouch is exercised against R1's projectile band and low swooper lanes instead. The under-bridge and under-platform spaces (128 u) are recovery/route spaces entered by falling or walking, never by crouching.

## 5. Encounter table

Behavior values are GAMEPLAY_RULES §8 (PROPOSED); placement is [P4 proposal]. All encounters reset on restart (GAMEPLAY_RULES §7).

| ID | Type (HP) | Position | Patrol / zone | Beat | Teaching / design role |
|---|---|---|---|---|---|
| E0 | Training effigy (non-hostile) [P4] | module 6, x 384–448 | static, whip height | B1 | Isolated first strike; no threat |
| P1 | Ground pursuer (1) | modules 16–18 | patrol x 1024–1216 | B1 | First real enemy, after the recoverable gap |
| P2 | Ground pursuer (1) | modules 22–26 | patrol x 1408–1728 | B2 | Spacing read, open court |
| P3 | Ground pursuer (1) | modules 28–32 | patrol x 1792–2112 | B2 | Second read, varied approach distance |
| P4 | Ground pursuer (1) | modules 36–38 | patrol x 2304–2496 | B2 | Gap-then-enemy combination; module 35 kept clear as touchdown strip |
| S1 | Airborne swooper (1) | above W2–W3 | patrol x ≈3136–3648 at +175–190 u over walkway | B3 | First airborne threat; stand-and-whip from ≥192 u landings |
| P5 | Ground pursuer (1) | modules 67–69 | patrol x 4288–4480 | B4 | Ground lane of the mixed encounter |
| R1 | Stationary ranged (2) | platform modules 71–72, top +2 | projectile lane overhangs ground modules 66–78 from platform level; over the ground route the shots pass 198–223 u up and cannot hit a ground hunter (§3), so the checkpoint apron (modules 63–66) stays safe | B4 | Crouch-dodge / elevated-route lesson; two readable routes (§3) |
| S2 | Airborne swooper (1) | above modules 74–78 | patrol x 4736–5056 at +175–190 u over ground | B4 | Airborne threat after the platform, not stacked on it |
| BOSS | Boss (8) | arena, spawn module 97 | arena modules 88–101 | B5 | Spacing + jump test; two attacks per GAMEPLAY_RULES §8.4 |

## 6. Safe zones, checkpoint, camera

- **Safe zones** (no enemy patrol, tell, or projectile lane reaches them): spawn plaza modules 0–7; B2 entry apron 20–21; walkway rest W1 (modules 45–47); checkpoint apron modules 63–66; pre-boss apron modules 83–86; exit vestibule after unlock. Module 35 is a one-module safe touchdown strip inside P4's beat.
- **Checkpoint:** module 64, inside its safe apron, before every B4/B5 threat. Before it is touched, respawn is the stage start (GAMEPLAY_RULES §7 / AUDIT B9).
- **Camera zones** [P4 proposal, within SPEC §6]: horizontal follow with bounded look-ahead elsewhere; vertical lock per encounter at the courtyard (modules 20–39, ground level), the walkway (modules 45–59, locked to walkway level so landings below stay visible), the mixed encounter (modules 66–78, ground level), and a hard lock to arena bounds (modules 88–101) during the boss fight. No zone hides a required landing (SPEC §6).

## 7. First-minute teach sequence (SPEC §3, mapped to geometry)

| Order | Lesson (SPEC) | Where | Failure cost |
|---|---|---|---|
| 1 | Safe movement space | Spawn plaza, modules 0–7 | none |
| 2 | Isolated whip target | Effigy E0, module 6 | none |
| 3 | Short recoverable gap | Module 8 (+ module 14) | 128 u fall, walk back, two 64 u steps |
| 4 | One ground enemy | P1, modules 16–18 | 1 health + knockback, inside a 320 u landing |
| 5 | Gap + enemy combined, safe landing | B2 pit gap module 34 → 320 u landing, P4 beyond module 35 | first lethal fall (pit) — flagged in §3 |

No off-screen first-hit attacks and no mandatory blind jumps anywhere in the stage: every gap is one module and visible from its takeoff edge at the 1280×720 logical view [P4 proposal — verify in greybox, V5–V7].

## 8. What remains open

- All placements, patrol bounds, the effigy, the pit in B2, and camera zones are [P4 proposal]s on PROPOSED baselines (D07–D11) — user confirmation or greybox evidence (VALIDATION V6/V7) settles them; nothing here is playtested.
- Exact enemy sizes/canvases and any new prop (effigy) enter the inventory in P3; visual identity of every encounter is P2's.
- The at-limit steps in §4 and the pre-checkpoint pit are the two known feel-risks to probe first in a greybox.

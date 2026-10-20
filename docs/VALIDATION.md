# Acceptance and review plan

No game or assets exist in this repository. All production tests below are **PENDING**. Document consistency checks can run now; playtest/performance evidence cannot.

The art gates are run with the tools in [tools/](../tools/README.md): `contract-check` (V0), `selftest` (must pass before any art is audited), `audit-art` and `review-pack` (V2, V3), and the independent reviewer of [prompts/ART_REVIEW.md](../prompts/ART_REVIEW.md) (V1, V3). Art production is autonomous (D21): a `REVIEW: PASS` from a fresh reviewer replaces human sign-off.

| Gate | Evidence required | Pass criterion |
|---|---|---|
| V0: specification | Cross-document review, decision ledger, valid examples and links; `node tools/contract-check.mjs`; `node tools/selftest.mjs` | Confirmed/proposed/open states distinguished; shared coordinates/timing agree; both tools PASS |
| V1: art calibration | Style pack, identity reference, logical-scale and phone-size scene review; independent reviewer verdict on the pack | One consistent treatment; hero/threats/terrain readable; no visible pixels; the reference itself passes ART_CONTRACT A-05/A-07/A-08 (a torso reference poisons every later size check) |
| V2: sprite technical | `node tools/audit-art.mjs --frames <root>`: audit.json / audit.md | 0 DEFECT. Every FLAG adjudicated in V3 |
| V3: animation | Review pack (`tools/review-pack.mjs`), independent reviewer verdict, engine frame-step test (every clip stepped through the real animation player: frame count, loop flag, atlas regions, trim offsets) and in-engine captures at phone size | `REVIEW: PASS` from a fresh reviewer; engine test PASS; all ANIMATION_SPEC states/transitions reachable (ART_CONTRACT A-15) |
| V4: terrain | Repeated patch and representative platforms with collision overlay | No seams; decorative features do not misrepresent collision; top edges align |
| V5: touch controls | Screen recording and observation on iPhone 17, iOS Safari (D14; TECHNICAL_SPEC §4) | Move+jump+whip works; controls recover from cancellation/focus loss; targets meet size requirement |
| V6: feel | At least three unfamiliar players, same short onboarding | At least two complete first mixed jump/whip encounter within three attempts without control confusion; record failures rather than rounding up |
| V7: stage | Complete playthrough, checkpoint/death/retry/boss/exit checks | No impossible mandatory jumps, off-screen unavoidable hits, stuck states, or inaccessible exit |
| V8: browser/performance | Exact device/browser/build IDs, network trace, frame samples | Meets agreed targets from technical spec; cold-load and warm-run evidence both supplied |
| V9: future APK | Later debug APK install and touch/resume test on device | Same bounded slice behavior; build prerequisites and version recorded |

V6 is an early diagnostic with a small sample, not statistical proof of broad usability. If it fails, adjust movement/encounter geometry before adding content.

## Rule-to-test traceability

Every gameplay rule has a test ID, and every test names the rule it proves. The first implementation passed 19 smoke checks while ordinary crouching never used the crouch body ([LESSONS.md](LESSONS.md) L13), because no test was tied to that rule. A rule with no test is not implemented, whatever the code says.

Minimum automated set (headless engine tests; each asserts on game state, not on screenshots):

| ID | Rule | Test |
|---|---|---|
| T-01 | GAMEPLAY_RULES §6.1 (3): crouch body on every entry | For each entry path (press, land with crouch held, air-attack landing), assert the active collision shape is 40×60 on the first crouch frame |
| T-02 | §6.1 (2): one-way surfaces are not ceilings | Crouch under a one-way slab 52 u above the floor, release; assert standing within 300 ms and `crouch_exit` played |
| T-03 | §6.1 (4): no-trap | For a grid of reachable positions (every 32 u along every surface), run crouch → release → move right 1.5 s, then move left 1.5 s, then jump; assert the hunter moved ≥ 64 u or left the spot by jumping |
| T-04 | §6.1 (5): jump envelope | Rise 128 u ±6%, apex 0.4 s ±6%, same-height travel 192 u ±6% |
| T-05 | SPEC §5: whip timeline | Hitbox inactive at 100 ms, active at 200 ms, inactive at 300 ms; each target hit once per attack |
| T-06 | GAMEPLAY_RULES §5: damage routing | Projectile → `hurt_recoil`; contact → `knockback`; boss strike → `knockdown` → `get_up`; lethal → `death` from every state |
| T-07 | GAMEPLAY_RULES §7: failure and retry | Pit → restart at the respawn point with 5 HP; checkpoint moves the respawn; boss defeat unlocks the exit |
| T-08 | GAMEPLAY_RULES §3: input hygiene | Opposing inputs → neutral; focus loss, pause and death clear held input |
| T-09 | ART_CONTRACT A-15: state coverage | Every hero/enemy/boss state maps to an existing clip, and every clip is played by some state |

A test is accepted only after it has been seen failing: break the rule on purpose (for example, count one-way surfaces as ceilings), run the test, watch it fail, then restore. Record that in the review record.

## Review adversarially

- If all detail is dark, can the player still distinguish an enemy from masonry at phone size?
- Does the art imply a safe platform where collision is absent?
- Does a stationary target get hit only once per attack, including across multiple active frames?
- Are an enemy's vulnerable regions reachable without agile jumps or stomp kills?
- Does a left-facing whip retain its correct origin, socket alignment, and reach?
- Can a player combine movement, jumping, and whipping with two thumbs, and separately crouch+whip? If the proposed button layout cannot support the combinations comfortably, revise layout/input semantics before adding gestures.
- Does a camera movement hide a landing or introduce a blind required jump?
- Does the visual contract fit the atlas/memory budget once every animation is counted?
- Does every supported state have meaningful authored animation, including crouch/stand, takeoff/apex/fall/landing, knockback/knockdown/get-up, and complete death?
- Do death, restart, focus loss, touch cancellation, and resize clear input and combat state?

## Handoff evidence format

Record gate ID, revision/build, method, device/tool details, expected result, observed result, evidence path, verdict (PASS/FAIL/NOT-TESTED), and corrective action. Never replace missing measurements with “should work.”

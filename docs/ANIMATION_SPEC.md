# Full character animation contract

**Confirmed requirement:** The character must be fully animated for every supported action and pose. A static graphic sliding, rotating, bouncing, or being tinted around the level does not satisfy this requirement. “Crunch” is interpreted as crouch; “knock off” as knockback/knockdown. Counts/timings below are **proposed production targets**; the coverage requirement itself is confirmed.

## Meaning of complete

Every state needs intentional silhouette, weight, anticipation/action/recovery where applicable, and readable transitions. A final death pose may hold after the full death sequence; a loop may repeat intentionally. This does not require every limb to move on every frame, but long-lived living states must not be frozen substitutes for animation. Full animation does not imply adding gameplay actions outside the bounded scope.

Use non-pixel illustrated frames or an explicitly reviewed 2D skeletal/cutout technique that achieves convincing articulated body motion and retains illustration quality. Translating an unarticulated cutout fails. Raster clips are the proposed delivery baseline. If rigging is chosen later, revise the export/manifest contract and demonstrate an equivalent complete state set; do not silently mix incompatible pipelines.

## Hero coverage — proposed frame budget

Frames are unique authored pose targets, not repeated copies to inflate counts. Additional in-betweens are allowed when justified. Raster frame timing can vary; never stretch animation to hide input lag.

| State / clip | Proposed frames | Behavior and transition |
|---|---:|---|
| idle | 8 | Subtle breathing, cloth/hair settling; 125 ms/frame loop |
| walk | 10 | Weight transfer, heel/toe contacts, arm/torso counter-motion; 80 ms/frame loop; tune playback to travel speed |
| start_move | 3 | 50 ms/frame visual push-off; motion begins immediately |
| stop_move | 3 | 50 ms/frame settling; new input can interrupt |
| turn | 3 | 50 ms/frame weight shift; mirror/facing change has explicit event, never sweep a live hitbox through the rear |
| crouch_enter | 4 | 50 ms/frame bend into low stance; meaningful joint motion |
| crouch_idle | 6 | 150 ms/frame breathing/cloth loop; stationary feet |
| crouch_exit | 4 | 50 ms/frame stand; plays only when standing clearance exists |
| jump_takeoff | 3 | 40 ms/frame push-off; velocity applied immediately, not after clip finishes |
| jump_rise | 4 | 60 ms/frame rising body/limb/cloth motion |
| jump_apex | 3 | 50 ms/frame weight transition; driven by vertical motion region |
| fall | 4 | 100 ms/frame loop for longer falls; never adds world translation |
| land | 4 | 40 ms/frame compression and recovery; jump/attack can interrupt |
| attack_ground | 8 | 500 ms total, exact phase timing from ASSET_SPEC.md |
| attack_air | 8 | Same timing; distinct airborne body/leg animation |
| attack_crouch | 8 | Same timing; distinct low stance and lowered whip socket |
| hurt_recoil | 4 | 50 ms/frame hit reaction; outgoing attack disabled immediately |
| knockback | 4 | 75 ms/frame body/cloth reaction while physically displaced; terminal fall routes to fall state |
| knockdown | 6 | 60 ms/frame heavy-impact fall and body-ground contact |
| get_up | 6 | 75 ms/frame recovery; preserves physical foot/ground alignment |
| death | 10 | 80 ms/frame full collapse/settle; lethal airborne impact waits for contact before final grounded collapse |
| whip_ground / air / crouch | 8 each | Separate synchronized weapon layer; no blank frame during active phase |

Hero-body target is 113 frame images, plus 24 weapon frames (137 total). This is a budgeting proposal, not proof of production readiness. Inventory changes must update this total and atlas estimate.

At 512×512 RGBA8, the untrimmed 113 body canvases alone occupy 113 MiB; the 24 untrimmed 768×512 whip canvases add 36 MiB. Therefore full untrimmed residency would exceed the proposed 128 MiB whole-slice texture budget before any environment/enemy art. The production pipeline must trim/pack while retaining pivots, load only necessary pages, or propose a validated alternate animation/density budget. Do not solve this by removing required action coverage. Reconcile actual packed occupancy in P3/P5 before production.

## Timeline and interruption rules

Logical state determines physical motion. Visual transitions must not block valid control inputs except for the explicitly designed attack/recovery commitments. An interrupted clip is still required and must be complete when it plays normally. Do not demand every clip finish before responding to input.

Priority: lethal damage → nonlethal damage/knockdown → existing committed attack or heavy recovery → airborne movement → crouch → grounded movement/idle. The next gameplay-spec task must formalize all event combinations rather than infer them from animation order.

- Landing during an airborne attack preserves its elapsed combat time and one-hit-per-target ID; transition the lower body or select the corresponding grounded pose without restarting the active window.
- Stepping off a ledge enters fall without a takeoff clip. Jump ascent/apex/fall timing follows velocity; reconcile proposed frame durations with the final motion curve rather than delaying gravity to play a pose.
- A ceiling collision ends ascent and transitions toward fall; no cycling the jump animation from the start.
- Crouch uses a proposed 40×60-unit body centered at (0,-30), preserving the foot origin. Restore standing collision only after clearance. No shrinking the artwork or moving the origin downward.
- Low attacks use a separate socket/hitbox. Crouch cannot be exited into an obstruction. No crouch-walk in the initial scope.
- Damage interrupts a strike immediately. Knockback displacement is physical motion, supplemented by articulated animation. Heavy hits may transition to knockdown/get-up; ordinary damage must not force that sequence every time.
- Lethal damage cannot enter get-up. Pit falls show falling and a death transition before retry; do not require a ground-collapse animation on a nonexistent floor.
- Death completion may hold a final pose. Restart resets animation/combat/input state.
- Idle, walk, and crouch loops must join cleanly without identity or scale jumps. A turn is intentional motion, not arbitrary frame-by-frame mirroring.

## Enemies and boss

Every on-screen creature has complete locomotion/idle, attack anticipation, execution, recovery, hurt reaction, and death animations appropriate to its behavior. Flying enemies articulate flight; they do not float as static drawings. A stationary enemy still animates breathing, aiming, attacking, and reacting. The boss requires separately readable full sequences for both attacks and a complete death. Exact counts belong in individual briefs.

## Required proof of completeness

Measured acceptance for every clip is [ART_CONTRACT.md](ART_CONTRACT.md): pose classes, per-frame size and anatomy rules, whip and effect rules, the review pack and the independent reviewer. The crouch design height is 140 px (0.625 × standing, ART_CONTRACT §2). The proof items below are produced by `tools/review-pack.mjs` plus engine captures.

Provide a state inventory mapping each gameplay action to clip IDs and all transition paths, a timed reel of every clip, actual-scale composite body+weapon previews, and a future in-engine recording showing each action triggered. Mark missing evidence NOT-TESTED. Review smoothness at intended playback speed and at phone display size, not just as thumbnails.

Reject static-picture motion; missing crouch/stand or takeoff/landing coverage; one generic pose for jump/fall/hurt; costume drift; collapsing anatomy; disconnected whip; skating feet; knockback implemented only by translation; instantaneous death disappearance; and complete clips that the actual state machine can never play.

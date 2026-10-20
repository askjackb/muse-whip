# Art bible — Package P2

**Status: PROPOSED calibration targets.** The constraints this bible implements are confirmed — gothic dark horror (D04), no visible pixels (D05), Castlevania as design reference for tone/mechanics (D06), horror line of dread/decay/silhouettes with **no explicit gore** (D13, user-confirmed 2026-10-08), full animation coverage (D18), original hunter in an original world (D02/D12 as amended 2026-10-08). Every palette value, proportion, costume element, and creature design below is a **proposal to be calibrated by the style pack (§8)** — none of it is user-confirmed, and no image has been generated. This document narrows [ART_DIRECTION.md](ART_DIRECTION.md) into rules another asset worker can execute without guessing; where the two disagree, ART_DIRECTION's confirmed constraints win and this bible is wrong.

Technical anchors (ASSET_SPEC.md, PROPOSED): 1280×720 logical units, 2 source px per game unit, hero standing 112 u (224 source px) on a 512×512 canvas, foot pivot (256, 448). Sizes below are initial proposals for P3 to finalize per brief.

## 1. Named palette

Hexes are [P2 proposal]s derived from ART_DIRECTION's palette *roles*. "Budget" = where the color may appear; scarcity is a rule, not a suggestion.

| Swatch | Hex | ART_DIRECTION role | Budget / use | Forbidden |
|---|---|---|---|---|
| Abyss Violet | `#171221` | near-black violet recesses | Deep shadow, void, unlit interior | Large flat fills on the play plane |
| Crypt Violet | `#2A2138` | near-black violet recesses | Shadow-side masonry, recess shading | Enemy silhouettes (reads as background) |
| Cold Slate | `#4C5866` | cold slate stone | Primary masonry mid-tone, terrain body | Hunter costume (must separate from stone) |
| Slate Edge | `#77838F` | cold slate stone | Stone highlights, worn edges, distant iron | Broad highlight fields |
| Drowned Teal | `#2F4F4E` | desaturated blue-green distance | Distant silhouettes, deep background | Play-plane threats |
| Mist Teal | `#64807C` | desaturated blue-green distance | Fog tint, far midground light | Attack tells, landing edges |
| Bone | `#CFC4A5` | restrained bone highlights | Hunter face/hands light, carving highlights, damage flash tint | Whole-costume fields |
| Old Bone | `#9C9077` | restrained bone highlights | Weathered bone, parchment, dim trim | Text-like patterning |
| Ember Ochre | `#C07F2E` | scarce ember/ochre for interactables | Checkpoint, exit, interactable accents — the only warm signal color | Decoration, enemy bodies |
| Ember Bright | `#E3A34A` | scarce ember/ochre | Active-state interactables, boss hazard telegraph ring | Ambient lighting fill |
| Grave Phosphor | `#8CC084` | (enemy projectile contrast, ART_DIRECTION light rules) | Enemy projectiles and the ranged threat's charge cue — always paired with a distinct shape | Interactables, hunter effects |
| Hunter Umber | `#5C4630` | (hunter materials) | Hunter leather mid-tone | Terrain (separation) |
| Dark Leather | `#3B2D20` | (hunter materials) | Hunter leather shadow, whip braid dark strand | Background shadow (use Abyss/Crypt) |
| Hunter Steel | `#8B959E` | (hunter materials) | Hunter metal: buckles, bracer plates, whip tip | Stone highlights (use Slate Edge) |
| Pallid Flesh | `#A9A491` | (enemy identity) | Enemy skin/flesh light | Hunter skin (use Bone-warmed tones) |
| Decay Green | `#5F6B45` | (enemy identity) | Enemy decay accents, moss, corpse-cloth | Interactables, projectiles |
| Ash Grey | `#6E6A61` | (death treatment, D13) | Ash-dissolution death particles, dead vegetation | UI emphasis |

Rules: (a) the play plane is read by value contrast first — threats and the hunter must separate from masonry in grayscale before color is considered; (b) Ember Ochre/Bright together may cover only interactables and telegraphs — if everything warm is important, nothing is; (c) Grave Phosphor never appears without its projectile/telegraph shape, so color-blind players still read the threat; (d) no swatch outside this table enters production art without a bible amendment recorded in [REVIEW_RECORD.md](REVIEW_RECORD.md).

## 2. Silhouette, material, and light rules

**Silhouette first.** Every character reads as a dark, closed shape against the scene at phone size before any interior detail is judged. The hunter is the only upright, clean-limbed human silhouette; enemies break that read in one obvious way each (low quadruped, winged, rooted, oversized). Terrain's walkable top edge is a continuous light-valued line (Slate Edge / Old Bone wear) against darker body stone — collision is visible, never guessed.

**Materials.** Painted, matte, non-photoreal. Hunter: worn leather (Umber/Dark Leather, edge wear in Old Bone), undyed linen, small steel pieces (Hunter Steel) — no chrome, no glow. Stone: Cold Slate with violet shadow (Crypt Violet) and teal distance shift. Metal in the world is corroded: Slate Edge highlights over Drowned Teal oxidation. Cloth and hair move in animation (ANIMATION_SPEC); material reads must survive that motion — no detail smaller than ~4 source px on animated parts.

**Light.** One broad upper-left form light, baked into illustrations (ART_DIRECTION). Soft occlusion, no cast floor shadows in sprites, no one-sided shadow so strong that mirroring looks wrong. Scene lighting may deepen mood but a threat must be identifiable with scene lights removed. Fog (Mist Teal, low alpha) lives behind the play plane and in distant layers only; it never crosses a landing edge or an attack tell.

**Depth stack (back → front):** sky/void gradient → distant silhouettes (Drowned Teal, low contrast) → midground architecture (Cold Slate, violet shadow) → **play plane** (full contrast, the only layer with Ember/Grave Phosphor signals) → sparse foreground framing (Abyss Violet, edges of frame only, never over a landing zone or tell).

## 3. The hunter — original design brief

An original character. Any resemblance to a franchise costume, crest, weapon name, or world element is a rejection reason (§9). Castlevania informs tone — whip-led combat, gothic dread — never the drawing.

- **Silhouette:** upright hunter, 112 u standing. Long coat skirts below the knee give the cloth mass that idle/walk/crouch loops animate; a single shoulder mantle adds an asymmetric read that survives mirroring; hair is a dark, tied-back mass with a readable outline against stone. Crouch must read as a deliberate coil (lowered hips, coat pooled), never a squashed resize (ANIMATION_SPEC).
- **Face/hair:** face lit in warm Bone tones, strong brow/cheek planes, features legible at phone size without line-art dependence. Hair near-black with Dark Leather warmth in the light; no anime spikes, no helmet (the head silhouette must stay human and distinct from every enemy).
- **Costume construction (original):** undyed linen shirt; a leather cuirass vest in Hunter Umber tooled with an original **thorn-knot** motif (interlaced thorn stems — explicitly *not* a cross, crest, or heraldic device); Dark Leather belt, bracers with small Hunter Steel plates; coat in desaturated umber-grey, worn hems; knee boots. Armor count and seams are fixed once the style pack locks — frame-to-frame drift in buckles, plates, or motif is a rejection (ANIMATION_SPEC).
- **The whip (original construction):** oak grip with two iron rings; a braided leather fall in alternating Umber/Dark Leather strands; a steel-weighted tip (Hunter Steel). Coiled at the left hip at rest; in attack frames it must read as one continuous flexible line from hand socket to tip, extending to the 168 u hitbox reach at full extension (SPEC §5 overlay review governs). It is a tool, not an energy weapon: no glow, no trail baked into frames.
- **Damage/death read:** invulnerability uses a non-strobing Bone-white tint (SPEC §5); death is a full collapse and settle (ANIMATION_SPEC), ashen and quiet per D13 — no blood, no wounds rendered.

## 4. Enemy and boss visual briefs

Each brief serves the behavior and tells in GAMEPLAY_RULES §8; the tell is a *silhouette event*, readable before color or sound.

- **Ground pursuer (1 HP):** a gaunt, stooped quadruped — Pallid Flesh over Decay Green cloth-like hide, spine and ribs suggested by shading, never opened (D13). ~56 u tall at the shoulder [P2 proposal, from P1's clearance math]. The `alert` rear-up is the key pose: front limbs lift, head high — a vertical silhouette spike the player learns to whip into. Lunge stretches the body long and low; recovery slumps it. Never reads as a dog or pet: proportions are wrong on purpose — forelimbs too long, head hung too low.
- **Airborne swooper (1 HP):** ash-grey membrane wings (Ash Grey over Crypt Violet shadow) on a small, shrouded body; wing articulation is the animation (ANIMATION_SPEC forbids floating drawings). The dive telegraph is a **fold**: wings snap shut, silhouette goes from wide cross to narrow dart for the full 600 ms tell. Cruise silhouette is broad and slow-beating; dive recovery climbs with visibly laboring strokes.
- **Stationary ranged threat (2 HP):** a hooded figure bound upright to a funerary post — rooted, swaying slightly (breathing/aim sway; stationary is not static). It raises one long arm to aim; a Grave Phosphor charge gathers at the hand across the 900 ms aim, brightening with the shape cue (a growing diamond halo, so the tell survives color-blindness). The projectile is a phosphor diamond, never a sphere or bullet. The figure's face is shadowed by the hood — dread by concealment (D13), not by wounds.
- **Boss (8 HP):** a tall revenant warden, ~176 u [P2 proposal], in corroded ceremonial plate (Cold Slate iron, Slate Edge corrosion) over a shrouded frame. One oversized striking arm makes the 700 ms wind-up unmistakable: the arm rises and *holds*, silhouette changing by a third, before the strike. The ground hazard telegraph is an Ember Bright cracked ring on the floor (the stage's only floor-level warm signal). Hurt flinch is small and brief; death is a complete sequence — the plate settles, the shroud collapses, and the form gutters into ash (Ash Grey) and shadow. No gore at any point.

## 5. Environment kit rules

Kit pieces per ASSET_SPEC §4 (caps, sides, fill, corners, platform ends/middle), all Cold Slate masonry with funerary carving in an original vocabulary: blind pointed arches, thorn-knot friezes (shared with the hunter's tooling — the world and the hunter belong to each other), shrouded statues, sealed tombs. No crosses-as-set-dressing, no readable text, no franchise iconography.

- Walkable top edges sit exactly on the module boundary with the light wear line of §2; decorative cracks stay off the top edge so detail never impersonates collision.
- Dead vegetation (Ash Grey) and corroded iron (teal-oxidized) dress quiet areas; density thins near tells, landings, and the whip lane.
- One kit serves the whole stage (SPEC §3): the ruined walkway reuses court masonry with broken variants, not a second material family.
- Backgrounds declare tiling/seam axis per ASSET_SPEC §4; foreground framing is sparse and frame-edge only.

## 6. Horror treatment — the D13 line, made enforceable

Confirmed line (user, 2026-10-08): dread, decay, silhouettes; **no explicit gore**, nothing heavier. For asset review, "explicit gore" means any of: exposed organs, muscle, or bone-as-wound; blood pools, spatter, dripping, or blood effects on hits/deaths; dismemberment or severed parts; corpses rendered as detailed bodies (faces, wounds, contortion). **Permitted:** shrouded and hooded forms; silhouettes of the dead in scenery; bone as clean set dressing (detached, unfleshed, non-graphic); decay as texture — rot-stain, moss, ash, corrosion; deaths that collapse, settle, or dissolve into ash/shadow; dread built from sound-quiet, stillness, and scale once audio exists. A candidate that needs a judgment call is REJECTED and the bible is amended — reviewers do not relitigate taste per asset (DECISIONS.md, D13 evidence note).

## 7. Reject (visual)

Carried from ART_DIRECTION and extended: photorealistic backgrounds mixed with illustrated figures; chibi proportions; decorative detail resembling a hazard; frame-to-frame changes in face, costume, limb length, or weapon; arbitrary bloom; visual noise along collision edges; baked UI/text; isometric perspective; fog hiding enemies; bright whimsical scenery; **plus:** any franchise-derived character, costume, crest, name, or architecture; blood or gore per §6; a whip that reads as energy/magic; enemies that read as animals/pets rather than wrong things; ember used as decoration.

## 8. Style-pack calibration plan (briefs, not images)

ART_DIRECTION requires exactly five calibration pieces before any production batch. The five briefs below follow [templates/ASSET_BRIEF.md](../templates/ASSET_BRIEF.md). All are **Status: DRAFT** — per the template, nothing may be marked READY while style and critical references remain unknown; approving these five *creates* the reference. Common terms for all five: density 2 source px per game unit; RGBA PNG, real transparent alpha (sprites) or declared opaque (mockup/terrain), sRGB, linear-filter-friendly edges, no baked text/UI/floor shadows; facing right where applicable; palette restricted to §1; light upper-left; provenance recorded (creator/tool/model/seed where exposed — unknown stays unknown, per ASSET_SPEC §6). Review for every piece: full logical view (1280×720), phone-size downscale, grayscale separation check, and the §7 reject list; verdicts recorded in REVIEW_RECORD format. After approval, the pack is registered in §9 with a style-lock revision ID (first: `style_lock_r01` [P2 proposal]) and becomes the canonical reference every P3 brief points to.

### Brief 1 — `style_hero_neutral` (hero neutral pose)

- **Purpose and gameplay state:** canonical hunter identity reference; the pose `idle` frame 0 derives from. Proves silhouette, costume, face/hair, palette at contract scale.
- **Confirmed vs proposed:** confirmed — original hunter (D02 amended), no pixels (D05), full-animation identity stability (D18). Proposed — every design element of §3.
- **Dependencies and unresolved decisions:** none blocking; D09 (stomp) does not affect this piece.
- **Canonical identity reference and style-lock revision:** this brief *creates* the identity reference; style_lock to be assigned on approval.
- **Silhouette, materials, palette, lighting, perspective:** §3 in full; side view, standing at rest, whip coiled at left hip; upper-left light.
- **Canvas; logical size; density:** 512×512 source px; figure 112 u (224 px) standing; 2 px/u.
- **Pivot and origin; facing:** foot pivot (256, 448); facing right; mirror must remain plausible (mantle asymmetry checked in the mirrored review).
- **Animation states, frames, durations:** single held pose; 1 frame; no loop.
- **Sockets:** hand socket marked on an overlay copy (not baked into the art): right hand at grip.
- **Collision/hitbox reference:** standing body 40×104 centered (0, −52) (ASSET_SPEC §2) shown as overlay only.
- **Alpha/format/atlas:** transparent alpha; not atlased (reference).
- **Reference inputs with provenance:** none external — original design from §3 text; record creator/tool/prompt in the manifest.
- **Exact generation/edit prompt and exclusions:** adapt the master prompt in [prompts/ASSET_GENERATION.md](../prompts/ASSET_GENERATION.md) with asset_id `style_hero_neutral`, pose "standing neutral, weight even, whip coiled at hip," plus exclusions: no franchise costume/crest/weapon, no glow, no text, no floor shadow, no gore.
- **Files expected and naming:** `art/candidates/style_hero_neutral__r01__f000.png` + overlay preview.
- **Preview requirements:** contact sheet single frame, actual-scale scene placement (against §5 masonry swatches), phone-size and grayscale checks.
- **Rejection criteria:** §7 list; face unreadable at phone size; costume separable into franchise references; silhouette merges with Cold Slate in grayscale.
- **Review result:** PENDING — no candidate exists. NOT-TESTED.

### Brief 2 — `style_hero_attack_key` (attack key pose)

- **Purpose and gameplay state:** the full-extension active-phase key pose of `attack_ground` (SPEC §5 active interval [150, 250) ms), body layer only, proving shoulder/hip rotation and the hand socket the separate whip layer must meet.
- **Confirmed vs proposed:** confirmed — whip timing/hitbox (SPEC §5), layered body/whip construction (ASSET_SPEC §2). Proposed — pose acting.
- **Dependencies:** Brief 1 approved (identity lock) — or generated in the same session against the same reference and reviewed only after Brief 1, per ASSET_GENERATION workflow step 3.
- **Identity/style-lock:** Brief 1's reference; same style_lock revision.
- **Silhouette/materials/lighting:** §3; planted rear foot, striking arm extended, head and chest open toward target; coat cloth trailing the rotation.
- **Canvas/density:** 512×512; 2 px/u; figure remains 224 px standing-height anatomy (extended pose within canvas).
- **Pivot/facing:** foot pivot (256, 448); facing right.
- **Frames/durations:** 1 key frame (the pose ASSET_SPEC §3 frames 2–3 must hit).
- **Sockets:** hand socket coordinates recorded in game units relative to foot origin on the overlay; whip root must meet it (ASSET_SPEC §2).
- **Collision/hitbox:** active region x +40..+168, y −82..−46 (SPEC §5) drawn as overlay; the extended hand/whip line must visually cover it.
- **Alpha/format:** transparent alpha PNG.
- **References/provenance:** Brief 1 reference image (path recorded); tool/model/seed where exposed.
- **Prompt/exclusions:** master prompt with pose "ground whip strike, full extension, active phase"; exclude the whip itself (separate layer), exclude ground plane and text.
- **Files:** `art/candidates/style_hero_attack_key__r01__f000.png` + socket/hitbox overlay preview.
- **Previews:** composite test with a schematic whip line from socket through the hitbox; actual-scale and phone-size reads.
- **Rejection:** socket outside the hitbox overlay's plausible whip arc; anatomy drift from Brief 1; whip-ready hand occluded.
- **Review result:** PENDING. NOT-TESTED.

### Brief 3 — `style_enemy_pursuer` (one enemy)

- **Purpose and gameplay state:** canonical pursuer reference (GAMEPLAY_RULES §8.1) in its `alert` rear-up pose — the tell silhouette every later pursuer frame must preserve.
- **Confirmed vs proposed:** confirmed — complete enemy animation coverage (D18/ANIMATION_SPEC), D13 line. Proposed — creature design (§4), size ~56 u shoulder height.
- **Dependencies:** none blocking; final canvas deferred to P3.
- **Identity/style-lock:** creates the pursuer identity reference under the pack's style_lock.
- **Silhouette/materials/lighting:** §4 — low quadruped, forelimbs too long, head low; Pallid Flesh/Decay Green; upper-left light.
- **Canvas/density:** [P2 proposal] 320×192 source px (≈160×96 u) at 2 px/u, formalized in P3.
- **Pivot/facing:** ground foot pivot centered under the body (P3 fixes coordinates); facing right.
- **Frames/durations:** 1 key frame (alert pose).
- **Sockets:** contact body reference — collision proposal deferred to P3/GAMEPLAY_RULES §5 (contact is a body overlap rule).
- **Collision/hitbox:** overlay of the proposed contact body at the alert pose.
- **Alpha/format:** transparent alpha PNG.
- **References/provenance:** §4 text only; original creature, no external reference imagery required; record generation inputs.
- **Prompt/exclusions:** master prompt adapted; exclude pet-like cuteness, gore/wounds, text, floor shadow.
- **Files:** `art/candidates/style_enemy_pursuer__r01__f000.png` + overlay.
- **Previews:** beside the hunter at contract scale (scale relationship is a review item); grayscale separation vs masonry.
- **Rejection:** reads as a natural animal; tell pose not silhouetted distinctly from patrol read (described, since only one pose exists in the pack); D13 violation.
- **Review result:** PENDING. NOT-TESTED.

### Brief 4 — `style_terrain_patch_3x3` (3×3 terrain patch)

- **Purpose and gameplay state:** proves the masonry kit tiles seamlessly with a readable walkable edge (ART_DIRECTION calibration; ASSET_SPEC §4's repeated-patch inspection).
- **Confirmed vs proposed:** confirmed — one kit for the stage (SPEC §3), collision honesty (ASSET_SPEC §4). Proposed — carving vocabulary (§5).
- **Dependencies:** none.
- **Identity/style-lock:** establishes the terrain material reference under the pack's style_lock.
- **Silhouette/materials/lighting:** Cold Slate body, Slate Edge wear line on top edges, Crypt Violet shadow; thorn-knot frieze on one tile only (density rule §5); side view, orthographic.
- **Canvas/density:** 3×3 modules = 384×384 source px (each module 128×128 = 64 u at 2 px/u).
- **Pivot/origin:** module grid origin at patch top-left; walkable top edges exactly on module boundaries.
- **Frames/durations:** static; 1 image, tileable horizontally by construction.
- **Sockets:** none.
- **Collision reference:** top edges = collision line; overlay showing the 64 u grid and which edges are walkable.
- **Alpha/format:** opaque PNG (terrain body), sRGB.
- **References/provenance:** §5 text; original carving motifs.
- **Prompt/exclusions:** terrain prompt extension in ASSET_GENERATION.md; exclude ornaments that cross the top edge, seam lighting gradients, text.
- **Files:** `art/candidates/style_terrain_patch_3x3__r01__f000.png` + grid overlay.
- **Previews:** the patch tiled 3-wide (9 modules) seam check; grayscale edge read.
- **Rejection:** visible seams; top-edge line broken by decoration; carving reads as franchise architecture.
- **Review result:** PENDING. NOT-TESTED.

### Brief 5 — `style_env_mockup` (layered environment mockup)

- **Purpose and gameplay state:** one layered scene at the logical gameplay view (ART_DIRECTION calibration): sky → distant silhouettes → midground architecture → play plane with the hunter at contract scale → foreground framing, proving depth, fog placement, and readability together.
- **Confirmed vs proposed:** confirmed — depth grammar and readability (D04, ART_DIRECTION), no pixels (D05). Proposed — composition and palette application.
- **Dependencies:** Briefs 1 and 4 (or same-session references reviewed in order).
- **Identity/style-lock:** consumes Briefs 1/4 references; approval locks the scene treatment under the same style_lock.
- **Silhouette/materials/lighting:** §2 depth stack; hunter placed on a masonry platform; one Ember Ochre interactable accent (checkpoint-like) to prove scarcity; no enemies (threat readability is judged in production scenes, not the mockup).
- **Canvas/density:** 2560×1440 source px (1280×720 u at 2 px/u), one composed image with layers kept separable in the source file [P2 proposal: layered source retained].
- **Pivot/origin:** view origin top-left; hunter foot on the platform's module boundary.
- **Frames/durations:** static; 1 image.
- **Sockets:** none. **Collision reference:** platform top edge overlay at module boundary.
- **Alpha/format:** opaque PNG composite; layer files retained as source.
- **References/provenance:** Briefs 1/4 outputs + §2 rules; record all inputs.
- **Prompt/exclusions:** master prompt adapted to a scene; exclude text/UI, fog over the platform, foreground over the hunter.
- **Files:** `art/candidates/style_env_mockup__r01__f000.png` + layer sources.
- **Previews:** full logical view; phone-size downscale; grayscale check that hunter and platform edge survive.
- **Rejection:** hunter merges with background at phone size; fog touches the play plane; ember accent not the single warm read.
- **Review result:** PENDING. NOT-TESTED.

## 9. Reference register and style-lock process

On pack approval, register here (empty until then): style-lock revision ID; the five approved file paths + hashes; creator/tool/model/version and prompt records (unknown values recorded as unknown, never invented); approval date and reviewer; the DECISIONS/REVIEW_RECORD entry that accepted it. Every P3 brief then cites `style_lock` and the relevant reference path, per the manifest contract (ASSET_SPEC §6). Any later style change requires a new style-lock revision and re-review of derived assets; silent drift is what ANIMATION_SPEC's rejection list exists to catch.

| Field | Value |
|---|---|
| Style-lock revision | — (pending pack approval) |
| Approved references | — |
| Reviewer / date | — |
| Evidence | — (VALIDATION V1 PENDING) |

## 10. What remains open

- The pack itself: no candidate art exists; V1 (art calibration) is PENDING and gates all production art.
- Final enemy/boss sizes, canvases, and frame counts are P3's; background panel dimensions are settled in P3's budget reconciliation ([TEXTURE_BUDGET.md](TEXTURE_BUDGET.md)).
- Everything visual here is PROPOSED except the confirmed constraints named in the header; user confirmation of the *designs* happens at pack review, not before.

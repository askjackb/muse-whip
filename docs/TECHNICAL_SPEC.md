# Technical / export specification — Package P5

**Status: PROPOSED implementation direction; NOT-TESTED throughout.** No Godot project exists. Confirmed inputs: 2D Godot web-first with later Android APK (D01), target device **iPhone 17 / iOS Safari, must-support** (D14, user-confirmed 2026-10-08), APK deferred (D16). Everything else here — including the version pin — is a proposal for the future implementation assignment to adopt or revise. This document re-anchors the performance hypotheses of [TECHNICAL_CONSTRAINTS.md](TECHNICAL_CONSTRAINTS.md): that file's "agreed mid-range Android phone" anchor is superseded by §5 below (AUDIT B4) and is left unedited as history.

## 1. Engine pin and baseline choices

| Item | Proposed pin | Basis |
|---|---|---|
| Engine | **Godot 4.7.2-stable** (editor + matching 4.7.2 export templates — versions must match exactly) | Current stable at godotengine.org's official download archive (`/download/archive/4.7.2-stable/`), verified by direct fetch on **2026-10-08**. Godot 4.8 exists only as development snapshots and is excluded. If implementation starts after a newer stable ships, re-pin deliberately and record why — never drift silently. |
| Language | GDScript (standard build, not .NET) | D10 (proposed); Godot 4 does not support C# web exports (official web-export documentation, linked from TECHNICAL_CONSTRAINTS) |
| Renderer | Compatibility | The web rendering path (WebGL 2.0); also the lowest-end mobile path, matching the 2D painted art and the no-volumetrics rule |
| Web threads | **Single-threaded export** (thread support off) | Threaded web builds require cross-origin isolation (COOP/COEP response headers and SharedArrayBuffer). The single-threaded baseline runs on any static host — including hosts that cannot set custom headers — and is the conservative choice for iOS Safari. This is a baseline to verify on device (§4), not a claim that threaded Safari builds can never work. |
| Viewport / stretch | 1280×720 logical; stretch mode `canvas_items`, aspect `keep` | SPEC §6: proportional scaling with letterboxing; SPEC §4's geometry is authored in these units |

Recheck rule (from TECHNICAL_CONSTRAINTS): all engine-behavior statements get re-verified against the pinned 4.7.2 documentation at implementation start.

## 2. Proposed scene / input / data boundaries

Implements TECHNICAL_CONSTRAINTS' responsibility split. Names are [P5 proposal]s; the boundaries are the contract, not the names.

- **Input layer** — one input-map action set (`move_left`, `move_right`, `jump`, `whip`, `crouch`, `pause`) fed by both touch buttons (Control nodes) and keyboard (SPEC §4 mappings). It exposes held/pressed state, resolves opposing directions to neutral, and clears all held input on focus loss, touch cancellation, or pause (SPEC §4/§6; GAMEPLAY_RULES §3). Gameplay never reads raw device input, so the later APK needs no separate logic.
- **Player** — a `CharacterBody2D` hunter whose state machine implements GAMEPLAY_RULES §4's table and §2's interruption priority exactly; motion constants (240 u/s, 1600 u/s², −640 u/s, 100 ms coyote/buffer) live in one exported data resource so tuning never touches code paths. Collision shapes come from ASSET_SPEC §2 bodies, never from sprite pixels.
- **Combat** — owns attack timelines and the per-attack hit-ID registry (one hit per target per attack, persisting across the air→ground continuation, GAMEPLAY_RULES §2/§5), hitbox data from SPEC §5, damage routing and the invulnerability window. Animation reports timeline events (`facing_flip`, `projectile_spawn`, `zone_lock`, etc., as defined in ASSET_BRIEFS.md); gameplay never infers events from art.
- **Animation** — observes logical state and plays the ASSET_BRIEFS clips; velocity-region clips (rise/apex/fall) are selected by the GAMEPLAY_RULES §4 thresholds, not by timers. Body and whip layers stay separate with the recorded hand socket (ASSET_SPEC §2).
- **Level data** — the stage is data: terrain module placements, encounter table, checkpoint, camera zones, and respawn points from STAGE_DESIGN.md, authored once and consumed by both collision and presentation. Swapping an encounter set at the boss gate is a data/loading operation (see §3 residency), not a scene edit.
- **Presentation** — camera (follow + the STAGE_DESIGN lock zones), HUD (health pips, touch buttons, checkpoint/retry/exit UI from ASSET_BRIEFS §10, all live text), VFX, and audio (separate music/SFX buses with independent volume controls and reduced-effects option, SPEC §6). Pause on focus loss with explicit resume; portrait shows the rotate prompt over a paused game.
- **Asset loading** — approved art arrives as per-class texture resources grouped by the residency sets of TEXTURE_BUDGET.md (core / small-enemy / boss). Import settings: linear filtering, sRGB, lossless; mip generation **off only if** the TEXTURE_BUDGET §5 amendment is ratified (until then the budget question stays open — the import setting and the budget are the same decision). Trim/pivot metadata from the manifests (ASSET_BRIEFS §1) is preserved through packing.

## 3. Web export checklist (baseline: single-threaded)

For the future implementation assignment; each item is checked off with evidence, not assumed.

1. Install the 4.7.2 export templates matching the editor build; record both version strings in the build record.
2. Web export preset: Compatibility renderer, GDScript (standard) build, thread support **off**, viewport/stretch per §1.
3. Serve from any static host (single-threaded needs no special headers). If a threaded build is ever proposed instead, the host must send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` — hosts that cannot set response headers rule that variant out; that is a hosting decision to record, not a default.
4. Tap-to-start screen before any audio (browser autoplay policy); audio starts only from that gesture (TECHNICAL_CONSTRAINTS).
5. Focus/visibility handling: pause + input-clear on blur/hidden; explicit resume control; verify behavior in the browser rather than trusting orientation-lock APIs (SPEC §6).
6. Layout: HUD respects device safe-area insets; touch targets ≥64 CSS px after scaling (SPEC §6); portrait → rotate prompt + accessible pause.
7. Record the exported file inventory and sizes (`.wasm`, `.pck`, loader) for the §5 payload measurement; confirm the host serves gzip/brotli for the wasm.
8. Smoke pass on every §4 matrix row before any performance claim is made.

## 4. Device / browser test matrix

| Row | Device / browser | Role | Notes |
|---|---|---|---|
| M1 | **iPhone 17, iOS Safari** (OS and browser versions recorded at test time) | **Must-support** (D14) | All VALIDATION gates V5–V8 are decided here |
| M2 | Desktop Chrome (current stable) | Development reference | Layout/debug reference only; never a substitute for M1 evidence |
| M3 | Desktop Firefox (current stable) | Development reference | WebGL/WASM divergence check |
| M4 | Desktop Safari (macOS, current) | Exploratory | Closest desktop proxy for iOS Safari behavior; findings do not transfer automatically |
| M5 | A current Android phone, Chrome | Exploratory | Keeps D16 informed; no support commitment in this phase |

Every test record names: engine build, export preset, build URL/hash, device, OS, browser version, CSS viewport size, device pixel ratio, power/thermal state (VALIDATION evidence format).

## 5. Performance measurement protocol

Targets are **PROPOSED hypotheses re-anchored on M1** (they supersede TECHNICAL_CONSTRAINTS' Android-anchored numbers — AUDIT B4). All are NOT-TESTED; none may be quoted as achieved.

| Target | Proposed value | Measurement |
|---|---|---|
| Frame rate | 60 fps; 95th-percentile frame time ≤ 20 ms | Full-slice run on M1 after a 30 s warm-up discard; 3 minutes of frame samples via the engine's debug/profile output plus Safari Web Inspector where available; device cool at start, thermal state logged at end |
| Cold payload | ≤ 30 MiB transferred (compressed, cold cache) | Network trace of a first load (fresh profile); inventory from export checklist item 7 |
| Cold load time | ≤ 12 s to tap-to-start at 20 Mbps / 50 ms RTT | Throttled network emulation + one real-network M1 confirmation |
| Texture residency | Peak ≤ 7 pages / 112 MiB (if the TEXTURE_BUDGET amendment is ratified) | Loaded-texture audit at the mixed-beat and boss-arena peaks once real art exists (VALIDATION V2/V8) |
| Touch behavior | Move+jump+whip and crouch+whip simultaneously; recovery from cancellation/focus loss | Screen recording + observation on M1 (VALIDATION V5) |

Failure handling: a missed target is recorded with its evidence and returns to the owning document (geometry → STAGE_DESIGN/GAMEPLAY_RULES; residency → TEXTURE_BUDGET; engine settings → this document). No target is "met" by estimation.

## 6. Android APK — DEFERRED (D16)

Not part of this phase; recorded so the later package starts from a list, not from memory. Prerequisites when D16 activates: JDK and Android SDK components at the versions the pinned engine's official Android export documentation requires (recorded then, not guessed now); the same 4.7.2 export templates (or a deliberate re-pin); a registered package identifier (reverse-DNS, chosen at activation; any value used earlier is a placeholder); arm64 as the primary architecture; a debug keystore for install testing and a release signing key held **outside** this repository (signing keys are never committed — TECHNICAL_CONSTRAINTS); then the V9 debug-install + touch/resume test on real hardware. The web build's input layer (§2) is the only APK-facing design commitment in this phase.

## 7. Pipeline rules learned in production (2026-10-12)

From the first implementation ([LESSONS.md](LESSONS.md) L15–L17):

- After repacking atlas PNGs, run `godot --headless --path <project> --import` before any test or capture. Otherwise the engine samples its previous import cache at the new region coordinates and draws the wrong sprite (the whip once drew a swooper wing).
- After packing, decode each atlas page and compare every packed region pixel-for-pixel with its source frame, so packing cannot silently swap, crop or shift a frame.
- Step every clip frame by frame through the real animation player in a headless test (VALIDATION V3); fast motions such as the 500 ms whip cannot be judged from browser screenshots, which took about 1.3 s each in headless Chromium.
- When publishing a web build, download the deployed `.pck` and compare its checksum with the local export, so the build you tested is the build people play.
- Desktop Chromium evidence (including software-rendered WebGL) is never reported as device evidence; iPhone 17 gates stay PENDING until run on the device.

## 8. Risks and open items

- iOS Safari WebGL2/Compatibility behavior, texture-memory limits, and audio latency on M1 are all unverified until device runs exist; the single-threaded baseline is chosen to minimize, not eliminate, that risk.
- The mip/residency question (TEXTURE_BUDGET §5 amendment) and this document's import settings are one decision seen from two sides; P6 must ratify or reject them together.
- Engine facts (C# web exclusion, threaded-hosting requirements, renderer path) were sourced from official documentation summarized in TECHNICAL_CONSTRAINTS (checked 2026-10-07) plus the 4.7.2 archive verification above; the §1 recheck rule applies at implementation.
- Open user items carried, unchanged: D09; D07–D11 confirmation; TEXTURE_BUDGET amendment ratification.

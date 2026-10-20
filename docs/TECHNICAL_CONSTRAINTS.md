# Technical framework — no implementation yet

Confirmed platform requirements are in D01. Everything else below is a proposed implementation direction for the next technical-spec task.

## Proposed baseline

Use Godot 4 with GDScript, the Compatibility renderer, and single-threaded web export. Godot's web documentation specifies WebAssembly/WebGL 2.0 support, identifies Compatibility as the web rendering path, and currently excludes Godot 4 C# web exports. Threaded exports have additional hosting requirements. Pin an exact stable engine version and matching export templates before creating a project; no version was chosen in the interview. [Official web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Require a user tap to begin audio; test browser focus/resume and real mobile performance. Treat browser rendering support as a tested device matrix, not a promise that every phone works. [Official mobile and audio considerations](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#mobile-considerations).

For later Android APK export, document the engine-matched Java/Android SDK prerequisites, templates, package identifier, architectures, debug-install test, and release-signing workflow. Exact versions belong in the future export specification. Signing keys never belong in the repository. [Official Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Sources checked 2026-10-07; recheck against the pinned engine release before implementation.

## Proposed responsibility boundaries

Player motion/state owns input and physical movement. Combat owns hit timing, hit IDs, and damage. Animation observes state and reports explicit timeline events; gameplay never guesses collision from image contents. Level data owns terrain/collision and spawn placement. Presentation owns camera, sound, effects, and UI. An input action layer serves keyboard and touch so the later APK does not require separate gameplay logic.

The downstream technical spec should choose concrete Godot node/resources only after describing these responsibilities and their data contracts. No plugin or paid tool dependency is mandated.

## Performance hypotheses to measure

Aim for 60 fps on an agreed mid-range Android phone, with a proposed 95th-percentile frame time ≤20 ms during a 3-minute warmed-up slice run. Exact phone, OS, browser, viewport, power mode, and thermal state must be recorded. Browser startup payload target: ≤30 MiB transferred on a cold cache; loading goal ≤12 s at measured 20 Mbps and 50 ms RTT. These are provisional targets, not achieved results.

Start with ≤128 MiB estimated resident RGBA texture data for slice art. One uncompressed 2048² RGBA8 atlas is 16 MiB before mipmaps/overhead; account for concurrent pages, not just compressed file size. Keep backgrounds and animations within an enumerated budget; reduce wasted canvas packing before reducing silhouette quality. Actual memory behavior still needs device profiling.

No required real-time volumetrics, expensive full-screen blur, or renderer-specific effects. Layered depth is an art/compositing goal, not a requirement for a 3D scene.

# Follow-on specification work

**Status 2026-10-12:** P0–P6 are drafted (imported from the askjackb completion pass and corrected), and the art contract (ART_CONTRACT.md, `contract/`, `tools/`) is added on top. The next useful work is a second implementation run from [prompts/BUILD.md](../prompts/BUILD.md), with every defect it finds fed back into LESSONS.md and a self-test case.

These are handoff boundaries, not an instruction to spawn agents or start implementation. Each package can be assigned independently once its dependencies are met. Use the decision template for changes to shared contracts.

| Package | Inputs / dependencies | Deliverable | Completion criterion |
|---|---|---|---|
| P0: resolve direction | Interview ledger | Preserve D05/D06; resolve D12/D13 with authority recorded | One coherent art branch and identity reference; remaining open items explicit |
| P1: gameplay rules | SPEC, asset coordinate contract | Complete state-transition table, input priority, damage/knockback rules, enemy/boss briefs | Every animation/state transition, interruption, attack tell, crouch-clearance case, knockdown/recovery, and failure/retry case defined |
| P2: art bible | P0, ART_DIRECTION | Named palette swatches, silhouette/material/light rules, reference register, style-pack evaluation plan | Another asset worker can reproduce the intended treatment without guessing |
| P3: asset production briefs | P1 + P2 | Individual briefs and full manifest field definitions for the slice inventory | Counts, sizes, timing, sockets, collision refs, dependency IDs, and rejection rules complete |
| P4: stage design | P1, movement envelope | Annotated blockout specification, encounter pacing, safe zones, checkpoint/boss placement | Every mandatory jump fits the conservative envelope; combat has safe readable setup |
| P5: technical/export design | D01, D14, official docs | Exact engine/template version, device/browser matrix, proposed scene/input/data boundaries, export checklist | No unsupported renderer/language requirement; performance measurement protocol defined |
| P6: readiness review | P0–P5 | Contradiction report and revised acceptance matrix | No unresolved production-blocking decisions; all proposed choices identified |

## Definition of specification-ready

A reviewer can explain the entire first minute; enumerate all required slice assets; distinguish rendering from collision; derive attack timing without inspecting art; identify exact target devices; and tell which decisions remain proposals. Shared values agree across the documents and manifest examples.

## Later production gates (not this assignment)

1. Explicit implementation assignment; lock the chosen engine version and proposed mechanics.
2. Greybox touch movement + whip test on actual target hardware.
3. Authorized style calibration and a single coherent hero/whip attack pipeline.
4. One mixed encounter with real art, mobile performance and legibility review.
5. Complete bounded web slice; only then reassess native Android APK work.

Do not create a large asset backlog or complete level map before movement and the asset pipeline are validated.

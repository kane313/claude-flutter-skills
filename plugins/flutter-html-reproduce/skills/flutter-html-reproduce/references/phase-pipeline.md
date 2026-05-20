# Phase pipeline orchestration

## Execution graph

```
[user invocation]
       │
       ▼
pre-flight: verify Flutter project, slug, detect existing file → maybe switch to incremental
       │
       ├── normal mode
       │       │
       │       ▼
       │  Phase 0: html-source-fetcher → html-flutter-align-table
       │       │
       │       ▼
       │  Phase 1: html-dom-to-widget-tree → write lib/pages/<slug>.dart
       │       │
       │       ▼
       │  Phase 2: html-css-to-flutter-style → fill styles in-place
       │       │
       │       ▼
       │  Phase 3: html-asset-export + interactions scaffold
       │       │
       │       ▼
       │  Phase 4: html-flutter-pixel-diff → verdict
       │
       └── incremental mode
               │
               ▼
          Phase 0 (Source & Align) — same as normal
               │
               ▼
          Phase 4 (pixel diff against existing file)
               │
               ▼
          green → emit "UI matches design, no changes" and exit
          yellow/red → diff regions → back-map to widget nodes → run Phase 2 on hit nodes only → re-Phase 4
```

## Per-phase mode behavior

| Phase | safe | fast | auto | incremental |
|---|---|---|---|---|
| Pre-flight | always | always | always | always |
| 0 | pause after | pause after | continue | pause after |
| 1 | pause after | continue | continue | SKIPPED |
| 2 | pause after | continue | continue | only diff-hit nodes |
| 3 | pause after | continue | continue | only if new assets needed |
| 4 | report only | report only | auto-retry once on yellow | auto-retry once |

## Resume semantics

For each phase, after success, write `.flutter-html-reproduce/<slug>/phase-N.summary.md`.
On next invocation with `--resume` (default), if `phase-N.summary.md` exists AND inputs hash unchanged (via meta.json + input file hashes), skip the phase.

## Diff → widget back-mapping (incremental mode)

For each top-K region from Phase 4:
1. Region bounding box (x, y, w, h) in screen coords.
2. Use Flutter's `LayoutBuilder` introspection (via patrol) to identify which widget tree node renders at that location. Without patrol, fall back to:
3. Source-map style heuristic: each widget in the dart file has a comment `// .className` from Phase 1; match the region position to the original HTML element's bounding box (computed via Playwright if URL kind, else via Image-based template matching).
4. The widget at the hit position becomes the "Phase 2 target node". Only its decoration / text style / padding are recomputed.

This is best-effort; if back-mapping fails, fall back to recomputing styles for the entire page (with a warning).

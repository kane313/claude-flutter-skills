# flutter-html-reproduce

Reproduce a Flutter UI page from an HTML input via a 5-phase pipeline:
**Source & Align → Skeleton → Styles → Assets + States → Verify**.

This plugin bundles seven skills under `skills/`:

- `flutter-html-reproduce` — the orchestrator; drives the 5 phases and the
  `safe` / `fast` / `auto` / `incremental` modes.
- `html-source-fetcher` — normalises the HTML input (file / URL / image /
  snippet) into a single `normalized.html`.
- `html-flutter-align-table` — maps CSS design tokens to the project's
  `ThemeData`, reporting matches and gaps.
- `html-dom-to-widget-tree` — translates the normalised DOM into a Flutter
  widget-tree skeleton.
- `html-css-to-flutter-style` — fills CSS-derived styles into the skeleton.
- `html-asset-export` — exports image / icon / font assets and patches
  `pubspec.yaml`.
- `html-flutter-pixel-diff` — pixel-compares the rendered Flutter page against
  the HTML design and reports a verdict.

## Behaviour highlights

- **Theme reuse** — matches CSS tokens against the project's existing
  `ThemeData` instead of hardcoding literals.
- **Incremental mode** — when the target page file already exists, it pixel-
  diffs first and surgically edits only the differing regions rather than
  overwriting hand-edited code.
- **Idiomatic structure** — splits output into `theme/`, `models/`, `data/`,
  `widgets/`, `pages/`; models multi-state screens as a request-driven
  lifecycle; emits a tab shell when the design has a shared bottom tab bar.

See `skills/flutter-html-reproduce/SKILL.md` for the full workflow.

## Requirements

A Flutter project as the working directory (`pubspec.yaml` with a `flutter:`
dependency). `cwebp` and Patrol are optional and only enable extra steps.

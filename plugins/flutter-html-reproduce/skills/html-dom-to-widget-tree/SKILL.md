---
name: html-dom-to-widget-tree
description: "Translates normalized HTML's DOM into a Flutter widget tree skeleton (no styles, just structure with TODO placeholders). Picks Row/Column/Stack/Wrap/GridView based on CSS display + flex/grid properties, maps <img>/<button>/<form>/<input>/<a>/<ul>/<svg> to corresponding Flutter widgets, and emits a single dart file with a top-of-file marker comment. Use as Phase 1 of HTML-to-Flutter reproduction."
---

# html-dom-to-widget-tree

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 1.
- Standalone: when you want a structural skeleton dart file from arbitrary HTML for hand-finishing.

## Inputs

- `normalized_html` (required) — path to `.flutter-html-reproduce/<page>/normalized.html`.
- `align_table` (optional) — path to align-table.md (improves widget naming hints; not required for structure).
- `output_file` (required) — destination `lib/pages/<page>.dart`.
- `page_class_name` (optional, derived from output_file) — e.g. `LandingPage`.

## Workflow

Read `references/dom-to-widget-mapping.md` for the full DOM → widget map.
Read `references/stack-detection.md` for the absolute-positioning sibling rule.

1. **Parse normalized.html** — produce a DOM tree (consider tags, attributes, computed display via inline + style block CSS).
2. **Annotate display** — each element gets a computed `display` (block / inline / flex-row / flex-col / grid / wrap / stack-required).
3. **Translate recursively** — root `<body>` → top-level widget; children processed per `dom-to-widget-mapping.md`.
4. **Emit dart file** — render via `templates/page.dart.tmpl`. Insert `// TODO: style` next to each widget that has CSS to apply later. Add marker comment at top.
5. **Verify** — run `dart format` on the output (in-place). Confirm exit 0 (no syntax errors).

## Outputs

- `<output_file>` (a runnable Stateless or StatelessWidget dart file). Each widget has a stable name; nodes corresponding to HTML elements with id/class get those as block comments like `// .card`.

## Constraints

- **No styles** — this phase produces structure only. CSS handling belongs to `html-css-to-flutter-style`.
- **No state** — the page emits as `StatelessWidget` by default. Switches to `StatefulWidget` only if `<form>` / `<input>` / `<button onclick>` is present (form requires controllers).
- **No imports beyond `package:flutter/material.dart`** — `<svg>` widgets are emitted as `// TODO: SvgPicture.asset(...) — requires flutter_svg` placeholders; the dependency check belongs to `html-asset-export`.

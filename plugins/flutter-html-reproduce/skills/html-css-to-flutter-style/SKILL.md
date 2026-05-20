---
name: html-css-to-flutter-style
description: "Fills CSS-derived styles (color, typography, spacing, padding, margin, border, radius, shadow, gradient, transform) into a previously-generated Flutter widget tree dart file. Prefers Theme.of(context).* references when the value matches an align-table entry; otherwise hardcodes the literal with a // TODO: theme gap marker. Use as Phase 2 of HTML-to-Flutter reproduction (runs after html-dom-to-widget-tree)."
---

# html-css-to-flutter-style

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 2.
- Standalone: when you have a skeleton dart widget tree and want to fill styles from a normalized HTML's CSS.

## Inputs

- `normalized_html` (required)
- `widget_tree_dart_file` (required) — typically `lib/pages/<page>.dart` after Phase 1.
- `align_table` (optional but strongly preferred) — for Theme.of(context).* binding.

## Workflow

Read `references/css-property-map.md` for the per-property mapping.
Read `references/theme-binding.md` for how align-table hits become `Theme.of` references.

1. **Re-parse the dart file** — locate every `// TODO: style` marker and the widget literal it annotates.
2. **For each annotated widget**, look up its source HTML element by id/class (the dart file's comments include this — they were inserted in Phase 1).
3. **Compute Flutter style args** from the matched CSS rules. Use align-table for tokens that match.
4. **Edit the dart file in place** — replace the bare widget constructor call with one that includes `decoration:`, `padding:`, `style:`, etc. Remove the `// TODO: style` marker. Add `// TODO: theme gap` for any hardcoded literal that should have been in the theme.
5. **Run `dart format`** in-place. Confirm exit 0.

## Outputs

- `<widget_tree_dart_file>` (modified in place). All `// TODO: style` markers removed.
- A short `style-summary.md` written to `.flutter-html-reproduce/<page>/` listing: total styles applied, total `theme gap` markers added, total `UNSUPPORTED` CSS occurrences.

## Constraints

- **In-place edits only** — must not change widget tree structure. (Structural changes belong to Phase 1.)
- **Preserve user edits**: lines NOT marked `// TODO: style` (i.e., the user manually styled something between Phase 1 and now) are left untouched.
- **`UNSUPPORTED` is explicit**: never silently drop a CSS property; either map it or emit `// UNSUPPORTED: <css>` as a sibling comment.

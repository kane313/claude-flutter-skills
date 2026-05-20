---
name: html-flutter-align-table
description: "Scans a normalized HTML file and a Flutter project's lib/theme/** and produces an 'align table' — Figma-style mapping of CSS tokens (colors, typography, spacing, radius, shadow) to existing ThemeData / ColorScheme / TextTheme entries — plus a 'gaps' list of tokens that have no project counterpart. Read-only on the project. Use as Phase 0 step 2 of HTML-to-Flutter reproduction, or to audit a Flutter project's theme coverage against an arbitrary HTML design."
---

# html-flutter-align-table

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 0 step 2 (after `html-source-fetcher`).
- Auditing a Flutter project's theme against a known HTML design.

## Inputs

- `normalized_html` (required) — path to `.flutter-html-reproduce/<page>/normalized.html`.
- `project_dir` (optional, default: cwd) — Flutter project root (must contain `pubspec.yaml` with flutter dep).
- `output_dir` (optional, default: same as input parent) — where to write outputs.

## Workflow

Read `references/token-extraction.md` for the CSS-token extraction algorithm.
Read `references/semantic-match.md` for the project-side scan and matching rules.
Read `references/output-format.md` for the exact markdown templates.

1. **Verify project** — `pubspec.yaml` exists with `flutter:` dependency. Otherwise emit clear error per spec §2.3.
2. **Extract HTML tokens** — color / font-family / font-size / line-height / border-radius / spacing scale / box-shadow. Build a `tokens_html` set.
3. **Scan project theme** — read `lib/theme/**.dart`, parse `ColorScheme` / `TextTheme` / custom `ThemeExtension` definitions. Build `tokens_project` set.
4. **Match** — semantic match per the rules in `semantic-match.md`. For each HTML token: either matched (with `Theme.of` reference) or gap (with suggested entry name).
5. **Emit** — use `templates/align-table.md.tmpl` for matches, `templates/gaps.md.tmpl` for gaps. Both written to `output_dir/`.

## Outputs

- `<output_dir>/align-table.md`
- `<output_dir>/gaps.md`

## Constraints

- **Read-only** on the Flutter project. Never modify `lib/theme/**`. Gap filling is a separate task for the user (or, in v0.2+, an `html-theme-gap-filler` companion skill).
- **No `lib/theme/` ⇒ degraded mode**: emit `gaps.md` listing all extracted tokens with the note `project has no theme layer — recommend running theme audit before reproduce` and a still-valid empty `align-table.md`.
- **Align-table hit rate < 30%** ⇒ append a warning header to `align-table.md` per spec §5.4.

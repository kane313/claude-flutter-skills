---
name: html-flutter-pixel-diff
description: "Captures a Flutter rendering of a target page (via Patrol if installed, else via adb screencap on Android, else skipped on iOS) and compares it pixel-by-pixel against an HTML reference screenshot from Phase 0. Produces a diff-report.md with overall difference rate, a heatmap PNG, and region-level analysis suggesting likely causes (spacing, color, missing element). Verdict colored red/yellow/green. Use as Phase 4 of HTML-to-Flutter reproduction, or as the comparison step of incremental mode."
---

# html-flutter-pixel-diff

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 4.
- Incremental mode: also as the first comparison step right after Phase 0.

## Inputs

- `html_screenshot` (required) — `.flutter-html-reproduce/<page>/screenshot.png` (or, in image-input mode, the source image itself).
- `flutter_page_dart` (required) — path of `lib/pages/<page>.dart` to render.
- `page_route` (optional) — route name to navigate the running app to before capturing. Default: `/`. Future versions may auto-route.
- `--flutter-screenshot=<path>` (optional) — skip live capture, diff against an existing image.

## Workflow

Read `references/patrol-driver.md` if Patrol is installed.
Read `references/adb-driver.md` if falling back to adb.
Read `references/diff-algorithm.md` for the per-pixel + region segmentation algorithm.

1. **Decide capture path**:
   a. If `--flutter-screenshot` provided → skip capture; proceed to diff.
   b. Else if `dev_dependencies.patrol` present in pubspec → use Patrol (see `patrol-driver.md`).
   c. Else if `adb devices` shows an attached Android device → use adb (see `adb-driver.md`).
   d. Else on iOS without Patrol → skip Phase 4; emit a friendly note in `diff-report.md`.
2. **Capture** Flutter screenshot to `.flutter-html-reproduce/<page>/flutter-shot.png`.
3. **Diff** the two PNGs per `diff-algorithm.md`. Produce `diff-heatmap.png`.
4. **Analyze regions** — identify the top 3 largest diff regions; for each, attempt to classify the cause via heuristics:
   - High color delta over a large area → likely background/fill color mismatch.
   - Pixel-aligned shifts in one direction → likely padding/margin difference.
   - Diff region exists only in one image → missing or extra element.
5. **Verdict**:
   - overall diff < 10% → 🟢 green: `UI matches design.`
   - 10–50% → 🟡 yellow: `Differences detected — see report.`
   - > 50% → 🔴 red: `Significant differences — top suspects: ...`
6. **Emit** `diff-report.md`. Include verdict at the top.

## Outputs

- `.flutter-html-reproduce/<page>/diff-report.md`
- `.flutter-html-reproduce/<page>/diff-heatmap.png`
- `.flutter-html-reproduce/<page>/flutter-shot.png` (the captured Flutter image — kept for re-diff)

## Constraints

- **No app modification** — the skill must only capture; never edit `lib/`.
- **iOS without Patrol degrades gracefully** — never error; emit a note.
- **adb mode is Android-only** — fail clearly if iOS is targeted and only adb is available.
- **Diff threshold is configurable** but the default red/yellow/green bands above match spec §5.5.

---
name: flutter-html-reproduce
description: "[Flutter projects only — pubspec.yaml with flutter dep present.] Reproduces a Flutter UI page from an HTML input (file / URL / screenshot / snippet) via 5-phase pipeline: Source & Align → Skeleton → Styles → Assets+States → Verify. Reuses the project's ThemeData via align-table matching. When the target lib/pages/<page>.dart already exists, switches to diff-driven incremental update — runs pixel diff first, then surgically applies edits only at differing regions; emits 'UI matches design, no changes' if the page is already correct. Orchestrates six sub-skills: html-source-fetcher, html-flutter-align-table, html-dom-to-widget-tree, html-css-to-flutter-style, html-asset-export, html-flutter-pixel-diff. Modes: safe (checkpoint each phase) / fast (chain 1→3) / auto (end-to-end) / incremental (auto-selected when file exists). Auto-trigger phrases: '还原这个 HTML', '用 Flutter 实现这个网页', 'reproduce HTML in Flutter', '按 HTML 做 Flutter 页面'. Also triggers on .html / .css file paths or http(s) URLs paired with reproduction context."
---

# flutter-html-reproduce

## When to use

Auto-trigger conditions:
- User message contains a path ending in `.html` or `.css` AND cwd is a Flutter project.
- User message contains an `http://` or `https://` URL **and** reproduction context (verbs like "还原 / 实现 / reproduce / build" + "页面 / page / UI").
- Explicit phrases listed in the frontmatter description.
- Explicit `/flutter-html-reproduce` invocation.

DO NOT auto-trigger when:
- User is asking general HTML questions (no Flutter context).
- User is asking general Flutter questions (no HTML input).
- User invoked a Figma reproduction (`flutter-figma-reproduce` family handles that).

## Inputs

| Arg | Required | Notes |
|---|---|---|
| `source` | yes | file / URL / image / snippet (see html-source-fetcher) |
| `--page=<slug>` | no | output slug; default derived per §4.1 of design spec |
| `--mode=safe\|fast\|auto\|incremental` | no | default `safe`; `incremental` auto-selected if file exists |
| `--render=static\|js` | no | only meaningful for URL inputs |
| `--output=lib/pages/<file>.dart` | no | default `lib/pages/<slug>.dart` |
| `--clean` | no | discard `.flutter-html-reproduce/<page>/` before starting |
| `--resume` | no | default; skip phases with existing `phase-N.summary.md` |
| `--include-large` | no | passed through to asset-export |
| `--force` | no | overwrite existing file (skip incremental detection) |
| `--flutter-screenshot=<path>` | no | offline Phase 4: skip live capture |

## Workflow

Read `references/phase-pipeline.md` for the full 5-phase orchestration logic.
Read `references/mode-decisions.md` for mode-specific behavior.

### Pre-flight

1. **Verify cwd is a Flutter project** — `pubspec.yaml` exists with `flutter:` dep. Fail-fast per spec §2.3.
2. **Determine page slug** — from `--page=` or by deriving from source.
3. **Detect existing target file** — if `lib/pages/<slug>.dart` exists AND `--force` not set → switch to `--mode=incremental`. Announce the switch.
4. **Prepare working dir** — `.flutter-html-reproduce/<slug>/`. Add to .gitignore if absent (idempotent).

### Phase 0 — Source & Align

1. Invoke **html-source-fetcher** with the source and `--render` flag.
2. Invoke **html-flutter-align-table** with the normalized.html.
3. In `safe` mode: pause, show user the align-table.md + gaps.md summary, await confirmation.

### Phase 1 — Skeleton

Skipped in `--mode=incremental`. Otherwise:
1. Invoke **html-dom-to-widget-tree** with normalized.html and align-table.md.
2. **Mobile mockups — transparent system status bar.** When the source is a
   phone-frame mockup, its status bar (e.g. a fake "9:41 📶🔋") and notch are
   device-frame chrome, not app UI — do not reproduce them. Instead make the
   real system status bar transparent so the page background extends behind it,
   which is exactly how the mockup renders that strip. Set
   `SystemUiOverlayStyle(statusBarColor: Colors.transparent, ...)` with icon
   brightness matching the page background (dark icons on a light bg) — either
   globally via `SystemChrome.setSystemUIOverlayStyle` in `main()`, or
   page-scoped via `AnnotatedRegion<SystemUiOverlayStyle>` wrapping the Scaffold
   (preferred when only `lib/pages/<slug>.dart` may be touched). Inset the body
   with `SafeArea` so content clears the status bar.
3. **Shared bottom tab bar — emit a shell, not per-page bars.** If the mockup
   shows the *same* bottom tab bar across multiple screens, that bar is a
   navigation shell shared by the tabs — not part of any single page. Reproduce
   the current page as a tab *body*: a Scaffold with **no** `bottomNavigationBar`.
   Put the tab bar in a separate shell scaffold (e.g. `lib/pages/main_tabs.dart`)
   that holds an `IndexedStack` of the tab bodies plus the bottom bar, and point
   `main.dart`'s `home` at it. Tabs switch by `IndexedStack` index, never by
   `Navigator.push`/`pop` — routing would re-show the bar per page and drop tab
   state; `IndexedStack` keeps every tab alive so each tab's state survives
   switches. Screens the mockup draws *without* the tab bar (a full-screen
   search / detail / modal) stay as pushed routes that cover the shell.
4. **Split the output across files — don't dump everything into one page file.**
   A reproduced page of any real size is unreadable as a single file. Organise
   by responsibility:
   - `lib/theme/app_colors.dart` (or similar) — design tokens (colours, etc.)
     as a class of `static const` fields: one source of truth, no scattered
     literals or per-page private `_Tokens` copies. In degraded mode (project
     has no theme) it is fine to *create* this file; never edit the project's
     existing `ThemeData`.
   - `lib/models/` — plain data classes and enums.
   - `lib/data/` — mock repositories and seed data.
   - `lib/widgets/<area>/` — one file per reusable component; tightly-coupled
     sub-widgets (a row used only by its card) may stay private in the parent's
     file.
   - `lib/pages/<slug>.dart` — thin composition wiring the widgets together.
   Anything referenced across files must be public (no `_` prefix); keep
   genuinely local helpers private.
5. In `safe` mode: pause, show widget tree summary + `flutter analyze` result.

### Phase 2 — Styles

In `--mode=incremental`, this phase runs **only on diff-hit nodes** (see Phase 4 result). Otherwise it runs on every widget annotated `// TODO: style`.
1. Invoke **html-css-to-flutter-style**.
2. In `safe` mode: pause, show style-summary.md.

### Phase 3 — Assets + States

1. Invoke **html-asset-export**.
2. **Multi-state pages — model as a request-driven lifecycle, not a switcher.**
   When the mockup repeats the *same* screen in several states (loading
   skeleton, success, offline / cached, empty, error), those are the stages of
   one data request — not variants the user toggles between. Build a single
   page whose state is driven by a mock repository: an initial `fetch()`
   produces loading → success / offline-with-cache / offline-no-cache, and
   pull-to-refresh + a retry button re-trigger it. Do **not** add a demo chip
   bar or segmented control for manually picking a state — it misrepresents the
   architecture, and the user will ask you to tear it out. To keep every state
   observable without such a switcher, have the mock `fetch()` advance a
   scripted sequence so successive pull-to-refresh / retry calls walk through
   all of them. Pure content differences (the same success layout with
   different data — e.g. a different fishing-index level) are just different
   success responses, *not* separate states. Model request state with a
   `sealed class` so the body `switch` is exhaustive.
3. Form / interaction scaffolding: if Phase 1 detected `<form>` / `<input>` / `<button>`, the widget tree already contains placeholders — add controller field declarations and `onPressed: () { /* TODO */ }` stubs if not present.
4. **Swipe-to-reveal actions — reveal-then-tap, not act-on-swipe.** When the
   mockup shows a list row partially swiped with an action button exposed
   behind it (an iOS-style swipe action — e.g. a red 删除 panel), the action
   fires when that revealed button is **tapped**, not when the swipe finishes.
   `Dismissible` is the wrong widget — it removes the row the moment the swipe
   completes. Reproduce it as swipe-to-reveal: the row slides to expose a fixed
   action button that stays open until tapped (or swiped closed). Use
   `flutter_slidable` if a dependency is acceptable, otherwise hand-roll with an
   `AnimationController` + `Transform.translate` inside a `Stack` — the drag
   follows the finger and snaps open/closed on release. Reserve `Dismissible`
   only for mockups whose intent truly is swiping the row clean away with no
   intermediate button.
5. Animation scaffolding (best-effort): scan normalized.html for `@keyframes` / `transition`; for each, emit an `// TODO: animate via AnimatedContainer` near the relevant widget. Full animation translation is out of scope for v0.1.
6. In `safe` mode: pause, show asset-summary.md.

### Phase 4 — Verify

1. Invoke **html-flutter-pixel-diff** with html screenshot + the generated dart file.
2. Decision based on diff verdict and mode:
   - `green` (< 10%) → finalize.
   - `yellow` (10–50%) → in `safe` / `fast` mode: pause and ask user; in `auto` / `incremental` mode: attempt one more pass of localized Phase 2 on diff-hit regions, re-diff. Max 2 rounds.
   - `red` (>50%) → finalize but warn user prominently; report likely causes.

### Finalization

- Write `final-summary.md` in `.flutter-html-reproduce/<page>/`.
- Echo to conversation: file path of generated dart file, verdict color, top issues if any.

## Outputs

- `lib/pages/<slug>.dart` plus the `lib/theme` / `lib/models` / `lib/data` / `lib/widgets` files it is split into (see Phase 1).
- `assets/{images,icons,fonts}/` + patched `pubspec.yaml`.
- `.flutter-html-reproduce/<slug>/` with all intermediate artifacts.

## Constraints

- **Never edit the project's existing `ThemeData` / theme files.** If the project has no theme layer, you *may* create a new `lib/theme/` design-token file (see Phase 1) — but never rewrite an existing one.
- **Only create or edit files the reproduction owns**: `lib/pages/<slug>.dart`, the `lib/theme` / `lib/models` / `lib/data` / `lib/widgets` files it splits into, a tab-shell file when the mockup has a shared tab bar, `main.dart`'s `home` wiring, and `pubspec.yaml` (assets/fonts sections only). Never touch unrelated existing source.
- **Diff-driven incremental mode is the default** for existing files — must NEVER silently overwrite a hand-edited file.
- **Phase 4 may be skipped on iOS without Patrol** — never error.

---
name: html-source-fetcher
description: "Normalizes an HTML-shaped input (local .html/.css file, http(s) URL, page screenshot, or pasted HTML snippet) into a single normalized.html plus an optional screenshot.png and source.meta.json. Picks between WebFetch (static), Playwright (JS-rendered), and vision-only paths automatically or per the --render flag. Use when starting Phase 0 of an HTML-to-Flutter reproduction, or whenever you need a single normalized form of an HTML source before further analysis. Requires the target Flutter project to be cwd."
---

# html-source-fetcher

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 0 step 1.
- Whenever a downstream skill or task needs a single normalized HTML representation of a possibly-messy input (multiple files with @import, JS-rendered page, just an image, ...).

## Inputs

- `source` (required) — one of:
  - local file path ending in `.html`
  - URL starting with `http://` or `https://`
  - local image path ending in `.png`/`.jpg`/`.webp`
  - pasted HTML snippet (string starting with `<`)
- `--page=<slug>` (optional) — output sub-directory name. Defaults derived per §4.1.
- `--render={static|js}` (optional, URL only) — force static fetch or Playwright render.

## Workflow

Read `references/fetch-strategies.md` for the per-input-kind algorithm.
Read `references/playwright-setup.md` only when `--render=js` is invoked.

1. **Detect input kind** — match against the rules above; ambiguous → ask user.
2. **Dispatch fetch** — call `scripts/fetch.sh <kind> <source> <output-dir>`.
3. **Inline external CSS** (file kind only) — for each `<link rel="stylesheet" href="X">`, read X relative to the HTML file and replace with `<style>...</style>`.
4. **Capture screenshot** if path can produce one (URL with Playwright, image input is itself the screenshot, file kind can be rendered via Playwright on-demand).
5. **Write `source.meta.json`** with `{kind, render, url?, vision_only, fetched_at}`.

## Outputs

- `.flutter-html-reproduce/<page>/normalized.html`
- `.flutter-html-reproduce/<page>/screenshot.png` (if available)
- `.flutter-html-reproduce/<page>/source.meta.json`

## Constraints

- **Never reach beyond `<page>` sub-directory** — do not modify project source files.
- **Never silently install Playwright** — first-time use must prompt and require user confirmation per spec §5.2.
- **Image input ⇒ no DOM** — set `vision_only=true`, skip CSS inlining, no normalized.html (write a placeholder with `<!-- vision-only -->` marker).

## Implementation note: URL kinds are dispatched from the SKILL

`scripts/fetch.sh` handles file/snippet/image kinds hermetically (no network).
URL fetching is performed by the SKILL itself using Claude tools (`WebFetch` for
static, ad-hoc `npx playwright` invocation for JS-rendered), then the resulting
HTML is fed back into `fetch.sh local-file <temp> <out>`. This keeps unit tests
offline and reproducible.

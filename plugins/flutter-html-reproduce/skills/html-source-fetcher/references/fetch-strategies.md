# Fetch strategies

## Strategy by kind

### local-file (`.html`)
1. `cat <file>` → raw HTML.
2. For each `<link rel="stylesheet" href="X">` and `<style>@import url("X")</style>`:
   - Resolve X relative to the HTML file's directory.
   - Read X. If not found, log to `fetch.log` and leave the tag intact.
   - Replace the `<link>` with `<style>/* inlined from X */\n<contents>\n</style>`.
3. For each `<style>...</style>` already inline → keep as-is.
4. Output normalized.html. No screenshot unless user explicitly requested `--screenshot`.

### url-static (default for URL)
1. Use Claude's WebFetch tool with the URL.
2. If response Content-Type is HTML and body length > 500 bytes → treat as static success.
3. If response is < 500 bytes OR contains `<div id="root"></div>` style SPA shell with no children → record `spa_suspected=true` in meta, suggest re-running with `--render=js`.
4. Inline CSS same as local-file, but `href` is resolved against URL origin (use `WebFetch` for each stylesheet).

### url-js (`--render=js`)
1. Verify Playwright reachable: `npx playwright --version`. If missing, follow `playwright-setup.md`.
2. Run `npx playwright screenshot --full-page <url> screenshot.png` for the screenshot.
3. Run a small inline Playwright script to extract rendered DOM: `await page.content()`.
4. Save rendered HTML as normalized.html (CSS likely already inline via computed styles — do NOT re-inline external sheets; user is downstream consuming the rendered tree).

### image (`.png|.jpg|.webp`)
1. Copy/move the image to `<output-dir>/screenshot.png` (convert format if needed via `sips` on macOS, `convert` elsewhere).
2. Set `vision_only=true` in meta.
3. Write a stub normalized.html: `<!-- vision-only: source was image -->`.

### snippet (string starting with `<`)
1. Write the string verbatim to normalized.html.
2. Inspect for `<link>`/`@import` — if present, warn user and ask whether they want to provide the referenced files.

## Output schema for source.meta.json

```json
{
  "kind": "local-file | url-static | url-js | image | snippet",
  "render": "static | js | none",
  "url": "<original url if URL kind>",
  "vision_only": false,
  "spa_suspected": false,
  "fetched_at": "<ISO 8601 timestamp>"
}
```

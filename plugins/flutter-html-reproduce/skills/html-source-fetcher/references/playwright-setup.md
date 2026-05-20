# Playwright setup

## First-time use

```
npx playwright --version
```

If this fails or asks to install, **prompt user** with:

> Playwright is not installed. To render JS-heavy URLs, we need to install it:
> ```
> npx playwright install chromium
> ```
> Downloads ~300MB to ~/.cache/ms-playwright/. Proceed? (yes/no)

Do NOT install without yes.

## Smoke test after install

```
npx playwright screenshot https://example.com /tmp/_pw_smoke.png
```
Expected: file exists, size > 1KB. Delete after verification.

## Failure modes

- `npx` not on PATH → ask user to install Node.js (>=18).
- Chromium fails to launch on Linux → likely missing system deps. Suggest `sudo npx playwright install-deps`.
- macOS Gatekeeper blocks first launch → user must approve via System Settings → Privacy.

## Usage in fetch.sh

````bash
url="$1"; out_dir="$2"
npx playwright screenshot --full-page "$url" "$out_dir/screenshot.png"

node -e "
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('$url', { waitUntil: 'networkidle' });
  const html = await p.content();
  require('fs').writeFileSync('$out_dir/normalized.html', html);
  await b.close();
})();
"
````

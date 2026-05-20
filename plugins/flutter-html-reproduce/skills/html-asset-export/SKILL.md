---
name: html-asset-export
description: "Downloads or copies image/SVG/font references from a normalized HTML file into the Flutter project's assets/ tree (assets/images/, assets/icons/, assets/fonts/), optionally converts raster images to WebP (when cwebp is on PATH) and writes a 2x density variant to assets/images/2.0x/, then patches pubspec.yaml's flutter.assets and flutter.fonts sections alphabetically. Idempotent and produces git-friendly diffs. Use as Phase 3 of HTML-to-Flutter reproduction."
---

# html-asset-export

## When to use

- Invoked by `flutter-html-reproduce` main skill as Phase 3.
- Standalone: when you want to bulk-import all images/icons/fonts referenced by an HTML file into a Flutter project.

## Inputs

- `normalized_html` (required)
- `project_dir` (optional, default: cwd)
- `--include-large` (optional flag) — download files > 5MB. Default: skip + record in gaps.md.

## Workflow

Read `references/asset-resolution.md` for resolving `src` URLs (absolute / relative / data-uri / blob).
Read `references/pubspec-patch.md` for the alphabetical idempotent yaml patch algorithm.

1. **Collect refs** — scan normalized.html for `<img src>`, `<picture><source srcset>`, inline `background-image: url(...)`, `<link rel="icon">`, `<svg>` inline elements (skipped — they get embedded), `@font-face src: url(...)`.
2. **Resolve** — per `asset-resolution.md`.
3. **Download/copy** — `<img>` → `assets/images/<name>`; `<svg>` → `assets/icons/<name>.svg`; fonts → `assets/fonts/<name>`.
4. **Convert (optional)** — if `cwebp` is available and the image is JPEG/PNG, also produce `assets/images/2.0x/<name>.webp` (full-res, treated as 2x density) and `assets/images/<name>.webp` (resampled to 50%). Update HTML refs to point at the WebP name.
5. **Patch pubspec.yaml** — add entries to `flutter.assets` (sorted) and `flutter.fonts` (sorted by family). Preserve all unrelated yaml content. Use 2-space indent (matches `flutter create` style).
6. **Emit summary** — `.flutter-html-reproduce/<page>/asset-summary.md` listing each ref: status (ok / missing / skipped-large / fallback-network).

## Outputs

- Files under `assets/{images,icons,fonts}/` (and `assets/images/2.0x/`)
- `pubspec.yaml` patched in place
- `assets/_missing.txt` if any 404 / CORS / oversize (one line per failure: `<original src> | <reason>`)
- `.flutter-html-reproduce/<page>/asset-summary.md`

## Constraints

- **Never overwrite an existing asset** at the same path unless the byte content differs AND user passed `--force-assets`.
- **Never modify pubspec.yaml outside `flutter.assets` and `flutter.fonts`**.
- **Network fetches must respect `--include-large`** — without it, files >5MB are skipped + recorded.
- **`<svg>` inline elements are NOT exported** — they're rendered via `flutter_svg` from string in Phase 1 OR left as TODO. Only `<svg src="...">` references and standalone `.svg` files are exported.

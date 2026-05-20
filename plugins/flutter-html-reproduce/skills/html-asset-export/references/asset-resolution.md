# Asset src resolution

## Sources

| src form | How |
|---|---|
| `assets/foo.png` | already a project-relative asset path; skip if file exists at that path |
| `./foo.png`, `foo.png`, `../bar/foo.png` | resolve relative to normalized.html's original source path (in source.meta.json) |
| `/foo.png` | for URL kind: relative to URL origin; for file kind: relative to filesystem root of html file's project (best-effort) |
| `https://...` / `http://...` | network fetch via WebFetch (binary mode if available; else fall back to `curl -L --max-time 30`) |
| `data:image/png;base64,XXX` | decode base64 inline → write to `assets/images/<hash>.png` where hash is first 8 chars of sha256 |
| `blob:...` | unreachable from outside browser → record in `_missing.txt` |

## File naming

Preserve original basename. Slugify special chars: `Hero Banner@2x.png` → `hero_banner_2x.png`. If two srcs collide on slug, append `-2`, `-3`, etc.

## Extension inference for data: URIs

Look at the MIME type after `data:`. Map:
- `image/png` → `.png`
- `image/jpeg` → `.jpg`
- `image/webp` → `.webp`
- `image/svg+xml` → `.svg`
- `image/gif` → `.gif`
- `font/woff2` → `.woff2`
- `font/woff` → `.woff`
- `font/ttf` → `.ttf`

## Size guard

After fetch (or before, for `Content-Length`): if size > 5MB and `--include-large` not set, do NOT save; instead append to `_missing.txt`:
```
<src> | skipped: size 7.2MB > 5MB limit (use --include-large to override)
```

## Failures that don't block

- Network 404 / 403 / DNS fail → log to `_missing.txt`, emit `// TODO: missing asset <src>` in any dart consumer.
- Decompression failure on WebP → keep original PNG/JPEG, do not crash.
- `cwebp` not on PATH → skip WebP conversion entirely (assets are still usable, just larger).

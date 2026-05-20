# pubspec.yaml patch algorithm

## Goal

Add new asset paths under `flutter.assets` and new font families under `flutter.fonts`. Preserve all other content byte-for-byte. Produce alphabetically-sorted entries (stable diffs). Idempotent.

## Algorithm

1. **Parse the existing pubspec.yaml** with a YAML parser that preserves comments and ordering (`ruamel.yaml` in Python; `yq` for shell). Failing that, use a regex-targeted text edit: locate the `flutter:` section, locate `assets:` and `fonts:` subkeys, splice entries.
2. **Build the union** of existing entries + new entries.
3. **Sort case-insensitively.**
4. **Write back** the file with the patched lists; leave everything outside `flutter.assets` and `flutter.fonts` untouched.

## Format conventions

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/icons/checkmark.svg
    - assets/images/2.0x/hero.webp
    - assets/images/hero.webp
    - assets/images/logo.png
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: JetBrains Mono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
```

- 2-space indent throughout.
- One blank line before the `flutter:` key and after the section; no other blank lines inside `flutter.assets` / `flutter.fonts`.
- Font weights mapped from `@font-face font-weight: X` (omit weight key if 400/normal).

## Idempotency

Re-running with the same inputs must produce no diff. Achieve this by:
- Always sorting before writing.
- Always normalizing the existing entries on read (strip trailing whitespace, normalize `- foo` vs `- "foo"`).
- Diffing in-memory before writing — write only if content changed.

## Conflict cases

- `flutter:` key missing → add it (legal, top-level).
- `flutter.assets` key missing → add it.
- `flutter.assets` exists but is a string instead of a list (legal yaml shorthand for a single entry) → convert to list.

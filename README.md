# claude-flutter-skills

A [Claude Code](https://claude.com/claude-code) plugin marketplace for Flutter
development. It currently ships one plugin — **flutter-html-reproduce** — which
reproduces a Flutter UI page from an HTML design input.

## Install

In Claude Code, run:

```
/plugin marketplace add kane313/claude-flutter-skills
/plugin install flutter-html-reproduce@claude-flutter-skills
```

Then restart Claude Code when prompted. To get updates later:

```
/plugin marketplace update claude-flutter-skills
```

## What's in the box

### Plugin: `flutter-html-reproduce`

Reproduces a Flutter UI page from an HTML input (a local `.html`/`.css` file, a
URL, a screenshot, or a pasted snippet) via a 5-phase pipeline:

```
Source & Align → Skeleton → Styles → Assets + States → Verify
```

It bundles an orchestrator skill plus six sub-skills:

| Skill | Role |
|---|---|
| `flutter-html-reproduce` | Orchestrates the 5-phase pipeline |
| `html-source-fetcher` | Normalises the HTML input into one file |
| `html-flutter-align-table` | Maps CSS tokens to the project's `ThemeData` |
| `html-dom-to-widget-tree` | Translates the DOM into a Flutter widget tree |
| `html-css-to-flutter-style` | Fills CSS-derived styles into the widget tree |
| `html-asset-export` | Exports images / icons / fonts and patches `pubspec.yaml` |
| `html-flutter-pixel-diff` | Pixel-compares the result against the design |

## Usage

Open a Flutter project in Claude Code (the working directory must contain a
`pubspec.yaml` with a `flutter:` dependency), then ask in plain language —
the skill auto-triggers on phrases such as:

- `还原这个 HTML` / `用 Flutter 实现这个网页`
- `reproduce this HTML in Flutter`
- a message containing a `.html` / `.css` path or an `http(s)` URL together
  with reproduction intent

The pipeline reuses the project's existing theme where possible, splits the
output into `theme/` · `models/` · `data/` · `widgets/` · `pages/` files, and
runs `flutter analyze` along the way.

## Requirements

- Claude Code with plugin support.
- A Flutter project as the working directory.
- Optional: `cwebp` on `PATH` for WebP asset conversion; Patrol for the
  pixel-diff verification step (the step is skipped gracefully without it).

## License

MIT — see [LICENSE](LICENSE).

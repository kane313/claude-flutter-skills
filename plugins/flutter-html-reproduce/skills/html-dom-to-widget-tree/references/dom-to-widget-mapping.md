# DOM → Widget mapping

## Containers by CSS display

| CSS condition | Flutter |
|---|---|
| `display: flex; flex-direction: row` (default) | `Row` |
| `display: flex; flex-direction: column` | `Column` |
| `display: flex; flex-wrap: wrap` | `Wrap` |
| `display: grid` (simple repeating) | `GridView.count(crossAxisCount: <cols>)` |
| `display: grid` (complex template) | `LayoutBuilder` + manual `Wrap`/`Column`/`Row` (best-effort) |
| `display: block` (default `<div>`) | `Container` (will receive `BoxDecoration` in Phase 2) |
| `display: inline-block` | wrapped in nearest `Row` parent or standalone widget |
| Any element with `position: absolute` sibling | parent becomes `Stack` + child becomes `Positioned(...)`. See `stack-detection.md`. |
| `overflow: auto` / `overflow: scroll` on a flex-col or block | wrap content in `SingleChildScrollView` or `ListView` if a long list of repeated children |

## Main / cross axis alignment

Read from `justify-content` (main) and `align-items` (cross).

| CSS | Flutter `MainAxisAlignment` |
|---|---|
| `flex-start` (default) | `start` |
| `flex-end` | `end` |
| `center` | `center` |
| `space-between` | `spaceBetween` |
| `space-around` | `spaceAround` |
| `space-evenly` | `spaceEvenly` |

Same enum applies to `CrossAxisAlignment` for `align-items`.

`gap: X` → `SizedBox(width/height: X)` inserted between children. (We don't depend on Flutter's `spacing` property for cross-version compatibility.)

## Leaf elements

| HTML | Flutter | Notes |
|---|---|---|
| `<h1>`–`<h6>` | `Text(...)` | `// TODO: style — headlineLarge` style hint |
| `<p>` | `Text(...)` | with `softWrap: true` (default) |
| `<span>` | `Text(...)` | inline; nest inside Row if siblings exist |
| `<a href>` | `InkWell(onTap: () {/* TODO: nav */}, child: Text(...))` | hosts Text or its children |
| `<button>` | `ElevatedButton` / `OutlinedButton` / `TextButton` | choose by CSS: filled bg → Elevated; border only → Outlined; no bg/border → Text |
| `<img src>` | `Image.asset(...)` (after asset-export) or `Image.network(...)` if external kept | use `// TODO: assets/<file>` placeholder until asset-export runs |
| `<input type="text">` | `TextField(decoration: ..., controller: _ctrl)` | adds controller field to State |
| `<input type="checkbox">` | `Checkbox(value: ..., onChanged: ...)` |
| `<input type="radio">` | `Radio(...)` |
| `<select>` | `DropdownButton<String>` |
| `<textarea>` | `TextField(maxLines: null, ...)` |
| `<form>` | `Form(key: _formKey, child: Column(...))` |
| `<ul>` / `<ol>` (≤8 items, no scroll) | `Column(children: [...])` |
| `<ul>` / `<ol>` (>8 items or `overflow: auto`) | `ListView(shrinkWrap: true, children: [...])` |
| `<li>` | child of parent Column/ListView |
| `<svg>` | `// TODO: SvgPicture.asset('assets/icons/<name>.svg') — flutter_svg pkg required` placeholder + `Container(width:..., height:...)` |
| `<video>` | `// TODO: video_player package required` placeholder |
| `<table>` | `Table(children: [TableRow(...), ...])` |
| `<hr>` | `Divider()` |
| `<br>` | inserts `\n` into parent Text, or a `SizedBox(height: lineHeight)` if not in Text |
| `<iframe>` | `// TODO: webview_flutter package required` placeholder |

## Composite elements with semantic naming

When an element has a recognizable class name (`card`, `hero`, `nav`, `footer`, `sidebar`, etc.) AND occurs only once, extract it as a private widget at file bottom. Example:

```
class _Card extends StatelessWidget {
  ...
}
```

Helps with later edit-in-place during incremental mode.

## Text consolidation

If a parent has only inline children (`<span>`, plain text, `<strong>`, `<em>`, `<a>`), emit a single `Text.rich(TextSpan(children: [...]))` instead of many widgets. Preserves selection / line-wrapping behavior.

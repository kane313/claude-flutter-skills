# Semantic match against project theme

## Project scan

Read every `.dart` file under `lib/theme/**` (or `lib/theme.dart` if flat). Look for:

1. **ColorScheme entries** — `ColorScheme(primary: Color(0xFFXXXXXX), ...)` or `ColorScheme.fromSeed(...)`.
2. **TextTheme entries** — `TextTheme(headlineLarge: TextStyle(fontSize: X, ...), ...)`.
3. **ThemeExtension** subclasses (project-custom tokens).
4. **Top-level `const Color(...)`** declarations (common pattern for color palettes).

For each extracted value, record a `path` like `colorScheme.primary` or `textTheme.headlineLarge.fontSize` for later code-emission.

## Match rules

### Color match
- Source: HTML token hex.
- Project candidates: every Color value collected.
- Rule: **CIE76 ΔE ≤ 5** (perceptual closeness). Plus alpha must match within ±10/255.
- Tie-break: prefer ColorScheme entries over raw palette consts.

### Font family
- Exact string match (case-insensitive), with one alias resolution layer: a project map e.g. `Inter == fontFamily 'Inter Variable'`. Look for `fontFamily: 'X'` patterns in TextTheme.

### Font size
- Within ±1px of any TextStyle.fontSize. If multiple match, prefer the one whose semantic name (`headlineLarge`, `bodyMedium`, etc.) hints at usage based on HTML element (h1→headline, p→body) — but only as tie-break.

### Line height
- Exact ratio or within ±2px. Match against TextStyle.height.

### Border radius
- Within ±1px of any value found in `BorderRadius.circular(X)` or `BorderRadius.all(Radius.circular(X))` in `lib/theme/**` or known shape themes. If not in theme, fall through to gap.

### Spacing scale
- Within ±1px of `EdgeInsets.*` literals found in widget code referenced from theme files. (Spacing is often not in theme — gap is common here.)

### Box shadow
- Match all five params within tolerance (x/y/blur/spread ±2px, color ΔE ≤ 5).

## Output schema

Each matched HTML token becomes a row:
```json
{
  "html_value": "#ff5722",
  "category": "color",
  "project_path": "colorScheme.primary",
  "project_value": "Color(0xFFFF5722)",
  "confidence": "exact | near (ΔE 3.2)"
}
```

Each gap:
```json
{
  "html_value": "#7c4dff",
  "category": "color",
  "suggested_name": "accent",
  "reason": "no project color within ΔE 5"
}
```

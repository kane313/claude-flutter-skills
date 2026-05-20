# CSS token extraction

## Scope

Extract from the `<style>` blocks of normalized.html and from inline `style="..."` attributes. Ignore tokens used in `@keyframes` (animation values are not design tokens).

## Per category

### Color
- Sources: `color`, `background-color`, `background`, `border-color`, `box-shadow` color stops, `outline-color`, `caret-color`, `text-decoration-color`.
- Normalize: convert `rgb()`, `rgba()`, `hsl()`, named colors → 8-digit hex `#RRGGBBAA` (lowercase). Drop alpha if `FF`.
- Dedup case-insensitively.

### Font family
- Source: `font-family`.
- Take first non-system font (skip `system-ui`, `sans-serif`, `serif`, `monospace`, `-apple-system`, `BlinkMacSystemFont`, etc.).
- Dedup case-insensitively.

### Font size
- Source: `font-size`.
- Normalize: `px`, `rem` (assume 1rem=16px), `em` (relative — record with parent context if possible, else mark unresolved).
- Dedup with ±1px tolerance.

### Line height
- Source: `line-height`.
- Normalize: unitless × font-size, `px`, `rem`. Output as ratio when unitless, px otherwise.

### Border radius
- Source: `border-radius`, `border-top-left-radius`, etc.
- Normalize to px. Dedup with 1px tolerance.

### Spacing scale
- Source: `margin*`, `padding*`, `gap`, `row-gap`, `column-gap`.
- Normalize to px. Cluster into a scale: sort unique values; values within 2px are clustered to the smaller representative. Output the resulting scale.

### Box shadow
- Source: `box-shadow`.
- Parse each shadow into `{x, y, blur, spread, color, inset}`. Output normalized form.

## Output (internal, before template rendering)

```yaml
colors: ["#ff5722", "#2196f3ff", ...]
fonts: ["Inter", "JetBrains Mono"]
font_sizes: [12, 14, 16, 20, 32]
line_heights: ["1.5", "24px"]
radii: [4, 8, 16]
spacing: [4, 8, 16, 24, 32, 48]
shadows:
  - {x: 0, y: 1, blur: 3, spread: 0, color: "#0000001a", inset: false}
```

# CSS → Flutter property map

## Color

| CSS | Flutter |
|---|---|
| `color: X` on Text leaf | `TextStyle(color: <X>)` |
| `background-color: X` on container | `BoxDecoration(color: <X>)` |
| `background: linear-gradient(...)` | `BoxDecoration(gradient: LinearGradient(...))` |
| `background: radial-gradient(...)` | `BoxDecoration(gradient: RadialGradient(...))` |

## Typography

| CSS | Flutter |
|---|---|
| `font-family: X` | `TextStyle(fontFamily: 'X')` |
| `font-size: Xpx` | `TextStyle(fontSize: X)` |
| `font-weight: X` | `TextStyle(fontWeight: FontWeight.w<X>)` (round to nearest 100) |
| `font-style: italic` | `TextStyle(fontStyle: FontStyle.italic)` |
| `line-height: X` (unitless) | `TextStyle(height: X)` |
| `line-height: Xpx` | `TextStyle(height: X / fontSize)` |
| `letter-spacing: Xpx` | `TextStyle(letterSpacing: X)` |
| `text-align: X` | `Text(textAlign: TextAlign.X, ...)` |
| `text-decoration: underline` | `TextStyle(decoration: TextDecoration.underline)` |

## Box / spacing

| CSS | Flutter |
|---|---|
| `padding: X` | wrap with `Padding(padding: EdgeInsets.all(X), ...)` or `Container(padding: ...)` |
| `padding: a b` (vertical/horizontal) | `EdgeInsets.symmetric(vertical: a, horizontal: b)` |
| `padding: a b c d` | `EdgeInsets.fromLTRB(d, a, b, c)` |
| `margin: X` | wrap with `Padding(padding: EdgeInsets.all(X), ...)` (Flutter has no Margin widget; use outer Padding or Container's `margin`) |
| `width: X` / `height: X` | `SizedBox(width: X, height: X, child: ...)` or Container constraints |
| `min-width` / `max-width` | `ConstrainedBox(constraints: BoxConstraints(minWidth: ..., maxWidth: ...), ...)` |

## Border / radius / shadow

| CSS | Flutter |
|---|---|
| `border: Xpx solid Ycolor` | `BoxDecoration(border: Border.all(width: X, color: Y))` |
| `border-radius: X` | `BoxDecoration(borderRadius: BorderRadius.circular(X))` |
| `border-radius: a b c d` | `BoxDecoration(borderRadius: BorderRadius.only(topLeft: ..., ...))` |
| `box-shadow: x y blur spread color` (single) | `BoxDecoration(boxShadow: [BoxShadow(offset: Offset(x, y), blurRadius: blur, spreadRadius: spread, color: Color(...))])` |
| Multi-layer `box-shadow` | list of BoxShadow entries, ordered as in CSS (CSS first layer is on top) |
| `box-shadow: inset ...` | not supported in BoxDecoration — best-effort: ignore inset, emit `// UNSUPPORTED: inset shadow` |

## Transform / filter

| CSS | Flutter |
|---|---|
| `transform: translate(x, y)` | `Transform.translate(offset: Offset(x, y), child: ...)` |
| `transform: scale(s)` | `Transform.scale(scale: s, child: ...)` |
| `transform: rotate(Xdeg)` | `Transform.rotate(angle: X * pi / 180, child: ...)` |
| `opacity: X` | `Opacity(opacity: X, child: ...)` |
| `filter: blur(Xpx)` | `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: X, sigmaY: X), child: ...)` |
| `backdrop-filter: blur(Xpx)` | `BackdropFilter(filter: ImageFilter.blur(...), child: ...)` (wrap inside a ClipRect) |

## Display modifiers (post-Phase-1, mostly stable)

| CSS | Flutter |
|---|---|
| `overflow: hidden` on container | `ClipRect(child: ...)` or `BoxDecoration` clipping behavior |
| `overflow-y: auto` on small container | wrap content in `SingleChildScrollView(child: ...)` (if not already done in Phase 1) |
| `display: none` | wrap in `Visibility(visible: false, child: ...)` or simply omit (omitting is preferred when value is constant) |

## Explicit UNSUPPORTED (emit comment, do not silently drop)

- `clip-path: polygon(...)` (arbitrary polygons)
- `mask: ...`
- Custom CSS variables (`var(--x)`) that we couldn't resolve
- `mix-blend-mode` (Flutter has limited blend mode support; map common ones, mark exotic ones)
- Animations / transitions (Phase 3 handles best-effort)

# Absolute-positioning → Stack detection

## Rule

A parent `P` must be emitted as `Stack` when ANY of its children has `position: absolute` AND `P` does not have `position: static` (the default — Flutter `Stack` mimics CSS `position: relative` containment).

In CSS the rule is:

> An absolutely-positioned child is positioned relative to its **nearest positioned ancestor** (any element with `position: relative | absolute | fixed | sticky`).

We map this to: the *Flutter* parent of the absolute child should be a `Stack`. If the CSS positioning ancestor is several levels up, **emit a Stack at that ancestor**, and pass a regular widget down for the intermediate levels.

## Positioned conversion

| CSS | Flutter `Positioned` arg |
|---|---|
| `top: X` | `top: X` |
| `right: X` | `right: X` |
| `bottom: X` | `bottom: X` |
| `left: X` | `left: X` |
| `width: X` | `width: X` |
| `height: X` | `height: X` |
| no positional CSS (just `position: absolute`) | `Positioned.fill(child: ...)` |

## Non-absolute siblings inside a Stack

Children of the Stack that are NOT absolutely positioned ⇒ wrap each in `Positioned.fill(child: ...)` ⇒ stacked at full size. Or, if there's exactly one such child and it's at the start, emit it as the first child (full-bleed background pattern).

## Z-order

CSS `z-index` does not directly map. In Flutter, last child renders on top. Sort the children by `z-index` ascending (default 0); ties broken by original DOM order.

## Examples

### Hero with overlay

```html
<div class="hero" style="position: relative;">
  <img src="bg.jpg" style="position: absolute; inset: 0;">
  <h1 style="position: absolute; bottom: 24px; left: 24px;">Title</h1>
</div>
```

→

```dart
Stack(
  children: [
    Positioned.fill(child: Image.asset('assets/bg.jpg', fit: BoxFit.cover)),
    Positioned(
      bottom: 24, left: 24,
      child: Text('Title' /* TODO: style */),
    ),
  ],
)
```

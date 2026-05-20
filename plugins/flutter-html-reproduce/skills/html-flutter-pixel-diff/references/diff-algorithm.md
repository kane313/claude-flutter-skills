# Pixel diff algorithm

## Inputs

- `baseline.png` — the HTML reference screenshot.
- `candidate.png` — the Flutter screenshot.

## Resolution alignment

If sizes differ, resize candidate to baseline's dimensions using Lanczos resampling. (Never resize baseline; treat it as ground truth.)

## Per-pixel comparison

Compute per-pixel ΔE (CIE76) over the RGBA channels (treat alpha as opacity in compositing against white). Output:

- `total_pixels` = W × H
- `diff_pixels` = count of pixels with ΔE > 8 (perceptual just-noticeable threshold)
- `overall_diff_rate` = diff_pixels / total_pixels

## Heatmap

For each pixel, output to `diff-heatmap.png`:
- ΔE ≤ 4 → black
- 4 < ΔE ≤ 8 → dark red
- 8 < ΔE ≤ 16 → red
- ΔE > 16 → bright red

Render at the same resolution as baseline.

## Region segmentation

1. Threshold the heatmap at "8 < ΔE" to a binary mask.
2. Run connected-components labelling (8-neighbour).
3. Filter components < 1% of total area.
4. Sort remaining by area DESC.

## Region cause classification

For each top-K (K=3) region:

| Heuristic | Suggested cause |
|---|---|
| Mean ΔE > 30 over solid-colored area | Color mismatch (likely `BoxDecoration(color: ...)` or `TextStyle.color`) |
| Pixel-shifted patch (shape match against baseline at offset X,Y) | Layout offset (likely `padding` or `margin` value off by X / Y) |
| Region present in candidate, absent in baseline | Extra element in Flutter, not in HTML |
| Region present in baseline, absent in candidate | Missing element in Flutter |
| Region overlaps multiple typography contexts | Font / line-height mismatch |

Emit cause heuristic alongside each top-K region.

## Implementation choice

Pure Python with Pillow + numpy is sufficient and dependency-light:

```python
import numpy as np
from PIL import Image

def diff_images(a_path, b_path):
    A = np.asarray(Image.open(a_path).convert("RGB")).astype(np.float32)
    B = np.asarray(Image.open(b_path).convert("RGB")).astype(np.float32)
    if A.shape != B.shape:
        B = np.asarray(
            Image.open(b_path).convert("RGB").resize(
                (A.shape[1], A.shape[0]),
                Image.LANCZOS,
            )
        ).astype(np.float32)
    # CIE76-ish: euclidean RGB (approximation)
    delta = np.sqrt(((A - B) ** 2).sum(axis=2))
    return delta
```

(Real CIE76 is over LAB; for image diff at this resolution, RGB euclidean is a good-enough proxy.)

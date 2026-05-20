#!/usr/bin/env python3
"""Pixel diff utility for html-flutter-pixel-diff skill.

Usage:
  diff.py <baseline.png> <candidate.png> <heatmap.png>

Outputs JSON to stdout with overall diff stats and top regions.
"""
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError:
    print(json.dumps({
        "error": "Pillow + numpy required",
        "install": "pip install Pillow numpy",
    }))
    sys.exit(2)

def main():
    if len(sys.argv) != 4:
        print("usage: diff.py <baseline> <candidate> <heatmap>", file=sys.stderr)
        sys.exit(1)
    base_p, cand_p, heat_p = map(Path, sys.argv[1:4])

    A = np.asarray(Image.open(base_p).convert("RGB"), dtype=np.float32)
    Bimg = Image.open(cand_p).convert("RGB")
    if Bimg.size != (A.shape[1], A.shape[0]):
        Bimg = Bimg.resize((A.shape[1], A.shape[0]), Image.LANCZOS)
    B = np.asarray(Bimg, dtype=np.float32)

    delta = np.sqrt(((A - B) ** 2).sum(axis=2))
    total = delta.size
    diff_count = int((delta > 8).sum())
    rate = diff_count / total

    # Heatmap output
    heat = np.zeros_like(delta, dtype=np.uint8)
    heat[delta > 4] = 80
    heat[delta > 8] = 160
    heat[delta > 16] = 255
    heat_img = Image.fromarray(np.stack([heat, np.zeros_like(heat), np.zeros_like(heat)], axis=2))
    heat_img.save(heat_p)

    # Top regions (very simple: tile the image into 8x8 grid, sort by mean delta)
    H, W = delta.shape
    th, tw = H // 8, W // 8
    regions = []
    for i in range(8):
        for j in range(8):
            r = delta[i*th:(i+1)*th, j*tw:(j+1)*tw]
            if r.size == 0:
                continue
            m = float(r.mean())
            if m > 8:
                regions.append({
                    "row": i, "col": j,
                    "mean_delta": round(m, 2),
                    "bbox": [j*tw, i*th, (j+1)*tw, (i+1)*th],
                })
    regions.sort(key=lambda r: r["mean_delta"], reverse=True)
    top = regions[:3]

    print(json.dumps({
        "overall_diff_rate": round(rate, 4),
        "diff_pixels": diff_count,
        "total_pixels": total,
        "verdict": (
            "green" if rate < 0.10
            else "yellow" if rate < 0.50
            else "red"
        ),
        "top_regions": top,
    }, indent=2))

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Fits the two supplied full-screen paintings to tall phones.

The original art is kept pixel-for-pixel in the middle. Paper and the spiral
binding are continued above and below so 19.5:9 phones need no side crop.
Usage: python3 extend_screens.py <home.png> <splash.png>
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'assets', 'screens')
TARGET_RATIO = 19.5 / 9
SPIRAL_WIDTH = 58


def spiral_period(strip):
    """Finds the repeat distance of the binding rings by autocorrelation."""
    signal = np.asarray(strip.convert('L'), dtype=np.float32).mean(axis=1)
    signal = signal - signal.mean()
    best, score = 50, -1e18
    for lag in range(36, 80):
        value = float((signal[:-lag] * signal[lag:]).mean())
        if value > score:
            best, score = lag, value
    return best


def extend(source, name):
    art = Image.open(source).convert('RGB')
    width, height = art.size
    extra = max(int(round(width * TARGET_RATIO)) - height, 0) // 2
    grain = np.random.default_rng(7).normal(0, 1.6, (height + extra * 2, width))[..., None]
    arr = np.asarray(art, dtype=np.float32)
    top_row = np.asarray(Image.fromarray(arr[:6].mean(axis=0, keepdims=True).astype(np.uint8)).resize((width, 1)).filter(ImageFilter.BoxBlur(0)), dtype=np.float32)
    bottom_row = arr[-6:].mean(axis=0, keepdims=True)

    def smooth(row):
        kernel = np.ones(121) / 121
        return np.stack([np.convolve(np.pad(row[0, :, c], 60, mode='edge'), kernel, 'valid') for c in range(3)], axis=1)[None]

    top = np.repeat(smooth(top_row), extra, axis=0)
    bottom = np.repeat(smooth(bottom_row), extra, axis=0)
    canvas = np.concatenate([top, arr, bottom], axis=0) + grain
    # Feather the seam with the art.
    feather = 28
    for i in range(feather):
        t = i / feather
        canvas[extra + i] = (top[0] + grain[extra + i]) * (1 - t) + canvas[extra + i] * t
        row = extra + height - 1 - i
        canvas[row] = (bottom[0] + grain[row]) * (1 - t) + canvas[row] * t
    result = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8))
    strip = art.crop((0, 200, SPIRAL_WIDTH, 1400))
    period = spiral_period(strip)
    tile = art.crop((0, 400, SPIRAL_WIDTH, 400 + period))
    for y in range(extra + 400 - period, -period, -period):
        result.paste(tile, (0, y))
    for y in range(extra + 400 + period * ((height - 460) // period), height + extra * 2, period):
        result.paste(tile, (0, y))
    os.makedirs(OUT, exist_ok=True)
    result.save(os.path.join(OUT, name), 'WEBP', quality=90, method=5)
    print(name, result.size, 'art at y =', extra, 'height', height, 'ring period', period)


if __name__ == '__main__':
    extend(sys.argv[1], 'home.webp')
    extend(sys.argv[2], 'splash.webp')

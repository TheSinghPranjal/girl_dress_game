"""Cuts each character's real face out of the supplied reference paintings.

The face is kept pixel-faithful: it is only enlarged to the shared canvas and
cut along its own jawline. Skin colour for the rest of the figure is sampled
from the same painting so the body matches the face.
"""
import os

import numpy as np
from PIL import Image, ImageFilter

from engine import CX, W

HERE = os.path.dirname(__file__)
SCALE = 2.4
CHIN_Y = 360
SKIN_TOLERANCE = 34
JAW_DEPTH = 88
FACE_TOP = 192
FADE = 26
BROW_LINE = 150


def _flood(mask, seed):
    """Connected region of True cells containing seed (4-neighbour)."""
    h, w = mask.shape
    seen = np.zeros_like(mask)
    stack = [seed]
    while stack:
        y, x = stack.pop()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not mask[y, x]:
            continue
        seen[y, x] = True
        stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    return seen


def _fill_holes(mask):
    outside = _flood(np.pad(~mask, 1, constant_values=True), (0, 0))[1:-1, 1:-1]
    return ~outside


def _solid_face(region, cx, chin):
    """Builds the face shape: the painted jaw below the nose, a whole upper face above.

    Above the nose a colour trace breaks wherever fringe or lashes touch, so
    that part simply keeps the full cheek width. Hair covers its outer edge.
    """
    h, w = region.shape
    nose = chin - JAW_DEPTH
    solid = np.zeros_like(region)
    spans = {}
    for y in range(nose, chin + 1):
        xs = np.nonzero(region[y])[0]
        if len(xs):
            spans[y] = (int(xs.min()), int(xs.max()))
    for y, (x0, x1) in spans.items():
        solid[y, x0:x1 + 1] = True
    cheek = [spans[y] for y in spans if y < nose + 26]
    half = max(max(cx - a, b - cx) for a, b in cheek)
    for y in range(max(chin - FACE_TOP, 0), nose):
        # Narrow above the brows, so painted temple hair is left behind.
        above_brows = min(max(chin - BROW_LINE - y, 0) / 26, 1)
        reach = half * (1 - .3 * above_brows)
        solid[y, max(int(cx - reach), 0):min(int(cx + reach) + 1, w)] = True
    return solid


def _locate(rgb):
    """Finds the nose seed, cheek colour, face centre and chin row."""
    h, w, _ = rgb.shape
    box = rgb[int(h * .42):int(h * .56), int(w * .36):int(w * .62)]
    light = box.reshape(-1, 3)
    light = light[light.sum(axis=1) > np.percentile(light.sum(axis=1), 55)]
    skin = np.median(light, axis=0)
    close = np.linalg.norm(rgb - skin, axis=2) < SKIN_TOLERANCE
    seed_box = close[int(h * .46):int(h * .52), int(w * .42):int(w * .56)]
    ys, xs = np.nonzero(seed_box)
    mid_y, mid_x = np.median(ys), np.median(xs)
    nearest = np.argmin((ys - mid_y) ** 2 + (xs - mid_x) ** 2)
    seed = (int(h * .46) + int(ys[nearest]), int(w * .42) + int(xs[nearest]))
    region = _flood(close, seed)
    row = rgb.mean(axis=2)
    # Centre: mean of the widest cheek rows.
    cheeks = region[seed[0] - 20:seed[0] + 20]
    cx = float(np.nonzero(cheeks)[1].mean())
    # Chin: the first dark jaw line down the centre, below the lips.
    column = row[:, int(round(cx)) - 3:int(round(cx)) + 4].mean(axis=1)
    first, last = seed[0] + int(h * .145), seed[0] + int(h * .215)
    chin = first + int(np.argmin(column[first:last]))
    return skin, cx, chin, seed


def load_face(character_id):
    """Returns (rgba array, canvas x, canvas y, skin hex) for one character."""
    source = Image.open(os.path.join(HERE, 'reference', f'{character_id}_head.png')).convert('RGB')
    big = source.resize((int(source.width * SCALE), int(source.height * SCALE)), Image.LANCZOS)
    big = big.filter(ImageFilter.UnsharpMask(radius=2.2, percent=70, threshold=2))
    rgb = np.asarray(big, dtype=np.float32)
    skin, cx, chin, seed = _locate(rgb)
    close = np.linalg.norm(rgb - skin, axis=2) < SKIN_TOLERANCE
    close[chin + 2:] = False
    traced = _fill_holes(_flood(close, seed))
    chin = int(np.nonzero(traced.any(axis=1))[0].max())
    region = _solid_face(traced, cx, chin)
    grown = Image.fromarray((region * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))
    alpha = np.asarray(grown.filter(ImageFilter.GaussianBlur(1.1)), dtype=np.float32) / 255
    alpha[chin + 7:] = 0
    # Fade out above the brows, where the plain scalp and hair take over.
    fade_end = chin - FACE_TOP + FADE
    alpha[:fade_end] *= np.clip((np.arange(fade_end) - (chin - FACE_TOP)) / FADE, 0, 1)[:, None]
    x = int(round(CX - cx))
    y = int(round(CHIN_Y - chin))
    rgba = np.dstack([rgb / 255, alpha])
    hex_skin = '#%02X%02X%02X' % tuple(int(v) for v in skin)
    return rgba, x, y, hex_skin


def stamp_face(layer, character_id):
    rgba, x, y, _ = load_face(character_id)
    h, w, _ = rgba.shape
    if x < 0:
        rgba = rgba[:, -x:]
        x = 0
    if y < 0:
        rgba = rgba[-y:]
        y = 0
    rgba = rgba[:, :W - x]
    layer._over(x, y, rgba[..., :3], rgba[..., 3])


def skin_of(character_id):
    return load_face(character_id)[3]

"""Pencil-and-watercolour raster engine used by the Help Me Dress art pipeline.

Every layer is painted on the shared 1024x2048 character canvas. Shapes are
built from splines, filled with a watercolour wash and finished with a wobbly
pencil line, so all characters and garments share one illustration language.
"""
import hashlib
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

W, H = 1024, 2048
CX = W / 2
SS = 2

INK = (73, 56, 47)
BROWN = (104, 74, 60)


def rgb(value):
    if isinstance(value, tuple):
        return value
    value = value.lstrip('#')
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def seed_of(text):
    return int(hashlib.md5(text.encode()).hexdigest()[:8], 16)


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _noise_tile(seed, cell):
    rng = np.random.default_rng(seed)
    base = rng.random((H // cell + 2, W // cell + 2), dtype=np.float32)
    img = Image.fromarray((base * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    arr = np.asarray(img, dtype=np.float32) / 255
    return (arr - arr.mean()) / (arr.std() + 1e-6)


BLOTCH = _noise_tile(11, 96)
MOTTLE = _noise_tile(23, 10)
_grain_rng = np.random.default_rng(5)
GRAIN = _grain_rng.normal(0, 1, (H, W)).astype(np.float32)


def spline(points, closed=False, steps=12):
    """Catmull-Rom spline through points. Repeat a point to make a corner."""
    pts = list(points)
    if len(pts) < 3:
        return pts
    out = []
    n = len(pts)
    span = n if closed else n - 1
    for i in range(span):
        if closed:
            p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        else:
            p0 = pts[max(i - 1, 0)]
            p1 = pts[i]
            p2 = pts[min(i + 1, n - 1)]
            p3 = pts[min(i + 2, n - 1)]
        for k in range(steps):
            t = k / steps
            t2, t3 = t * t, t * t * t
            x = 0.5 * (2 * p1[0] + (p2[0] - p0[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2
                       + (3 * p1[0] - p0[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * (2 * p1[1] + (p2[1] - p0[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
                       + (3 * p1[1] - p0[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    if not closed:
        out.append(pts[-1])
    return out


def R(*dxy):
    """Right-of-centre point list from (dx, y) pairs."""
    return [(CX + dx, y) for dx, y in dxy]


def flip(points):
    return [(W - x, y) for x, y in points]


def symmetric(right):
    """Closed polygon from a right-side contour running top to bottom."""
    return right + flip(right)[::-1]


def resample(points, count):
    pts = np.array(points, dtype=np.float32)
    seg = np.hypot(*(pts[1:] - pts[:-1]).T)
    dist = np.concatenate([[0], np.cumsum(seg)])
    if dist[-1] == 0:
        return [tuple(pts[0])] * count
    t = np.linspace(0, dist[-1], count)
    return list(zip(np.interp(t, dist, pts[:, 0]), np.interp(t, dist, pts[:, 1])))


def ribbon(center, widths, steps=None):
    """Polygon around a centreline with interpolated half-widths."""
    count = steps or max(10, int(sum(math.dist(center[i], center[i + 1]) for i in range(len(center) - 1)) / 8))
    line = resample(spline(center) if len(center) > 2 else center, count)
    w = np.interp(np.linspace(0, 1, count), np.linspace(0, 1, len(widths)), widths)
    left, right = [], []
    for i, (x, y) in enumerate(line):
        ax, ay = line[max(i - 1, 0)]
        bx, by = line[min(i + 1, count - 1)]
        dx, dy = bx - ax, by - ay
        length = math.hypot(dx, dy) or 1
        nx, ny = -dy / length, dx / length
        left.append((x + nx * w[i], y + ny * w[i]))
        right.append((x - nx * w[i], y - ny * w[i]))
    return left + right[::-1]


class Mask:
    def __init__(self, x, y, arr):
        self.x, self.y, self.arr = x, y, arr

    @property
    def empty(self):
        return self.arr.size == 0 or self.arr.max() <= 0

    def minus(self, other):
        result = self.arr.copy()
        x0 = max(self.x, other.x)
        y0 = max(self.y, other.y)
        x1 = min(self.x + self.arr.shape[1], other.x + other.arr.shape[1])
        y1 = min(self.y + self.arr.shape[0], other.y + other.arr.shape[0])
        if x1 > x0 and y1 > y0:
            result[y0 - self.y:y1 - self.y, x0 - self.x:x1 - self.x] *= (
                1 - other.arr[y0 - other.y:y1 - other.y, x0 - other.x:x1 - other.x])
        return Mask(self.x, self.y, result)

    def times(self, other):
        full = np.zeros_like(self.arr)
        x0 = max(self.x, other.x)
        y0 = max(self.y, other.y)
        x1 = min(self.x + self.arr.shape[1], other.x + other.arr.shape[1])
        y1 = min(self.y + self.arr.shape[0], other.y + other.arr.shape[0])
        if x1 > x0 and y1 > y0:
            full[y0 - self.y:y1 - self.y, x0 - self.x:x1 - self.x] = (
                self.arr[y0 - self.y:y1 - self.y, x0 - self.x:x1 - self.x]
                * other.arr[y0 - other.y:y1 - other.y, x0 - other.x:x1 - other.x])
        return Mask(self.x, self.y, full)


def poly_mask(polys, holes=(), pad=14):
    polys = [p for p in polys if len(p) > 2]
    xs = [pt[0] for poly in polys for pt in poly]
    ys = [pt[1] for poly in polys for pt in poly]
    x0, y0 = max(int(min(xs)) - pad, 0), max(int(min(ys)) - pad, 0)
    x1, y1 = min(int(max(xs)) + pad, W), min(int(max(ys)) + pad, H)
    size = (max(x1 - x0, 1) * SS, max(y1 - y0, 1) * SS)
    img = Image.new('L', size, 0)
    draw = ImageDraw.Draw(img)
    for poly in polys:
        draw.polygon([((x - x0) * SS, (y - y0) * SS) for x, y in poly], fill=255)
    for poly in holes:
        draw.polygon([((x - x0) * SS, (y - y0) * SS) for x, y in poly], fill=0)
    img = img.resize((x1 - x0, y1 - y0), Image.LANCZOS)
    return Mask(x0, y0, np.asarray(img, dtype=np.float32) / 255)


def _blur(arr, radius):
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8))
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32) / 255


class Layer:
    """A premultiplied RGBA layer on the shared canvas."""

    def __init__(self, seed='layer'):
        self.rgb = np.zeros((H, W, 3), dtype=np.float32)
        self.alpha = np.zeros((H, W), dtype=np.float32)
        self.rng = random.Random(seed_of(str(seed)))
        self.shift = seed_of(str(seed)) % 900

    def _over(self, x, y, color, alpha):
        h, w = alpha.shape
        target_rgb = self.rgb[y:y + h, x:x + w]
        target_a = self.alpha[y:y + h, x:x + w]
        premult = color * alpha[..., None]
        self.rgb[y:y + h, x:x + w] = premult + target_rgb * (1 - alpha[..., None])
        self.alpha[y:y + h, x:x + w] = alpha + target_a * (1 - alpha)

    def _noise(self, source, m):
        h, w = m.arr.shape
        rolled_y = (m.y + self.shift) % (H - h) if H > h else 0
        rolled_x = (m.x + self.shift // 2) % (W - w) if W > w else 0
        return source[rolled_y:rolled_y + h, rolled_x:rolled_x + w]

    def wash(self, m, color, shade=0.3, edge=0.16, bleed=0.05, pattern=None, line=1.0,
             line_color=INK, volume=30, side=0.08, alpha=1.0):
        """Paint a watercolour fill with soft volume, pooled edges and a pencil line."""
        if m.empty:
            return
        base = np.array(rgb(color), dtype=np.float32) / 255
        h, w = m.arr.shape
        col = np.ones((h, w, 3), dtype=np.float32) * base
        if pattern is not None:
            yy, xx = np.mgrid[m.y:m.y + h, m.x:m.x + w].astype(np.float32)
            col = pattern(xx, yy, col)
        shadow_tint = np.array([0.74, 0.62, 0.70], dtype=np.float32)
        vol = _blur(m.arr, volume)
        vol = np.clip(vol / max(vol.max(), 1e-3), 0, 1)
        pool = np.clip(1 - _blur(m.arr, 5) * 1.05, 0, 1)
        blotch = self._noise(BLOTCH, m)
        mottle = self._noise(MOTTLE, m)
        grain = self._noise(GRAIN, m)
        ramp = np.linspace(-1, 1, w, dtype=np.float32)[None, :]
        dark = (1 - vol) ** 1.6 * shade + np.clip(ramp, 0, 1) * side + np.clip(blotch, -1.4, 1.6) * bleed
        dark = np.clip(dark, -0.16, 0.75)[..., None]
        shadow = col * shadow_tint
        light = col + (1 - col) * 0.7
        painted = np.where(dark >= 0, col + (shadow - col) * dark, col + (light - col) * -dark)
        painted = painted * (1 - pool[..., None] * edge)
        painted += (mottle * 0.004 + grain * 0.009)[..., None]
        painted = np.clip(painted, 0, 1)
        self._over(m.x, m.y, painted, m.arr * alpha)
        if line > 0:
            self.outline(m, line_color, line)

    def outline(self, m, color=INK, weight=1.0):
        pad = 6
        arr = np.pad(m.arr, pad)
        x, y = m.x - pad, m.y - pad
        x0, y0 = max(-x, 0), max(-y, 0)
        arr = arr[y0:, x0:]
        arr = arr[:H - max(y, 0), :W - max(x, 0)]
        x, y = max(x, 0), max(y, 0)
        sharp = _blur(arr, 1.25 * weight)
        band = np.clip(1 - np.abs(sharp - 0.5) / 0.34, 0, 1) ** 0.7
        probe = Mask(x, y, arr)
        tooth = np.clip(0.8 + self._noise(MOTTLE, probe) * 0.22 + self._noise(GRAIN, probe) * 0.12, 0.3, 1)
        col = np.ones(arr.shape + (3,), dtype=np.float32) * (np.array(rgb(color), dtype=np.float32) / 255)
        self._over(x, y, col, band * tooth * 0.92)

    def fill(self, polys, color, holes=(), **kw):
        m = poly_mask(polys, holes)
        self.wash(m, color, **kw)
        return m

    def pencil(self, points, color=INK, width=2.0, alpha=0.75, taper=True, curve=True, clip=None, solid=False):
        line = spline(points) if curve and len(points) > 2 else list(points)
        if len(line) < 2:
            return
        xs = [p[0] for p in line]
        ys = [p[1] for p in line]
        pad = int(width + 6)
        x0, y0 = max(int(min(xs)) - pad, 0), max(int(min(ys)) - pad, 0)
        x1, y1 = min(int(max(xs)) + pad, W), min(int(max(ys)) + pad, H)
        if x1 <= x0 or y1 <= y0:
            return
        img = Image.new('L', ((x1 - x0) * SS, (y1 - y0) * SS), 0)
        draw = ImageDraw.Draw(img)
        n = len(line)
        for i in range(n - 1):
            t = i / max(n - 2, 1)
            press = (math.sin(t * math.pi) ** 0.5) if taper else 1.0
            ww = max(1, width * SS * (0.45 + 0.55 * press))
            a = ((line[i][0] - x0) * SS, (line[i][1] - y0) * SS)
            b = ((line[i + 1][0] - x0) * SS, (line[i + 1][1] - y0) * SS)
            draw.line([a, b], fill=255, width=int(round(ww)))
            draw.ellipse([b[0] - ww / 2, b[1] - ww / 2, b[0] + ww / 2, b[1] + ww / 2], fill=255)
        img = img.resize((x1 - x0, y1 - y0), Image.LANCZOS)
        arr = np.asarray(img, dtype=np.float32) / 255
        m = Mask(x0, y0, arr)
        if clip is not None:
            m = m.times(clip)
            arr = m.arr
        tooth = 1.0 if solid else np.clip(0.82 + self._noise(GRAIN, m) * 0.14, 0.35, 1)
        col = np.ones(arr.shape + (3,), dtype=np.float32) * (np.array(rgb(color), dtype=np.float32) / 255)
        self._over(x0, y0, col, arr * tooth * alpha)

    def soft(self, cx, cy, rx, ry, color, alpha=0.3, clip=None):
        """Airbrushed ellipse, used for blush and soft shadows."""
        x0, y0 = max(int(cx - rx * 1.6), 0), max(int(cy - ry * 1.6), 0)
        x1, y1 = min(int(cx + rx * 1.6), W), min(int(cy + ry * 1.6), H)
        yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
        arr = np.clip(np.exp(-d * 1.4) * alpha, 0, 1)
        m = Mask(x0, y0, arr)
        if clip is not None:
            m = m.times(clip)
        col = np.ones(arr.shape + (3,), dtype=np.float32) * (np.array(rgb(color), dtype=np.float32) / 255)
        self._over(x0, y0, col, m.arr)

    def stamp(self, other):
        a = other.alpha[..., None]
        self.rgb = other.rgb + self.rgb * (1 - a)
        self.alpha = other.alpha + self.alpha * (1 - other.alpha)

    def to_image(self):
        a = np.clip(self.alpha, 0, 1)
        safe = np.where(a > 1e-4, a, 1)[..., None]
        straight = np.clip(self.rgb / safe, 0, 1)
        data = np.dstack([straight, a])
        return Image.fromarray((data * 255).astype(np.uint8), 'RGBA')


# ---- fabric patterns ------------------------------------------------------

def stripes_h(color, period=46, band=20, slant=0.0):
    c = np.array(rgb(color), dtype=np.float32) / 255

    def apply(xx, yy, col):
        t = np.mod(yy + xx * slant, period)
        edge = np.clip((band - t) / 2.2, 0, 1)[..., None]
        return col * (1 - edge) + c * edge
    return apply


def plaid(color, color2=None, period=66):
    c = np.array(rgb(color), dtype=np.float32) / 255
    c2 = np.array(rgb(color2 or color), dtype=np.float32) / 255

    def apply(xx, yy, col):
        h = (np.mod(yy, period) < period * 0.42)[..., None].astype(np.float32)
        v = (np.mod(xx, period) < period * 0.42)[..., None].astype(np.float32)
        out = col * (1 - h * 0.42) + c * h * 0.42
        out = out * (1 - v * 0.42) + c * v * 0.42
        thin = (np.mod(yy + period * 0.7, period) < 3)[..., None].astype(np.float32)
        thin2 = (np.mod(xx + period * 0.7, period) < 3)[..., None].astype(np.float32)
        out = out * (1 - thin * 0.6) + c2 * thin * 0.6
        return out * (1 - thin2 * 0.6) + c2 * thin2 * 0.6
    return apply


def denim():
    def apply(xx, yy, col):
        weave = np.sin((xx + yy) * 1.15) * 0.022 + np.sin((xx - yy * 0.4) * 0.05) * 0.025
        fade = np.sin(yy * 0.009 + xx * 0.012) * 0.022
        return np.clip(col + (weave + fade)[..., None], 0, 1)
    return apply


def knit():
    def apply(xx, yy, col):
        rib = np.sin(xx * 0.42 + np.sin(yy * 0.2) * 2.2) * 0.045
        return np.clip(col + rib[..., None], 0, 1)
    return apply


def dots(color, period=52, radius=8):
    c = np.array(rgb(color), dtype=np.float32) / 255

    def apply(xx, yy, col):
        row = np.floor(yy / period)
        px = np.mod(xx + row * period / 2, period) - period / 2
        py = np.mod(yy, period) - period / 2
        edge = np.clip(radius + 1 - np.hypot(px, py), 0, 1)[..., None]
        return col * (1 - edge) + c * edge
    return apply


def _motif_positions(period):
    row = 0
    y = 0
    while y < H:
        x = (period / 2) if row % 2 else 0
        while x < W:
            yield x, y, row
            x += period
        y += period * 0.82
        row += 1


def _motif_pattern(stamp, period, seed):
    """Rasterise a motif across the canvas once, then reuse it for any shape."""
    cache = {}

    def apply(xx, yy, col):
        if 'tile' not in cache:
            img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)
            rng = random.Random(seed)
            for x, y, _ in _motif_positions(period):
                stamp(draw, x + rng.uniform(-8, 8), y + rng.uniform(-8, 8), rng)
            cache['tile'] = np.asarray(img.filter(ImageFilter.GaussianBlur(0.7)), dtype=np.float32) / 255
        ty0, tx0 = int(yy[0, 0]), int(xx[0, 0])
        tile = cache['tile'][ty0:ty0 + xx.shape[0], tx0:tx0 + xx.shape[1]]
        a = tile[..., 3:]
        return col * (1 - a) + tile[..., :3] * a
    return apply


def florals(petal, center='#F2D27A', leaf='#9DB58F', period=74, size=15, seed=3):
    p, c, l = rgb(petal), rgb(center), rgb(leaf)

    def stamp(draw, x, y, rng):
        s = size * rng.uniform(0.75, 1.15)
        a0 = rng.uniform(0, 6.28)
        draw.ellipse([x + s * 0.9 - s * .45, y + s * 1.0 - s * .22, x + s * 0.9 + s * .45, y + s * 1.0 + s * .22], fill=l + (255,))
        for k in range(5):
            a = a0 + k * 2 * math.pi / 5
            px, py = x + math.cos(a) * s * 0.7, y + math.sin(a) * s * 0.7
            draw.ellipse([px - s * .55, py - s * .55, px + s * .55, py + s * .55], fill=p + (255,))
        draw.ellipse([x - s * .3, y - s * .3, x + s * .3, y + s * .3], fill=c + (255,))
    return _motif_pattern(stamp, period, seed)


def hearts(color, period=78, size=11, seed=5):
    k = rgb(color)

    def stamp(draw, x, y, rng):
        s = size * rng.uniform(0.8, 1.2)
        draw.ellipse([x - s, y - s * .8, x, y + s * .2], fill=k + (255,))
        draw.ellipse([x, y - s * .8, x + s, y + s * .2], fill=k + (255,))
        draw.polygon([(x - s * .96, y - s * .15), (x + s * .96, y - s * .15), (x, y + s * 1.2)], fill=k + (255,))
    return _motif_pattern(stamp, period, seed)


def combine(*patterns):
    def apply(xx, yy, col):
        for pattern in patterns:
            col = pattern(xx, yy, col)
        return col
    return apply

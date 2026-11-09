"""Room decorations, sketchbook page and paper props in the shared style."""
import math
import random

import numpy as np
from PIL import Image

from body import _bow, circle
from engine import BROWN, CX, H, INK, R, W, Layer, flip, mix, poly_mask, ribbon, spline
from garments import graphic_flower, graphic_heart

SKETCH = mix(BROWN, '#FFFFFF', .12)


def _flower(l, x, y, s, petal='#F4AFC0'):
    for k in range(5):
        a = k * 1.2566 - 1.57
        px, py = x + math.cos(a) * s * .72, y + math.sin(a) * s * .72
        poly = ribbon([(x, y), (px, py), (x + math.cos(a) * s * 1.28, y + math.sin(a) * s * 1.28)], [s * .16, s * .56, s * .22], steps=12)
        l.fill([poly], petal, shade=.42, edge=.14, bleed=.05, line=.72, line_color=mix(INK, petal, .3), volume=max(3, int(s * .28)))
    l.fill([circle(x, y, s * .26, 12)], '#EFC870', shade=.3, line=.6, volume=2)


def _leaf(l, x, y, a, s, color='#A4BC93'):
    tip = (x + math.cos(a) * s, y + math.sin(a) * s)
    mid = (x + math.cos(a) * s * .5, y + math.sin(a) * s * .5)
    l.fill([ribbon([(x, y), mid, tip], [1.5, s * .24, 1], steps=12)], color, shade=.35, edge=.12, line=.68, line_color=mix(INK, color, .3), volume=3)
    l.pencil([(x, y), tip], mix(INK, color, .4), 1.2, .5, curve=False)


def sprig(l, x, y, length=280, turn=.5, flowers=2, seed=1):
    rng = random.Random(seed)
    pts = [(x, y), (x + length * .25 * turn, y - length * .45), (x + length * .62 * turn, y - length)]
    l.pencil(pts, '#7E9570', 3.5, .9)
    line = spline(pts)
    for i in range(3, len(line) - 2, 4):
        px, py = line[i]
        _leaf(l, px, py, -1.57 + (1 if i % 8 else -1) * 1.05 + rng.uniform(-.2, .2), 58)
    for k in range(flowers):
        px, py = line[int((len(line) - 1) * (1 - k * .32))]
        _flower(l, px + k * 18, py, 52 - k * 11)


def mannequin(l):
    ox, oy = 420, 150
    sk = SKETCH
    body = [(ox - 130, oy + 100), (ox - 60, oy + 60), (ox + 60, oy + 60), (ox + 130, oy + 100), (ox + 118, oy + 280), (ox + 72, oy + 420),
            (ox + 240, oy + 700), (ox - 240, oy + 700), (ox - 72, oy + 420), (ox - 118, oy + 280)]
    l.fill([spline(body, closed=True)], '#FFF8EF', shade=.1, edge=.06, bleed=.02, line=.95, line_color=sk, volume=30)
    l.fill([ribbon([(ox, oy - 30), (ox, oy + 62)], [34, 56], steps=8)], '#F2E4CF', shade=.2, edge=.08, line=.8, line_color=sk, volume=6)
    l.fill([circle(ox, oy - 54, 26, 16)], '#CBA57E', shade=.3, line=.85, volume=5)
    for pts in ([(ox, oy + 62), (ox + 10, oy + 240), (ox, oy + 420)], [(ox - 70, oy + 76), (ox - 56, oy + 240), (ox - 72, oy + 420)],
                [(ox + 70, oy + 76), (ox + 56, oy + 240), (ox + 72, oy + 420)], [(ox - 112, oy + 300), (ox, oy + 330), (ox + 112, oy + 300)],
                [(ox - 72, oy + 420), (ox, oy + 440), (ox + 72, oy + 420)]):
        l.pencil(pts, sk, 1.9, .55)
    for t in (-.72, -.36, 0, .36, .72):
        l.pencil([(ox + t * 72, oy + 430), (ox + t * 220, oy + 700)], sk, 1.8, .46)
    l.fill([[(ox - 11, oy + 700), (ox + 11, oy + 700), (ox + 11, oy + 960), (ox - 11, oy + 960)]], '#C4A37C', shade=.3, line=.8, line_color=sk, volume=4)
    for k in range(4):
        l.pencil([(ox - 250 + k * 8, oy + 710 + k * 26), (ox - 40, oy + 960 - k * 40)], sk, 1.2, .2)


def polaroid(l, tint='#F9D6DD', dress='#F7BCCB'):
    ox, oy = 420, 160
    frame = [(ox - 240, oy), (ox + 240, oy), (ox + 240, oy + 560), (ox - 240, oy + 560)]
    l.fill([frame], '#FFFDF8', shade=.05, edge=.06, bleed=.01, line=.9, line_color=SKETCH, volume=8)
    inner = [(ox - 200, oy + 40), (ox + 200, oy + 40), (ox + 200, oy + 500), (ox - 200, oy + 500)]
    l.fill([inner], tint, shade=.12, edge=.2, bleed=.08, line=0, volume=20)
    bod = [(ox - 44, oy + 190), (ox + 44, oy + 190), (ox + 34, oy + 280), (ox - 34, oy + 280)]
    sk = [(ox - 34, oy + 278), (ox + 34, oy + 278), (ox + 160, oy + 450), (ox - 160, oy + 450)]
    l.fill([sk], dress, shade=.3, edge=.14, line=.9, line_color=mix(INK, dress, .25), volume=20)
    l.fill([bod], dress, shade=.2, edge=.1, line=.9, line_color=mix(INK, dress, .25), volume=8)
    for t in (-.66, -.3, .06, .4, .74):
        l.pencil([(ox + t * 34, oy + 290), (ox + t * 150, oy + 448)], mix(INK, dress, .3), 1.8, .4)
    l.pencil([(ox, oy + 120), (ox, oy + 190)], SKETCH, 3, .75, curve=False)
    l.fill([circle(ox, oy + 116, 10, 10)], '#CBA57E', shade=.3, line=.7, volume=3)
    l.fill([[(ox - 70, oy - 34), (ox + 70, oy - 34), (ox + 70, oy + 34), (ox - 70, oy + 34)]], '#F2E1B9', shade=.1, edge=.1, line=.6, line_color=SKETCH, volume=6, alpha=.92)


def books(l):
    ox, oy = 420, 560
    for i, color in enumerate(('#F4C9D2', '#F2E4CF', '#F6D7DE')):
        y = oy + i * 52 - 30
        w = 260 - i * 22 + (i % 2) * 18
        l.fill([[(ox - w, y), (ox + w, y), (ox + w + 4, y + 50), (ox - w - 4, y + 50)]], color, shade=.2, edge=.1, line=.9, line_color=SKETCH, volume=8)
        l.pencil([(ox - w + 30, y + 26), (ox + w - 10, y + 26)], SKETCH, 1.4, .4, curve=False)


def vase_flowers(l, cx=420, base=560):
    books(l)
    vase = [(cx - 30, base - 180), (cx + 30, base - 180), (cx + 72, base - 90), (cx + 66, base - 34), (cx - 66, base - 34), (cx - 72, base - 90)]
    for i, (a, s) in enumerate(((-.6, 310), (-.25, 350), (.1, 340), (.42, 310), (.72, 270))):
        x = cx + math.sin(a) * s
        y = base - 180 - math.cos(a) * s
        l.pencil([(cx + a * 18, base - 120), (cx + a * 80, base - 260), (x, y)], '#7E9570', 3.4, .9)
        _leaf(l, cx + a * 100, base - 280, -1.57 + (1 if i % 2 else -1) * .9, 74)
    for i, (a, s) in enumerate(((-.6, 310), (-.25, 350), (.1, 340), (.42, 310), (.72, 270))):
        _flower(l, cx + math.sin(a) * s, base - 180 - math.cos(a) * s, 62 - (i % 2) * 8)
    l.fill([spline(vase, closed=True)], '#E9F2F1', shade=.22, edge=.2, line=.9, line_color=SKETCH, volume=14, alpha=.75)


def window_vanity(l):
    ox, oy = 410, 130
    w, h = 200, 640
    arch = [(ox - w, oy + h), (ox - w, oy + 200)] + [(ox + math.cos(math.pi + t * math.pi) * w, oy + 200 + math.sin(math.pi + t * math.pi) * 200) for t in np.linspace(0, 1, 26)] + [(ox + w, oy + h)]
    l.fill([arch], '#DCEBF5', shade=.14, edge=.12, bleed=.1, line=1.1, line_color=SKETCH, volume=40)
    for i in range(7):
        _flower(l, ox - 150 + i * 46, oy + h - 30 - (i * 83) % 190, 34, '#F7C2CF')
    l.pencil([(ox, oy), (ox, oy + h)], SKETCH, 7, .7, curve=False, taper=False)
    l.pencil([(ox - w, oy + 300), (ox + w, oy + 300)], SKETCH, 7, .7, curve=False, taper=False)
    l.pencil([(ox - w, oy + h), (ox + w, oy + h)], SKETCH, 9, .75, curve=False, taper=False)
    l.fill([[(ox - w - 30, oy + h), (ox + w + 30, oy + h), (ox + w + 22, oy + h + 34), (ox - w - 22, oy + h + 34)]], '#FBF2E5', shade=.1, edge=.08, line=.9, line_color=SKETCH, volume=6)
    # Dresser
    dy = oy + h + 150
    l.fill([[(ox - 240, dy), (ox + 240, dy), (ox + 220, dy + 40), (ox - 220, dy + 40)]], '#FAF0E2', shade=.12, edge=.08, line=.95, line_color=SKETCH, volume=6)
    l.fill([[(ox - 200, dy + 40), (ox + 200, dy + 40), (ox + 200, dy + 500), (ox - 200, dy + 500)]], '#FBF4E9', shade=.16, edge=.08, line=.95, line_color=SKETCH, volume=14)
    for k in range(3):
        y = dy + 60 + k * 148
        l.pencil([(ox - 170, y), (ox + 170, y), (ox + 170, y + 126), (ox - 170, y + 126), (ox - 170, y)], SKETCH, 2, .55, curve=False)
        l.fill([circle(ox, y + 62, 13, 12)], '#D7B481', shade=.3, line=.75, volume=3)
    for s in (-1, 1):
        l.fill([[(ox + s * 180 - 16, dy + 500), (ox + s * 180 + 16, dy + 500), (ox + s * 176 + 8, dy + 580), (ox + s * 176 - 8, dy + 580)]], '#F5E8D5', shade=.15, line=.85, line_color=SKETCH, volume=4)
    jar = [(ox - 46, dy - 110), (ox + 46, dy - 110), (ox + 46, dy), (ox - 46, dy)]
    for i, a in enumerate((-.4, -.14, .12, .4)):
        l.pencil([(ox + a * 30, dy - 40), (ox + a * 120, dy - 200)], '#C4A37C', 5, .85, curve=False)
        l.fill([circle(ox + a * 124, dy - 216, 20, 12)], '#F2B5C3' if i % 2 else '#E9CDB0', shade=.3, line=.75, line_color=SKETCH, volume=4)
    l.fill([jar], '#F7D7DE', shade=.2, edge=.12, line=.9, line_color=SKETCH, volume=8, alpha=.9)


def hearts_doodle(l):
    for x, y, s in ((300, 200, 60), (470, 330, 36)):
        graphic_heart(l, x, y, s, '#FFFFFF00'[:7], line=0) if False else None
        pts = [(x, y + s * .9), (x - s, y - s * .05), (x - s * .95, y - s * .68), (x - s * .4, y - s * .82), (x, y - s * .28),
               (x + s * .4, y - s * .82), (x + s * .95, y - s * .68), (x + s, y - s * .05)]
        l.pencil(spline(pts + pts[:1], closed=False), '#E98DA4', 5, .92, curve=False)


def sketchbook(path, width=1024, height=2222):
    rng = np.random.default_rng(4)
    paper = np.ones((height, width, 3), dtype=np.float32) * (np.array((255, 246, 236), dtype=np.float32) / 255)
    img = Image.fromarray((rng.random((height // 90 + 2, width // 90 + 2), dtype=np.float32) * 255).astype(np.uint8)).resize((width, height), Image.BICUBIC)
    blot = np.asarray(img, dtype=np.float32) / 255
    img2 = Image.fromarray((rng.random((height // 320 + 2, width // 320 + 2), dtype=np.float32) * 255).astype(np.uint8)).resize((width, height), Image.BICUBIC)
    big = np.asarray(img2, dtype=np.float32) / 255
    pink = np.array((248, 205, 212), dtype=np.float32) / 255
    amount = np.clip((big - .42) * 1.6, 0, 1) * np.clip(.5 + blot * .6, 0, 1)
    paper = paper * (1 - amount[..., None] * .62) + pink * amount[..., None] * .62
    paper += rng.normal(0, .012, (height, width))[..., None]
    out = Image.fromarray((np.clip(paper, 0, 1) * 255).astype(np.uint8)).convert('RGBA')
    ring = Layer('ring')
    # A single binder ring, repeated down the left edge.
    ring.fill([ribbon([(14, 30), (44, 22), (70, 34)], [6, 6.5, 6], steps=20)], '#B7B0AA', shade=.45, edge=.1, line=.9, line_color='#5F544E', volume=4)
    ring.fill([circle(72, 36, 11, 12)], '#FFFFFF', shade=.25, edge=.16, line=.8, line_color='#9D8E85', volume=4)
    tile = ring.to_image().crop((0, 0, 92, 64))
    step = 52
    for y in range(8, height, step):
        out.alpha_composite(tile, (0, y))
    out.convert('RGB').save(path, 'WEBP', quality=84, method=5)


def banner():
    l = Layer('banner')
    rng = random.Random(9)
    pts = []
    for i in range(20):
        pts.append((60 + i * 47, 190 + rng.uniform(-10, 10)))
    pts += [(990 + rng.uniform(-6, 6), 330 + rng.uniform(-20, 20))]
    for i in range(20):
        pts.append((960 - i * 47, 470 + rng.uniform(-10, 10)))
    pts += [(34 + rng.uniform(-6, 6), 330 + rng.uniform(-20, 20))]
    l.fill([pts], '#F8E9D2', shade=.14, edge=.18, bleed=.08, line=.65, line_color=mix(SKETCH, '#FFFFFF', .3), volume=44)
    return l

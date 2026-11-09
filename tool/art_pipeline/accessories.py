"""Accessory illustrations placed on the shared body template."""
import math

from body import _bow, circle
from engine import CX, INK, R, flip, mix, poly_mask, ribbon, rgb, spline
from garments import _flip_if, graphic_flower, graphic_heart, graphic_star, line_color, side


def _handle(layer, pts, c, w=6):
    layer.fill([ribbon(pts, [w, w, w], steps=max(20, int(sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) / 10)))], c,
               shade=.15, edge=.05, line=.8, line_color=line_color(c), volume=3)


def shoulder_bag(layer, c, floral=False):
    _handle(layer, R((84, 470), (116, 700), (150, 950)), c, 6)
    body = R((92, 950), (214, 950), (232, 1080), (200, 1110), (106, 1110), (74, 1080))
    layer.fill([spline(body, closed=True)], c, shade=.28, edge=.12, line=1, line_color=line_color(c), volume=20)
    flap = R((92, 950), (214, 950), (220, 1020), (153, 1050), (86, 1020))
    layer.fill([spline(flap, closed=True)], mix(c, '#FFFFFF', .12), shade=.16, edge=.08, line=.9, line_color=line_color(c), volume=10)
    layer.fill([circle(CX + 153, 1030, 9, 12)], '#E8C77A', shade=.2, line=.8, volume=3)
    if floral:
        for dx, dy in ((120, 985), (186, 985), (153, 1070)):
            graphic_flower(layer, CX + dx, dy, 13, '#F2A6B9')


def handbag(layer, c, floral=False, x=282, y=1300):
    _handle(layer, [(CX + x - 54, y), (CX + x - 44, y - 58), (CX + x + 44, y - 58), (CX + x + 54, y)], mix(c, '#684A3C', .22), 5)
    body = [(CX + x - 78, y), (CX + x + 78, y), (CX + x + 96, y + 150), (CX + x - 96, y + 150)]
    layer.fill([body], c, shade=.28, edge=.12, line=1, line_color=line_color(c), volume=20)
    layer.pencil([(CX + x - 78, y + 40), (CX + x + 78, y + 40)], line_color(c), 1.8, .5, curve=False)
    layer.fill([circle(CX + x, y + 42, 8, 10)], '#E8C77A', shade=.2, line=.8, volume=3)
    if floral:
        for dx, dy in ((-48, 86), (0, 104), (48, 86)):
            graphic_flower(layer, CX + x + dx, y + dy, 17, '#F2A6B9')


def purse(layer, c):
    _handle(layer, R((-84, 470), (-30, 720), (130, 960)), '#D9B98C', 3.5)
    body = R((92, 960), (196, 960), (212, 1050), (76, 1050))
    layer.fill([spline(body, closed=True)], c, shade=.3, edge=.12, line=1, line_color=line_color(c), volume=14)
    _bow(layer, CX + 144, 978, 18, mix(c, '#C46A82', .4))


def backpack_back(layer, c):
    body = R((-172, 560), (172, 560), (184, 950), (150, 990), (-150, 990), (-184, 950))
    layer.fill([spline(body, closed=True)], c, shade=.3, edge=.1, line=1, line_color=line_color(c), volume=30)


def backpack_front(layer, c):
    for s in (1, -1):
        _handle(layer, _flip_if(R((90, 462), (118, 610), (134, 800)), s), c, 12)


def hoops(layer, c, r=18):
    for s in (1, -1):
        x = CX + s * 84
        pts = [(x + math.cos(a / 26 * 6.283) * r, 318 + math.sin(a / 26 * 6.283) * r) for a in range(27)]
        layer.pencil(pts, c, 4, .95, taper=False, solid=True)
        layer.pencil(pts[2:12], mix(c, '#FFFFFF', .6), 1.4, .8)


def studs(layer, c):
    for s in (1, -1):
        layer.fill([circle(CX + s * 84, 304, 8, 12)], c, shade=.15, edge=.05, line=.8, volume=3)


def drops(layer, c):
    for s in (1, -1):
        x = CX + s * 84
        layer.pencil([(x, 300), (x, 330)], '#D4B063', 2.2, .95, curve=False)
        layer.fill([circle(x, 340, 11, 12)], c, shade=.2, edge=.06, line=.8, volume=4)


def _neck_chain(layer, depth, c, w=2.2):
    pts = R((-50, 436), (-30, 436 + depth * .6), (0, 436 + depth), (30, 436 + depth * .6), (50, 436))
    layer.pencil(pts, c, w, .95, taper=False)


def pendant(layer):
    _neck_chain(layer, 94, '#D4B063')
    graphic_heart(layer, CX, 544, 14, '#E98DA4')


def layered(layer):
    _neck_chain(layer, 66, '#D4B063')
    _neck_chain(layer, 112, '#D4B063')
    graphic_star(layer, CX, 560, 13, '#E8C77A')


def pearls(layer):
    for i in range(21):
        t = i / 20
        a = math.pi * t
        layer.fill([circle(CX - math.cos(a) * 54, 438 + math.sin(a) * 74, 7.5, 10)], '#FFF8F0', shade=.2, edge=.05, line=.6, volume=3)


def _wrist(layer, t, s, c, w=8, y_shift=0):
    from garments import arm_at
    (x, y), hw = arm_at(t)
    pts = [(x - hw - 4, y + y_shift - 2), (x, y + y_shift + 8), (x + hw + 4, y + y_shift + 2)]
    layer.fill([ribbon(_flip_if(pts, s), [w, w, w], steps=14)], c, shade=.15, edge=.06, line=.75, line_color=line_color(c), volume=3)


def bracelet(layer, c):
    _wrist(layer, .95, -1, c, 5)
    _wrist(layer, .91, -1, mix(c, '#FFFFFF', .3), 4)


def bead_bracelet(layer, c):
    from garments import arm_at
    (x, y), hw = arm_at(.94)
    for i in range(9):
        layer.fill([circle(W_flip(x - hw - 3 + i * (2 * hw + 6) / 8), y + 2 + 6 * math.sin(i / 8 * 3.14), 6.5, 10)], c, shade=.22, edge=.05, line=.6, volume=3)


def W_flip(x):
    return 1024 - x


def ring(layer, c):
    for s, finger in ((1, (795.5, 1254)), (-1, (795.5, 1254))):
        x, y = finger
        x2 = x if s > 0 else 1024 - x
        layer.fill([[(x2 - 9, y), (x2 + 9, y), (x2 + 9, y + 7), (x2 - 9, y + 7)]], c, shade=.1, edge=.04, line=.6, volume=2)
    layer.fill([circle(795.5, 1252, 6, 10)], '#F6C5CE', shade=.15, line=.6, volume=2)


def watch(layer, c, face='#FFF8F0'):
    _wrist(layer, .93, 1, c, 11)
    from garments import arm_at
    (x, y), _ = arm_at(.93)
    layer.fill([circle(x, y + 8, 18, 18)], '#E8C77A', shade=.18, edge=.05, line=.9, volume=4)
    layer.fill([circle(x, y + 8, 13, 16)], face, shade=.08, edge=.03, line=.5, volume=3)
    layer.pencil([(x, y + 8), (x + 1, y)], INK, 1.5, .8, curve=False)
    layer.pencil([(x, y + 8), (x + 7, y + 10)], INK, 1.5, .8, curve=False)


def sunglasses(layer, c='#3A2A28', tint='#6A5552', frame=None):
    frame = frame or c
    for s in (1, -1):
        shape = R((16, 226), (84, 222), (94, 250), (72, 280), (28, 280), (10, 254))
        layer.fill([spline(_flip_if(shape, s), closed=True)], tint, shade=.35, edge=.1, bleed=.02, line=1.25, line_color=frame, volume=10, alpha=.92)
        layer.pencil(_flip_if(R((30, 240), (50, 236)), s), '#FFFFFF', 3.4, .55, curve=False)
        layer.pencil(_flip_if(R((90, 236), (100, 232)), s), frame, 4, .95, curve=False, taper=False)
    layer.pencil(R((-16, 238), (0, 232), (16, 238)), frame, 4, .95, taper=False)


def clip(layer, c, kind='bar'):
    x, y = CX + 106, 146
    if kind == 'bar':
        layer.fill([ribbon([(x - 32, y + 12), (x + 26, y - 18)], [7, 7], steps=8)], c, shade=.18, edge=.06, line=.9, line_color=line_color(c), volume=3)
        layer.fill([ribbon([(x - 26, y + 26), (x + 30, y - 2)], [5, 5], steps=8)], mix(c, '#FFFFFF', .3), shade=.15, line=.8, line_color=line_color(c), volume=3)
    elif kind == 'star':
        graphic_star(layer, x, y, 26, c)
    elif kind == 'flower':
        graphic_flower(layer, x, y, 26, c)
    elif kind == 'heart':
        graphic_heart(layer, x, y, 22, c)


def hairband(layer, c, knot=False):
    pts = R((-132, 214), (-112, 116), (-60, 74), (0, 62), (60, 74), (112, 116), (132, 214))
    layer.fill([ribbon(pts, [12, 15, 16, 16, 16, 15, 12], steps=50)], c, shade=.22, edge=.08, line=.95, line_color=line_color(c), volume=5)
    if knot:
        _bow(layer, CX + 46, 70, 30, mix(c, '#FFFFFF', .08))


def bow_accessory(layer, c, x=CX + 110, y=128, s=34):
    _bow(layer, x, y, s, c)


def sunhat(layer, c, band='#E98DA4'):
    brim = spline(R((-226, 180), (-120, 120), (0, 108), (120, 120), (226, 180), (120, 214), (0, 222), (-120, 214)), closed=True)
    layer.fill([brim], c, shade=.28, edge=.1, line=1, line_color=line_color(c), volume=28)
    crown = spline(R((-116, 146), (-108, 66), (-52, 28), (52, 28), (108, 66), (116, 146)))
    layer.fill([crown], c, shade=.28, edge=.1, line=1, line_color=line_color(c), volume=22)
    layer.fill([ribbon(R((-116, 132), (0, 146), (116, 132)), [15, 15, 15], steps=30)], band, shade=.2, edge=.06, line=.85, line_color=line_color(band), volume=5)
    _bow(layer, CX + 96, 138, 18, band)


def beret(layer, c):
    shape = spline(R((-150, 138), (-140, 60), (-40, 22), (84, 30), (156, 96), (138, 146), (0, 158)), closed=True)
    layer.fill([shape], c, shade=.32, edge=.1, line=1, line_color=line_color(c), volume=30)
    layer.pencil(R((-140, 134), (0, 150), (140, 134)), line_color(c), 2, .55)
    layer.pencil([(CX + 8, 22), (CX + 12, 8)], line_color(c), 5, .9, curve=False)


def cap(layer, c):
    crown = spline(R((-128, 164), (-122, 74), (-52, 28), (52, 28), (122, 74), (128, 164)))
    layer.fill([crown], c, shade=.26, edge=.1, line=1, line_color=line_color(c), volume=22)
    brim = spline(R((-128, 164), (-62, 192), (0, 200), (62, 192), (128, 164), (70, 158), (-70, 158)), closed=True)
    layer.fill([brim], mix(c, '#684A3C', .1), shade=.2, edge=.08, line=1, line_color=line_color(c), volume=8)
    layer.pencil([(CX, 30), (CX, 158)], line_color(c), 1.8, .45, curve=False)


def scarf(layer, c, pattern=None):
    wrap = spline(R((-92, 438), (-62, 404), (62, 404), (92, 438), (70, 488), (0, 506), (-70, 488)), closed=True)
    tail = ribbon(R((46, 480), (60, 620), (54, 800)), [30, 36, 42], steps=30)
    layer.fill([tail], c, shade=.26, edge=.1, bleed=.04, pattern=pattern, line=1, line_color=line_color(c), volume=14)
    layer.fill([wrap], c, shade=.26, edge=.1, bleed=.04, pattern=pattern, line=1, line_color=line_color(c), volume=16)
    for dx in range(14, 90, 16):
        layer.pencil(R((dx, 800), (dx, 830)), line_color(c), 1.8, .6, curve=False)


def headphones(layer, c):
    pts = R((-122, 436), (-62, 448), (0, 462), (62, 448), (122, 436))
    layer.fill([ribbon(pts, [9, 9, 9, 9, 9], steps=30)], c, shade=.2, edge=.06, line=.9, line_color=line_color(c), volume=4)
    for s in (1, -1):
        cup = circle(CX + s * 104, 430, 38, 24)
        layer.fill([cup], c, shade=.3, edge=.08, line=1, line_color=line_color(c), volume=12)
        layer.fill([circle(CX + s * 104, 430, 22, 18)], mix(c, '#FFF8F0', .55), shade=.16, edge=.04, line=.8, volume=6)

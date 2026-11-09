"""Parametric garment drawing on the shared body template."""
import math

import numpy as np

from body import ARM, ARM_HW, _bow, circle
from engine import (CX, INK, R, denim, dots, flip, florals, hearts, knit, mix, plaid, poly_mask, resample,
                    ribbon, rgb, spline, stripes_h, symmetric)

_side = np.array([(474, 150), (560, 152), (622, 128), (680, 126), (760, 112), (834, 99), (926, 114), (1000, 152),
                  (1064, 166), (1126, 162)], dtype=float)
_arm_line = np.array(resample(spline(ARM), 80))
_arm_w = np.interp(np.linspace(0, 1, 80), np.linspace(0, 1, len(ARM_HW)), ARM_HW)


def side(y):
    return float(np.interp(y, _side[:, 0], _side[:, 1]))


def arm_at(t):
    i = min(int(t * 79), 79)
    return tuple(_arm_line[i]), float(_arm_w[i])


def line_color(c):
    return mix(INK, c, 0.18)


def sleeve_poly(t0, t1, ease, flare=0.0, count=18):
    ts = np.linspace(t0, t1, count)
    pts = [arm_at(t)[0] for t in ts]
    ws = []
    for t in ts:
        k = (t - t0) / max(t1 - t0, 1e-3)
        ws.append(arm_at(t)[1] + ease + flare * k)
    return ribbon(pts, ws, steps=count * 2)


def cuff_line(layer, t, ease, color):
    (x, y), w = arm_at(t)
    (x2, y2), _ = arm_at(min(t + .02, 1))
    dx, dy = x2 - x, y2 - y
    d = math.hypot(dx, dy) or 1
    nx, ny = -dy / d, dx / d
    w += ease
    for side_sign in (1, -1):
        def m(p):
            return p if side_sign > 0 else flip(p)
        layer.pencil(m([(x + nx * w, y + ny * w), (x, y + 6), (x - nx * w, y - ny * w)]), color, 2.2, .75)


NECKS = {
    'crew': [(70, 452), (56, 484), (30, 506), (0, 512)],
    'scoop': [(82, 456), (72, 530), (40, 584), (0, 598)],
    'square': [(84, 456), (84, 556), (82, 568), (0, 570)],
    'v': [(74, 454), (46, 530), (0, 620)],
    'sweet': [(84, 456), (86, 556), (46, 596), (14, 572), (0, 592)],
    'high': [(44, 420), (34, 436), (0, 442)],
    'boat': [(106, 462), (64, 486), (0, 498)],
}


def torso_poly(neck, hem, ease, flare=0):
    n = NECKS[neck]
    right = spline(R(*n[::-1]))
    ys = list(range(626, int(hem), 26)) + [hem]
    side_pts = R((150 + ease, 474), (152 + ease, 560))
    for y in ys:
        k = (y - 626) / max(hem - 626, 1)
        side_pts += R((side(y) + ease + flare * k * k, y))
    contour = right + spline(side_pts)
    return contour + flip(contour)[::-1]


def wavy_hem(layer, left_x, right_x, y, depth, count, color, pattern=None, line=1.0, curve=0):
    """Ruffle band drawn as one scalloped polygon."""
    pts = []
    width = right_x - left_x
    for i in range(count * 8 + 1):
        t = i / (count * 8)
        x = left_x + width * t
        bow = curve * (1 - (2 * t - 1) ** 2)
        pts.append((x, y + bow + depth + abs(math.sin(t * count * math.pi)) * depth * .55))
    top = [(right_x - 3, y - depth * .3), (left_x + 3, y - depth * .3)]
    m = poly_mask([pts + top])
    layer.wash(m, color, shade=.32, edge=.1, bleed=.04, pattern=pattern, line=line, line_color=line_color(color), volume=10)
    for i in range(count):
        x = left_x + (i + .5) / count * width
        t = (x - left_x) / width
        bow = curve * (1 - (2 * t - 1) ** 2)
        layer.pencil([(x, y + bow - depth * .1), (x + 2, y + bow + depth * .9)], line_color(color), 1.6, .36, curve=False)


def folds(layer, lines, c, a=.3):
    for pts in lines:
        layer.pencil(pts, mix(INK, c, .34), 2.0, a)


def buttons(layer, x, ys, r=7, color='#FFF8F0'):
    for y in ys:
        layer.fill([circle(x, y, r, 12)], color, shade=.2, edge=.05, line=.7, volume=3)
        layer.pencil([(x - 2, y), (x + 2, y)], INK, 1.4, .7, curve=False)


def stitch(layer, pts, color, gap=11):
    line = resample(spline(pts) if len(pts) > 2 else pts, max(4, int(sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)) / gap)))
    for i in range(0, len(line) - 1, 2):
        layer.pencil([line[i], line[i + 1]], color, 1.5, .62, curve=False, taper=False)


def graphic_flower(layer, x, y, s, petal, center='#F2D27A'):
    for k in range(6):
        a = k * 1.047
        px, py = x + math.cos(a) * s * .62, y + math.sin(a) * s * .62
        layer.fill([circle(px, py, s * .52, 16)], petal, shade=.28, edge=.08, line=.65, volume=int(s * .3))
    layer.fill([circle(x, y, s * .36, 14)], center, shade=.25, edge=.06, line=.6, volume=4)


def graphic_heart(layer, x, y, s, color, line=.8):
    pts = [(x, y + s * .9), (x - s, y - s * .05), (x - s * .95, y - s * .68), (x - s * .4, y - s * .82), (x, y - s * .28),
           (x + s * .4, y - s * .82), (x + s * .95, y - s * .68), (x + s, y - s * .05)]
    layer.fill([spline(pts, closed=True)], color, shade=.25, edge=.08, line=line, volume=8)


def graphic_star(layer, x, y, s, color):
    pts = []
    for i in range(10):
        r = s if i % 2 == 0 else s * .44
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((x + math.cos(a) * r, y + math.sin(a) * r))
    layer.fill([pts], color, shade=.2, edge=.08, line=.8, volume=6)


def sleeves_for(kind):
    """(t_end, ease, flare, puff)"""
    return {
        'none': None,
        'short': (.26, 8, 8, 0),
        'puff': (.25, 12, 2, 20),
        'elbow': (.52, 8, 8, 0),
        'long': (.965, 11, 3, 0),
        'oversized': (.97, 22, 4, 0),
        'bishop': (.94, 16, 18, 0),
    }[kind]


def add_sleeves(layer, c, kind, pattern=None, cuff=True, sleeve_color=None):
    spec = sleeves_for(kind)
    if not spec:
        return
    t1, ease, flare, puff = spec
    col = sleeve_color or c
    polys = []
    for s in (1, -1):
        poly = sleeve_poly(0.0, t1, ease, flare)
        cap = circle(arm_at(0)[0][0] - 8, arm_at(0)[0][1] + 14, 42 + ease * .6 + puff)
        polys.append(poly if s > 0 else flip(poly))
        polys.append(cap if s > 0 else flip(cap))
    m = poly_mask(polys)
    layer.wash(m, col, shade=.34, edge=.12, bleed=.05, pattern=pattern, line=1, line_color=line_color(col), volume=20, side=0)
    if cuff and kind != 'none':
        for s in (1, -1):
            lc = line_color(col)
            (x, y), w = arm_at(t1 - .025)
            tw = w + ease + flare
            pts = [(x - tw, y + 2), (x, y + 10), (x + tw, y - 4)]
            layer.pencil(pts if s > 0 else flip(pts), lc, 2, .7)
    for s in (1, -1):
        p = [(696, 620), (718, 760)]
        if kind in ('elbow', 'long', 'oversized', 'bishop'):
            layer.pencil(p if s > 0 else flip(p), mix(INK, col, .34), 1.8, .28, curve=False)


def blouse_top(layer, c, neck='square', sleeve='puff', hem=790, ease=8, flare=0, pattern=None, peplum=False, tie=None, ruffle=False,
               sleeve_cuff=True):
    add_sleeves(layer, c, sleeve, pattern=pattern, cuff=sleeve_cuff)
    m = layer.fill([torso_poly(neck, hem, ease, flare)], c, shade=.3, edge=.12, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30)
    folds(layer, [R((-74, 640), (-66, 720), (-74, hem - 16)), R((74, 640), (66, 720), (74, hem - 16))], c, .24)
    w = side(hem) + ease + flare
    if peplum:
        wavy_hem(layer, CX - w - 8, CX + w + 8, hem, 22, 7, c, pattern)
    if ruffle:
        wavy_hem(layer, CX - w - 6, CX + w + 6, hem - 18, 18, 9, c, pattern)
    if tie:
        _bow(layer, CX, tie, 22, mix(c, '#C46A82', .28))
    return m


def tee(layer, c, neck='crew', hem=880, ease=10, sleeve='short', pattern=None, graphic=None, crop=False):
    h = 780 if crop else hem
    add_sleeves(layer, c, sleeve, pattern=pattern, cuff=True)
    layer.fill([torso_poly(neck, h, ease)], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30)
    n = NECKS[neck]
    layer.pencil(R(*[(a - 2, b + 13) for a, b in n]) if False else R(*[(-a, b + 12) for a, b in n[::-1]] + [(a, b + 12) for a, b in n[1:]]), line_color(c), 1.8, .55)
    if graphic == 'flower':
        graphic_flower(layer, CX, 668, 42, '#F2A6B9')
    elif graphic == 'heart':
        graphic_heart(layer, CX, 660, 44, '#EE8FA6')
    elif graphic == 'star':
        graphic_star(layer, CX, 666, 50, '#F4D7DE')
    elif graphic == 'bow':
        _bow(layer, CX, 650, 30, '#EE8FA6')
    folds(layer, [R((-92, h - 60), (-40, h - 30)), R((92, h - 74), (46, h - 34))], c, .22)
    layer.pencil(R((-side(h) - ease, h - 20), (0, h - 16), (side(h) + ease, h - 20)), line_color(c), 1.6, .32)


def off_shoulder(layer, c, pattern=None, hem=800, ruffle_depth=46):
    y = 584
    top = spline(R((186, y + 10), (120, y + 2), (0, y + 12)))
    ys = list(range(y + 40, hem, 24)) + [hem]
    contour = top[::-1] + spline(R(*[(side(v) + 8, v) for v in ys]))
    poly = contour + flip(contour)[::-1]
    layer.fill([poly], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30)
    wavy_hem(layer, CX - 196, CX + 196, y, ruffle_depth, 11, mix(c, '#FFFFFF', .08), pattern, curve=8)
    wavy_hem(layer, CX - side(hem) - 12, CX + side(hem) + 12, hem - 16, 18, 9, c, pattern)


def tied_shirt(layer, c, pattern=None, sleeve='short'):
    add_sleeves(layer, c, sleeve, pattern=pattern)
    hem = 776
    layer.fill([torso_poly('v', hem, 12)], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30)
    collar_shirt(layer, c)
    layer.pencil([(CX, 620), (CX, 760)], line_color(c), 1.8, .7, curve=False)
    buttons(layer, CX + 12, [650, 700, 745], 6)
    for s in (1, -1):
        tail = ribbon([(CX, 770), (CX + 34, 830), (CX + 74, 886)], [24, 22, 9], steps=16)
        layer.fill([tail if s > 0 else flip(tail)], c, shade=.3, edge=.08, bleed=.04, pattern=pattern, line=1, line_color=line_color(c), volume=8)
    layer.fill([circle(CX, 772, 24, 14)], c, shade=.26, edge=.08, line=1, line_color=line_color(c), volume=6)


def collar_shirt(layer, c, w=62):
    for s in (1, -1):
        pts = R((30, 436), (w + 28, 452), (w + 18, 512), (22, 560), (0, 520), (6, 470))
        layer.fill([pts if s > 0 else flip(pts)], mix(c, '#FFFFFF', .06), shade=.22, edge=.08, line=.95, line_color=line_color(c), volume=8)


def button_shirt(layer, c, pattern=None, hem=926, sleeve='long'):
    add_sleeves(layer, c, sleeve, pattern=pattern)
    layer.fill([torso_poly('v', hem, 14)], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30)
    collar_shirt(layer, c)
    layer.pencil([(CX, 600), (CX, hem - 4)], line_color(c), 1.8, .7, curve=False)
    layer.pencil([(CX + 20, 600), (CX + 20, hem - 4)], line_color(c), 1.4, .34, curve=False)
    buttons(layer, CX + 10, list(range(640, hem - 10, 66)), 6)
    pocket = R((-86, 620), (-30, 620), (-30, 690), (-58, 704), (-86, 690))
    layer.pencil(pocket + pocket[:1], line_color(c), 1.8, .55, curve=False)


def hoodie(layer, c, pattern=None, hem=900):
    add_sleeves(layer, c, 'oversized', pattern=pattern, cuff=True)
    hood = spline(R((-110, 460), (-120, 400), (-66, 366), (66, 366), (120, 400), (110, 460), (60, 500), (0, 540), (-60, 500)), closed=True)
    layer.fill([hood], mix(c, '#684A3C', .08), shade=.3, edge=.1, line=1, line_color=line_color(c), volume=14)
    layer.fill([torso_poly('crew', hem, 26, 8)], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=34)
    wavy_hem(layer, CX - side(hem) - 34, CX + side(hem) + 34, hem - 8, 14, 16, mix(c, '#684A3C', .06), line=.9)
    pocket = R((-88, 868), (-66, 780), (66, 780), (88, 868))
    layer.pencil(pocket, line_color(c), 2, .6, curve=False)
    layer.pencil(R((-88, 868), (88, 868)), line_color(c), 2, .6, curve=False)
    for s in (-1, 1):
        layer.pencil([(CX + s * 24, 512), (CX + s * 26, 620)], '#FFF8F0', 5, .95)
        layer.pencil([(CX + s * 24, 512), (CX + s * 26, 620)], line_color(c), 1.4, .55)
    folds(layer, [R((-120, 720), (-70, 700)), R((120, 730), (70, 706))], c, .24)


def sweater(layer, c, pattern=None, hem=880, neck='crew', ribbed=True):
    add_sleeves(layer, c, 'oversized', pattern=pattern)
    layer.fill([torso_poly(neck, hem, 28, 6)], c, shade=.28, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=34)
    n = NECKS[neck]
    layer.pencil(R(*[(-a, b + 18) for a, b in n[::-1]] + [(a, b + 18) for a, b in n[1:]]), line_color(c), 2, .55)
    if ribbed:
        for x in range(-150, 151, 22):
            layer.pencil([(CX + x, hem - 22), (CX + x, hem - 2)], line_color(c), 1.4, .42, curve=False)
        layer.pencil(R((-side(hem) - 30, hem - 26), (side(hem) + 30, hem - 26)), line_color(c), 1.6, .5, curve=False)


def cardigan_top(layer, c, hem=890, pattern=None):
    sweater(layer, c, pattern=pattern, hem=hem, neck='v')
    layer.pencil([(CX, 618), (CX, hem - 2)], line_color(c), 2, .7, curve=False)
    buttons(layer, CX, list(range(652, hem - 30, 62)), 8, '#D9B98C')


def denim_top_jacket(layer, c):
    add_sleeves(layer, c, 'oversized', pattern=denim())
    layer.fill([torso_poly('v', 870, 28)], c, shade=.3, edge=.14, bleed=.06, pattern=denim(), line=1, line_color=line_color(c), volume=30)
    collar_shirt(layer, c, 74)
    layer.pencil([(CX, 600), (CX, 868)], line_color(c), 2, .75, curve=False)
    stitch(layer, R((-142, 640), (142, 640)), '#F3D9A7')
    buttons(layer, CX + 12, [640, 710, 780, 850], 7, '#D9B98C')
    for s in (1, -1):
        pocket = R((46, 650), (120, 650), (120, 716), (83, 734), (46, 716))
        layer.pencil(_flip_if(pocket + pocket[:1], s), line_color(c), 1.8, .62, curve=False)


def _flip_if(points, s):
    return points if s > 0 else flip(points)


def varsity_top(layer, c, trim='#FFF4E6'):
    add_sleeves(layer, c, 'oversized', sleeve_color=trim, cuff=True)
    layer.fill([torso_poly('v', 870, 28)], c, shade=.28, edge=.1, bleed=.05, line=1, line_color=line_color(c), volume=30)
    wavy_hem(layer, CX - 168, CX + 168, 856, 14, 14, trim, line=.9)
    layer.pencil([(CX, 610), (CX, 852)], line_color(c), 2, .75, curve=False)
    buttons(layer, CX, [650, 712, 774, 830], 7)
    layer.fill([ribbon(R((-34, 684), (-58, 628), (-82, 684)), [6, 6, 6], steps=20)], trim, shade=.1, edge=.02, line=.75, volume=3)
    layer.pencil(R((-44, 660), (-72, 660)), trim, 5, .95, curve=False, taper=False)


# ---- bottoms ----------------------------------------------------------------

def _waistband(layer, c, y, band=44, dx=None, ease=4):
    w0 = (dx or side(y)) + ease
    w1 = side(y + band) + ease + 4
    pts = R((-w0, y), (0, y + 7), (w0, y), (w1, y + band), (0, y + band + 7), (-w1, y + band))
    layer.fill([spline(pts[:3]) + spline(pts[3:])], c, shade=.18, edge=.1, bleed=.03, line=1, line_color=line_color(c), volume=8)
    return y + band


def pants(layer, c, pattern=None, waist=826, hem=1930, hem_out=270, hem_in=86, cargo=False, jogger=False, band=True, belt=False,
          drawstring=False, thigh=8):
    outer = [(side(waist) + 4, waist), (side(930) + 10, 930), (side(1040) + 12, 1040), (side(1040) + thigh + 12, 1190)]
    mid_y = (1190 + hem) / 2
    outer += [((outer[-1][0] + hem_out) / 2 + 4, mid_y), (hem_out, hem)]
    inner = [(hem_in, hem), ((hem_in + 16) / 2, mid_y), (4, 1134)]
    right = spline(R(*outer)) + R(*inner) + R((0, 1130), (0, waist))
    polys = [right, flip(right)]
    m = poly_mask(polys)
    layer.wash(m, c, shade=.3, edge=.12, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=26, side=0)
    for s in (1, -1):
        crease = R((70, 960), (92 + (hem_out - 200) * .1, 1400), ((hem_out + hem_in) / 2, hem - 8))
        layer.pencil(_flip_if(crease, s), mix(INK, c, .34), 2, .3)
        crease2 = R((110, 1000), (130, 1300), (hem_out - 40, hem - 40))
        layer.pencil(_flip_if(crease2, s), mix(INK, c, .34), 1.8, .2)
    layer.pencil([(CX, 880), (CX, 1124)], line_color(c), 2, .55)
    if band:
        bottom = _waistband(layer, mix(c, '#FFFFFF', .05), waist)
        if not jogger:
            buttons(layer, CX, [waist + 24], 8, '#D9B98C')
            layer.pencil([(CX, bottom + 6), (CX + 3, 1040)], line_color(c), 1.8, .6, curve=False)
            for s in (1, -1):
                layer.pencil(_flip_if(R((50, bottom + 4), (102, bottom + 56), (side(940) + 6, bottom + 66)), s), line_color(c), 2, .55)
                for dx in (66, 128):
                    layer.pencil(_flip_if(R((dx, waist + 2), (dx, waist + 42)), s), line_color(c), 2.4, .55, curve=False)
    if cargo:
        for s in (1, -1):
            pk = R((108, 1240), (186, 1240), (190, 1390), (112, 1390))
            layer.fill([_flip_if(pk, s)], mix(c, '#684A3C', .08), shade=.2, edge=.1, bleed=.02, pattern=pattern, line=.9, line_color=line_color(c), volume=8)
            flap = R((102, 1230), (192, 1230), (196, 1278), (104, 1278))
            layer.fill([_flip_if(flap, s)], mix(c, '#684A3C', .12), shade=.15, edge=.08, line=.9, line_color=line_color(c), volume=5)
            buttons(layer, CX + s * 150, [1258], 5, '#D9B98C')
    if jogger:
        for s in (1, -1):
            cuff = R((hem_in - 8, hem - 30), (hem_out + 2, hem - 30), (hem_out + 2, hem), (hem_in - 8, hem))
            layer.fill([_flip_if(cuff, s)], mix(c, '#684A3C', .08), shade=.2, edge=.1, line=1, line_color=line_color(c), volume=5)
    else:
        for s in (1, -1):
            layer.pencil(_flip_if(R((hem_in + 2, hem - 16), (hem_out - 2, hem - 16)), s), line_color(c), 1.6, .5, curve=False)
    if drawstring:
        for s in (1, -1):
            layer.pencil([(CX + s * 8, waist + 34), (CX + s * 16, waist + 120)], '#FFF8F0', 4, .95)


def shorts(layer, c, pattern=None, waist=826, hem=1190, frayed=False, embroidered=False):
    outer = [(side(waist) + 4, waist), (side(930) + 10, 930), (side(1040) + 12, 1040), (side(1040) + 18, hem)]
    right = spline(R(*outer)) + R((30, hem + 6), (6, 1132), (0, 1130), (0, waist))
    layer.fill([right, flip(right)], c, shade=.28, edge=.12, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=22, side=0)
    bottom = _waistband(layer, mix(c, '#FFFFFF', .05), waist)
    buttons(layer, CX, [waist + 24], 8, '#D9B98C')
    layer.pencil([(CX, bottom + 6), (CX, 1124)], line_color(c), 1.8, .55, curve=False)
    for s in (1, -1):
        layer.pencil(_flip_if(R((50, bottom + 4), (106, bottom + 52), (side(940) + 8, bottom + 62)), s), line_color(c), 2, .55)
        if frayed:
            for i in range(26):
                x = 34 + i * 6
                layer.pencil(_flip_if(R((x, hem), (x + (i % 3) - 1, hem + 12 + (i * 7) % 12)), s), '#FFF8F0', 2, .95, curve=False)
        else:
            layer.pencil(_flip_if(R((32, hem - 12), (side(1040) + 16, hem - 12)), s), line_color(c), 1.6, .5, curve=False)
        if embroidered:
            for k in range(3):
                graphic_flower(layer, CX + s * (82 + k * 22), 1080 + k * 24, 13, '#F2A6B9')


def skirt(layer, c, pattern=None, waist=826, hem=1300, half=250, pleats=0, buttons_front=False, band=True, tier=False, zig=False):
    side_pts = [(side(waist) + 5, waist), (side(940) + 10, 940), (side(1060) + 22, 1060)]
    y2 = max(hem - 120, 1090)
    side_pts += [(min(half * .92, 212) if hem > 1300 else half * .93, y2), (half, hem)]
    bow = 18
    hem_pts = [(half, hem), (half * .5, hem + bow), (0, hem + bow + 4)]
    if zig:
        count = 16
        hem_pts = [(half - (half * 2) * i / count, hem + (14 if i % 2 else 0)) for i in range(count + 1)]
        right = spline(R(*side_pts))
        poly = right + R(*hem_pts) + flip(right)[::-1]
    else:
        right = spline(R(*side_pts)) + spline(R(*hem_pts))[1:]
        poly = right + flip(right)[::-1]
    layer.fill([poly], c, shade=.28, edge=.12, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=30, side=0)
    if pleats:
        for i in range(1, pleats):
            t = i / pleats * 2 - 1
            layer.pencil([(CX + t * (side(waist) + 2), waist + 46), (CX + t * (side(1040) + 8), 1060), (CX + t * (half - 4), hem + bow * (1 - t * t))], line_color(c), 1.9, .58)
    else:
        for t in (-.6, -.2, .25, .62):
            layer.pencil([(CX + t * 120, waist + 90), (CX + t * half * .95, hem - 8)], mix(INK, c, .34), 2, .26)
    if tier:
        wavy_hem(layer, CX - half + 8, CX + half - 8, (waist + hem) / 2 + 80, 26, 10, c, pattern, curve=12)
    if band:
        _waistband(layer, mix(c, '#FFFFFF', .05), waist)
    if buttons_front:
        layer.pencil([(CX, waist + 44), (CX, hem + 18)], line_color(c), 2, .55, curve=False)
        buttons(layer, CX + 12, list(range(waist + 90, hem - 10, 96)), 7, '#D9B98C')


# ---- dresses ------------------------------------------------------------------

def dress(layer, c, neck='sweet', sleeve='none', waist=834, hem=1540, half=320, pattern=None, straps=True, pleats=0, tier=0, ruffle_hem=False,
          sash=None, bow=None, lace=False, collar=False, buttons_front=False, off=False):
    pts = [(side(waist) + 5, waist), (side(940) + 14, 940), (side(1060) + 24, 1060)]
    if hem > 1320:
        pts += [(212, 1240), ((212 + half) / 2, (1240 + hem) / 2)]
    pts += [(half, hem)]
    right = spline(R(*pts)) + spline(R((half, hem), (half * .5, hem + 26), (0, hem + 30)))[1:]
    poly = right + flip(right)[::-1]
    layer.fill([poly], c, shade=.26, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=34, side=0)
    for t in (-.72, -.44, -.14, .18, .47, .74):
        layer.pencil([(CX + t * 100, waist + 40), (CX + t * 170, 1100), (CX + t * half * .96, hem + 22 * (1 - t * t))], mix(INK, c, .34), 2, .3 if not pleats else .55)
    for i in range(tier):
        y = waist + (hem - waist) * (i + 1) / (tier + 1)
        width = np.interp(y, [waist, 1060, 1240, hem], [side(waist), side(1060) + 24, 212, half])
        wavy_hem(layer, CX - width, CX + width, y, 26, 12, mix(c, '#FFFFFF', .08 * (i % 2)), pattern, curve=14)
    if ruffle_hem:
        wavy_hem(layer, CX - half - 6, CX + half + 6, hem + 6, 30, 16, mix(c, '#FFFFFF', .1), pattern, curve=14)
    if lace:
        for i in range(30):
            t = i / 29 * 2 - 1
            x, y = CX + t * half * .97, hem + 30 * (1 - t * t) * .9
            layer.fill([circle(x, y + 6, 13, 12)], '#FFFDF8', shade=.12, edge=.04, line=.55, volume=3)
    if off:
        off_shoulder(layer, c, pattern=pattern, hem=waist, ruffle_depth=40)
    else:
        add_sleeves(layer, c, sleeve, pattern=pattern)
        polys = [torso_poly(neck, waist + 12, 4)]
        layer.fill(polys, c, shade=.26, edge=.1, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=28)
        if straps and sleeve == 'none':
            for s in (1, -1):
                strap = R((82, 500), (84, 476), (84, 448))
                layer.fill([ribbon(_flip_if(strap, s), [8, 7, 7])], c, shade=.15, edge=.05, line=.85, line_color=line_color(c), volume=4)
    layer.pencil(R((-side(waist) - 5, waist + 8), (0, waist + 18), (side(waist) + 5, waist + 8)), line_color(c), 2, .6)
    if collar:
        collar_shirt(layer, mix(c, '#FFFFFF', .4), 48)
    if sash:
        width = side(waist) + 6
        pts = R((-width, waist - 12), (0, waist - 2), (width, waist - 12), (width + 2, waist + 26), (0, waist + 36), (-width - 2, waist + 26))
        layer.fill([spline(pts[:3]) + spline(pts[3:])], sash, shade=.18, edge=.08, line=.9, line_color=line_color(sash), volume=7)
    if bow:
        _bow(layer, CX, waist + 10, 34, bow)
        for s in (1, -1):
            tail = ribbon(R((0, waist + 30), (22, waist + 150), (34, waist + 268)), [8, 11, 7], steps=14)
            layer.fill([_flip_if(tail, s)], bow, shade=.2, edge=.06, line=.8, line_color=line_color(bow), volume=5)
    if buttons_front:
        layer.pencil([(CX, 620), (CX, hem + 26)], line_color(c), 2, .6, curve=False)
        buttons(layer, CX + 12, list(range(660, hem - 10, 104)), 7, '#D9B98C')


# ---- jackets ------------------------------------------------------------------

def open_jacket(layer, c, hem=900, inner_top=48, inner_hem=78, ease=30, sleeve_color=None, pattern=None, lapel=False, collar=True,
                ribbed=False, pockets='patch', zipper=False, seam=False):
    add_sleeves(layer, c, 'oversized', pattern=pattern, sleeve_color=sleeve_color)
    ys = [474, 560] + list(range(640, int(hem), 30)) + [hem]
    outer = [(150 + ease, 474), (152 + ease, 560)] + [(side(y) + ease, y) for y in ys[2:]]
    polyR = spline(R(*outer)) + R((inner_hem, hem), (inner_top + 18, 640), (inner_top, 500), (48, 440), (76, 452))
    m = layer.fill([polyR, flip(polyR)], c, shade=.28, edge=.13, bleed=.05, pattern=pattern, line=1, line_color=line_color(c), volume=26, side=0)
    if collar:
        for s in (1, -1):
            shape = R((36, 432), (106, 454), (112, 520), (78, 556), (46, 496))
            layer.fill([_flip_if(shape, s)], mix(c, '#FFFFFF', .05), shade=.2, edge=.08, pattern=pattern, line=.95, line_color=line_color(c), volume=8)
    if lapel:
        for s in (1, -1):
            shape = R((42, 440), (118, 500), (132, 556), (98, 590), (120, 640), (72, 760), (48, 620))
            layer.fill([_flip_if(shape, s)], mix(c, '#FFFFFF', .08), shade=.18, edge=.08, line=.95, line_color=line_color(c), volume=8)
    if ribbed:
        for s in (1, -1):
            cuff = R((inner_hem, hem - 34), (side(hem) + ease, hem - 34), (side(hem) + ease - 8, hem + 2), (inner_hem, hem + 2))
            layer.fill([_flip_if(cuff, s)], sleeve_color or mix(c, '#684A3C', .1), shade=.2, edge=.08, line=.9, line_color=line_color(c), volume=5)
    for s in (1, -1):
        if pockets == 'patch':
            pk = R((inner_hem + 22, hem - 148), (inner_hem + 96, hem - 148), (inner_hem + 96, hem - 72), (inner_hem + 60, hem - 56), (inner_hem + 22, hem - 72))
            layer.pencil(_flip_if(pk + pk[:1], s), line_color(c), 1.9, .62, curve=False)
        elif pockets == 'slit':
            layer.pencil(_flip_if(R((inner_hem + 30, hem - 110), (inner_hem + 90, hem - 150)), s), line_color(c), 2.4, .62, curve=False)
        if seam:
            stitch(layer, _flip_if(R((inner_top + 22, 620), (side(620) + ease - 6, 620)), s), '#F3D9A7')
        if zipper:
            layer.pencil(_flip_if(R((inner_top + 8, 520), (inner_hem - 6, hem)), s), '#D7CFC5', 5, .95, curve=False, taper=False)


# ---- shoes --------------------------------------------------------------------

def _foot(layer, fn):
    fn(1)
    fn(-1)


def _shape(layer, pts, s, c, **kw):
    return layer.fill([spline(_flip_if(R(*pts), s), closed=True)], c, shade=kw.pop('shade', .24), edge=kw.pop('edge', .08), bleed=.02,
                      line=kw.pop('line', 1), line_color=kw.pop('line_color', line_color(c)), volume=kw.pop('volume', 12), side=0, **kw)


def sneaker(layer, c, sole='#FFFFFF', accent=None):
    def draw(s):
        _shape(layer, [(72, 1858), (126, 1858), (144, 1916), (162, 1962), (158, 1990), (98, 2002), (40, 1990), (36, 1962), (56, 1916)], s, c)
        _shape(layer, [(38, 1966), (160, 1966), (164, 2000), (140, 2024), (56, 2024), (34, 2000)], s, sole, volume=8, shade=.15)
        for i in range(4):
            y = 1890 + i * 20
            layer.pencil(_flip_if(R((78 - i * 2, y), (122 + i * 2, y + 7)), s), '#FFFFFF', 4.2, .98, curve=False, taper=False)
            layer.pencil(_flip_if(R((78 - i * 2, y + 3), (122 + i * 2, y + 10)), s), INK, 1.2, .55, curve=False)
        _shape(layer, [(58, 1940), (140, 1940), (152, 1964), (46, 1964)], s, accent or mix(c, '#684A3C', .06), line=.7, volume=6, shade=.12)
    _foot(layer, draw)


def boot(layer, c, top=1650):
    def draw(s):
        _shape(layer, [(56, top), (142, top), (136, 1800), (146, 1920), (160, 1978), (150, 2004), (98, 2008), (46, 2004), (38, 1978), (52, 1920), (64, 1800)], s, c, volume=18)
        layer.pencil(_flip_if(R((60, top + 24), (140, top + 24)), s), line_color(c), 1.7, .5, curve=False)
        _shape(layer, [(36, 1984), (162, 1984), (162, 2022), (36, 2022)], s, mix(c, '#3A2A22', .5), volume=4, shade=.05, line=.9)
        layer.pencil(_flip_if(R((70, top + 90), (66, 1780), (72, 1880)), s), mix(INK, c, .3), 1.8, .3)
    _foot(layer, draw)


def sandal(layer, c):
    def draw(s):
        for pts, w in (([(58, 1902), (98, 1912), (140, 1902)], 8), ([(56, 1950), (98, 1940), (146, 1950)], 10)):
            layer.fill([ribbon(_flip_if(R(*pts), s), [w, w, w], steps=18)], c, shade=.2, edge=.06, line=.85, line_color=line_color(c), volume=4)
        for pts in ([(62, 1864), (98, 1878), (134, 1864)],):
            layer.fill([ribbon(_flip_if(R(*pts), s), [7, 7, 7], steps=16)], c, shade=.2, edge=.06, line=.85, line_color=line_color(c), volume=4)
        _shape(layer, [(44, 1994), (154, 1994), (160, 2012), (98, 2018), (38, 2012)], s, mix(c, '#684A3C', .2), volume=4, shade=.1, line=.8)
    _foot(layer, draw)


def flats(layer, c, bow_color=None):
    def draw(s):
        _shape(layer, [(58, 1932), (98, 1944), (140, 1932), (158, 1966), (150, 1998), (98, 2008), (46, 1998), (40, 1966)], s, c, volume=9)
        if bow_color:
            _bow(layer, CX + s * 98, 1950, 14, bow_color)
    _foot(layer, draw)


def heels(layer, c):
    def draw(s):
        _shape(layer, [(64, 1906), (98, 1916), (134, 1906), (152, 1960), (130, 1996), (98, 2024), (66, 1996), (46, 1960)], s, c, volume=9)
        _shape(layer, [(92, 2000), (106, 2000), (104, 2038), (94, 2038)], s, mix(c, '#684A3C', .3), volume=3, shade=.05, line=.7)
    _foot(layer, draw)


def loafer(layer, c):
    def draw(s):
        _shape(layer, [(62, 1900), (98, 1912), (136, 1900), (154, 1964), (152, 1998), (98, 2008), (44, 1998), (42, 1964)], s, c, volume=9)
        layer.pencil(_flip_if(R((66, 1930), (132, 1930)), s), '#D9B98C', 4, .9, curve=False, taper=False)
        _shape(layer, [(40, 1992), (156, 1992), (158, 2016), (40, 2016)], s, mix(c, '#3A2A22', .5), volume=3, shade=.05, line=.8)
    _foot(layer, draw)

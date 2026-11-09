"""Shared figure template. Every character uses exactly these proportions."""
import math

import faces
from engine import CX, INK, Layer, R, W, flip, mix, poly_mask, ribbon, rgb, spline, symmetric

# Arm centreline on the viewer's right. Mirrored for the other arm.
ARM = [(668, 498), (694, 640), (724, 836), (752, 984), (778, 1122)]
ARM_HW = [40, 38, 33, 30, 21]

TORSO = R((38, 346), (39, 404), (52, 442), (112, 462), (150, 474), (152, 560), (126, 622),
          (124, 680), (110, 760), (97, 834), (112, 926), (150, 1000), (164, 1064), (160, 1126))
LEG_OUT = [(164, 1064), (161, 1200), (146, 1350), (128, 1470), (136, 1600), (124, 1740), (124, 1866)]
LEG_IN = [(72, 1866), (64, 1740), (44, 1600), (30, 1470), (20, 1350), (7, 1210), (0, 1120)]
FOOT = R((126, 1866), (138, 1920), (150, 1962), (140, 1990), (98, 2000), (62, 1990), (50, 1960), (62, 1920), (72, 1866))
SCALP = R((0, 112), (56, 118), (82, 170), (82, 262), (0, 262))
HEAD = R((0, 112), (60, 116), (90, 165), (92, 232), (78, 292), (47, 336), (17, 357), (0, 360))


def _leg(side):
    pts = R(*LEG_OUT) + R(*LEG_IN)
    pts = spline(pts, closed=False)
    return pts if side > 0 else flip(pts)


def _hand(side):
    """Palm and fingers as a single set of polygons."""
    polys = [ribbon([(778, 1118), (792, 1172), (798, 1212)], [21, 28, 26])]
    fingers = [
        [(783, 1205), (781, 1240), (778, 1268)],
        [(795, 1212), (796, 1250), (796, 1284)],
        [(807, 1208), (811, 1244), (813, 1272)],
        [(818, 1198), (825, 1226), (829, 1248)],
    ]
    for finger in fingers:
        polys.append(ribbon(finger, [7.5, 7, 5], steps=12))
    polys.append(ribbon([(770, 1160), (754, 1196), (748, 1226)], [10, 8.5, 5], steps=12))
    return polys if side > 0 else [flip(p) for p in polys]


def circle(x, y, r, count=28):
    return [(x + math.cos(a / count * 6.283) * r, y + math.sin(a / count * 6.283) * r) for a in range(count)]


def _arm(side):
    polys = [ribbon(ARM, ARM_HW), circle(ARM[0][0] - 8, ARM[0][1] + 14, 38)]
    return polys if side > 0 else [flip(p) for p in polys]


def draw_body(layer, skin):
    """Paints a smooth, featureless doll figure. It is always covered by a garment layer."""
    shadow = mix(skin, '#B9806A', 0.5)
    line = mix(INK, skin, 0.22)
    limbs = [_leg(1), _leg(-1), spline(FOOT, closed=True), flip(spline(FOOT, closed=True))] + _arm(1) + _arm(-1)
    for side in (1, -1):
        limbs.extend(_hand(side))
    core = symmetric(spline(TORSO))
    mask = poly_mask(limbs + [core])
    layer.wash(mask, skin, shade=0.24, edge=0.05, bleed=0.012, line=0.95, line_color=line, volume=20, side=0.03)
    # Knees, ankles and toes.
    for side in (1, -1):
        def s(pts):
            return pts if side > 0 else flip(pts)
        layer.pencil(s(R((52, 1462), (78, 1478), (104, 1464))), line, 1.8, 0.4)
        layer.pencil(s(R((62, 1496), (80, 1506), (100, 1496))), line, 1.5, 0.28)
        for i, dx in enumerate((72, 88, 104, 120, 134)):
            layer.pencil(s(R((dx, 1974 - abs(i - 1) * 3), (dx + 2, 1992 - abs(i - 1) * 3))), line, 1.5, 0.5, curve=False)
    # Soft contact shadows around the collar and under the chin.
    return mask


def draw_face(layer, look):
    """Places the character's own painted face from the reference art."""
    skin = look['skin']
    line = mix(INK, skin, 0.15)
    layer.soft(CX, 374, 52, 26, mix(skin, '#B9806A', 0.75), 0.6, clip=poly_mask([symmetric(spline(TORSO))]))
    # Plain skin for the top of the head. Hair always covers its edge.
    layer.fill([spline(SCALP + flip(SCALP)[::-1], closed=True)], skin, shade=0, edge=0, bleed=0, line=0)
    faces.stamp_face(layer, look['id'])
    layer.pencil(R((-34, 462), (-70, 468), (-112, 482)), line, 1.8, 0.4)
    layer.pencil(R((34, 462), (70, 468), (112, 482)), line, 1.8, 0.4)


def _eyes(layer, look):
    iris = look['iris']
    lash = look.get('lash', '#2E211C')
    brow = look['brow']
    rise = look.get('eye_lift', 0)
    width = look.get('eye_w', 28)
    height = look.get('eye_h', 19)
    for side in (1, -1):
        def s(pts):
            return pts if side > 0 else flip(pts)
        cx, cy = 46, 238
        eye = s(R((cx - width, cy + 3), (cx - width * .4, cy - height * .9), (cx + width * .4, cy - height + rise * -1),
                  (cx + width, cy - 2 - rise), (cx + width * .35, cy + height * .72), (cx - width * .45, cy + height * .7)))
        mask = layer.fill([spline(eye, closed=True)], '#FFFDF8', shade=0.1, edge=0.03, bleed=0, line=0, volume=8)
        ix = CX + side * (cx + (-1 if side > 0 else -1) * 1)
        r = height * 1.02
        iris_mask = poly_mask([[(ix + math.cos(a / 24 * 6.283) * r, cy + 1 + math.sin(a / 24 * 6.283) * r) for a in range(24)]])
        layer.wash(iris_mask.times(mask), iris, shade=0.55, edge=0.2, bleed=0.03, line=0, volume=6)
        pupil = poly_mask([[(ix + math.cos(a / 18 * 6.283) * r * .5, cy + 1 + math.sin(a / 18 * 6.283) * r * .5) for a in range(18)]])
        layer.wash(pupil.times(mask), '#241813', shade=0, edge=0, bleed=0, line=0)
        layer.soft(ix - 6, cy - 7, 6, 6, '#FFFFFF', 1.0, clip=mask)
        layer.soft(ix + 7, cy + 7, 3, 3, '#FFFFFF', 0.85, clip=mask)
        upper = s(R((cx - width - 2, cy + 5), (cx - width * .45, cy - height), (cx + width * .4, cy - height - 1 - rise),
                    (cx + width + 8, cy - 8 - rise)))
        layer.pencil(upper, lash, 5.0, 0.98, solid=True)
        layer.pencil(s(R((cx + width - 2, cy - 5 - rise), (cx + width + 10, cy - 12 - rise), (cx + width + 16, cy - 20 - rise))), lash, 2.8, 0.9, solid=True)
        layer.pencil(s(R((cx + width * .6, cy - height + 2 - rise), (cx + width * .85, cy - height - 10 - rise))), lash, 2.0, 0.75, curve=False, solid=True)
        layer.pencil(s(R((cx - width * .7, cy + height * .72), (cx, cy + height * .95), (cx + width * .8, cy + height * .5))), line_soft(look), 1.6, 0.55)
        layer.pencil(s(R((cx - width * .85, cy - height * 1.42), (cx, cy - height * 1.72), (cx + width * .86, cy - height * 1.42))), line_soft(look), 1.6, 0.42)
        brow_arc = R((cx - width - 1, cy - 45 + look.get('brow_drop', 0)), (cx + width * .25, cy - 54), (cx + width + 8, cy - 41 - rise))
        layer.fill([ribbon(s(brow_arc), [3.6, 4.6, 1.2], steps=24)], brow, shade=0.1, edge=0, bleed=0.02, line=0, alpha=0.82, volume=4)


def line_soft(look):
    return mix(INK, look['skin'], 0.3)


def _lips(layer, look):
    lip = look['lip']
    width = look.get('lip_w', 22)
    top = R((-width, 319), (-10, 316), (0, 319), (10, 316), (width, 319), (9, 325), (-9, 325))
    bottom = R((-width, 319), (-9, 325), (9, 325), (width, 319), (12, 334), (0, 338), (-12, 334))
    layer.fill([spline(top, closed=True)], mix(lip, '#8E3B50', 0.25), shade=0.12, edge=0, bleed=0.02, line=0, volume=6)
    layer.fill([spline(bottom, closed=True)], lip, shade=0.2, edge=0, bleed=0.02, line=0, volume=6)
    layer.pencil(R((-width - 3, 316), (-10, 325), (0, 324), (10, 325), (width + 3, 316)), '#7A3644', 2.2, 0.82, solid=True)
    layer.soft(CX + 3, 331, 7, 3, '#FFFFFF', 0.42)


def draw_base_top(layer, color='#F6C5CE'):
    """Modest, opaque neutral camisole covering the whole torso."""
    body = spline(R((36, 546), (66, 512), (100, 500), (124, 560), (127, 640), (124, 700), (112, 770), (106, 836), (108, 866)))
    poly = symmetric(body)
    # Straps sit on the shoulders.
    straps = []
    for side in (1, -1):
        pts = R((86, 520), (84, 480), (84, 450))
        straps.append(ribbon(pts if side > 0 else flip(pts), [8, 7.5, 7]))
    m = poly_mask([poly] + straps)
    layer.wash(m, color, shade=0.25, edge=0.1, bleed=0.04, line=1.0, volume=30)
    layer.pencil(R((-122, 860), (0, 866), (122, 860)), mix(INK, color, 0.25), 1.6, 0.5)
    _bow(layer, CX, 566, 16, '#EFA4B7')
    layer.pencil(R((-60, 690), (-54, 760), (-64, 840)), mix(INK, color, 0.45), 1.8, 0.28)
    layer.pencil(R((60, 690), (54, 760), (64, 840)), mix(INK, color, 0.45), 1.8, 0.28)


def draw_base_bottom(layer, color='#F6C5CE'):
    """Matching opaque pink shorts."""
    right = R((106, 838), (122, 922), (156, 1004), (170, 1080), (170, 1166))
    inner = R((86, 1176), (12, 1166), (3, 1118))
    pts = spline(right) + inner + flip(inner)[::-1] + flip(spline(right))[::-1]
    m = poly_mask([pts])
    layer.wash(m, color, shade=0.26, edge=0.1, bleed=0.04, line=1.0, volume=26)
    layer.pencil(R((-110, 866), (0, 874), (110, 866)), mix(INK, color, 0.25), 1.7, 0.55)
    layer.pencil([(CX, 880), (CX, 1100)], mix(INK, color, 0.45), 1.8, 0.4, curve=False)
    _bow(layer, CX, 878, 11, '#EFA4B7')


def _bow(layer, x, y, s, color):
    left = [(x, y), (x - s * 1.5, y - s * .9), (x - s * 1.6, y + s * .9)]
    layer.fill([spline(left + [(x, y)], closed=True), spline(flip_about(left, x) + [(x, y)], closed=True)], color,
               shade=0.2, edge=0.05, bleed=0.02, line=0.75, volume=6)
    circle = [(x + math.cos(a / 10 * 6.283) * s * .32, y + math.sin(a / 10 * 6.283) * s * .32) for a in range(10)]
    layer.fill([circle], mix(color, '#C46A82', 0.5), shade=0.1, edge=0, line=0.5, volume=4)


def flip_about(points, x):
    return [(2 * x - px, py) for px, py in points]

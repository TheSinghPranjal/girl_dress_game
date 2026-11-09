"""Twelve hairstyles, each split into back and front layers.

Hair shape depends only on the style, never the character, so metadata and
alignment are shared and each character just supplies her own colour palette.
"""
import math
import random

import numpy as np

from body import circle
from engine import CX, R, flip, mix, poly_mask, ribbon, resample, spline

CROWN = [(0, 54), (66, 62), (116, 108), (134, 186), (128, 262), (94, 326)]
LINE = [(0, 146), (34, 152), (66, 180), (84, 232), (88, 292), (94, 326)]

STYLES = {
    'long_straight': 'Long Straight',
    'long_wavy': 'Long Wavy',
    'high_ponytail': 'High Ponytail',
    'low_ponytail': 'Low Ponytail',
    'double_ponytail': 'Double Ponytail',
    'braided': 'Side Braid',
    'messy_bun': 'Messy Bun',
    'high_bun': 'High Bun',
    'short_bob': 'Short Bob',
    'shoulder_wavy': 'Shoulder Wavy',
    'half_up': 'Half-Up',
    'curly': 'Curly',
}


def _s(points, side):
    return points if side > 0 else flip(points)


def _flow(root, via, end, amp, period, phase, count=44, arc=None):
    guide = [root, arc, via, end] if arc else [root, via, end]
    line = resample(spline(guide), count)
    out = []
    y0 = via[1] - 40
    for x, y in line:
        k = min(max((y - y0) / 170, 0), 1)
        out.append((x + amp * k * math.sin((y - y0) / period * 6.283 + phase), y))
    return out


class Painter:
    def __init__(self, back, front, pal, rng):
        self.back, self.front, self.pal, self.rng = back, front, pal, rng

    def tone(self, shade=None):
        if shade is None:
            shade = self.rng.random()
        return mix(self.pal['dark'], self.pal['light'], shade)

    def lock(self, layer, line, width, shade=None, strands=2, base=0.45):
        widths = [width * base, width * .86, width, width * .9, width * .62, 1.5]
        poly = ribbon(line, widths, steps=len(line) * 2)
        color = self.tone(shade)
        mask = poly_mask([poly])
        layer.wash(mask, color, shade=0.42, edge=0.1, bleed=0.02, line=0.72, line_color=self.pal['line'], volume=10, side=0)
        count = len(line)
        for k in range(strands):
            offset = self.rng.uniform(-.55, .55) * width
            pts = [(x + offset * (1 - i / count), y) for i, (x, y) in enumerate(line)][::3]
            layer.pencil(pts, mix(self.pal['line'], color, .35), 1.5, .42, clip=mask)
        hi = [(x - width * .22, y) for x, y in line[int(count * .2):int(count * .65)]][::3]
        if len(hi) > 2:
            layer.pencil(hi, self.pal['shine'], width * .18 + 1.2, .38, clip=mask)

    def mass(self, layer, polys, shade=.15):
        layer.fill(polys, self.tone(shade), shade=.3, edge=.08, bleed=.02, line=.6, line_color=self.pal['line'], volume=26, side=0)

    def cap(self, flat=False, part=True):
        layer = self.front
        for side in (1, -1):
            shape = spline(R(*CROWN)) + spline(R(*LINE))[::-1]
            self.mass(layer, [_s(shape, side)], shade=.42)
            for i in range(11):
                t = i / 10
                a = R((0 if part else 2, 62 + t * 56))
                if flat:
                    start = (CX + 4, 70 + t * 40)
                    end = R((96 + 36 * t, 150 + 130 * t))[0]
                    mid = R((64 + 44 * t, 92 + 80 * t))[0]
                else:
                    start = a[0]
                    mid = R((52 + 58 * t, 86 + 78 * t))[0]
                    end = R((104 + 26 * t, 190 + 104 * t))[0]
                layer.pencil(_s([start, mid, end], side), mix(self.pal['line'], self.pal['mid'], .3), 1.7, .42)
            layer.pencil(_s(spline(R(*LINE[1:])), side)[::4], self.pal['line'], 1.6, .5)
        if part:
            layer.pencil([(CX, 58), (CX + 1, 90), (CX, 121)], self.pal['line'], 2.2, .7)

    def locks(self, layer, count, root, via_x, via_y, end_x, end_y, amp, period, width, spread=.9, shade_lo=.2, shade_hi=.8, jitter=40):
        for i in range(count):
            u = i / max(count - 1, 1)
            for side in (1, -1):
                phase = self.rng.uniform(0, 6.28)
                r = R((root[0] + root[1] * u, root[2]))[0]
                v = R((via_x[0] + (via_x[1] - via_x[0]) * u, via_y))[0]
                e = R((end_x[0] + (end_x[1] - end_x[0]) * u, end_y + self.rng.uniform(-jitter, jitter)))[0]
                arc = R((78 + 52 * u, 128 + 44 * u))[0]
                line = _flow(r, v, e, amp * (1 + u * .3), period, phase, arc=arc)
                self.lock(layer, _s(line, side), width * spread + width * (1 - spread) * self.rng.random(),
                          shade=shade_lo + (shade_hi - shade_lo) * self.rng.random(), base=.12)

    def wisps(self, count=3):
        for side in (1, -1):
            for i in range(count):
                pts = R((62 + i * 12, 138 + i * 6), (104 + i * 6, 240 + i * 10), (112 + i * 7, 330 + i * 18))
                self.front.pencil(_s(pts, side), self.pal['mid'], 3.2, .7)

    def blob(self, layer, x, y, r, shade=None, spiral=True):
        layer.fill([circle(x, y, r, 22)], self.tone(shade), shade=.42, edge=.1, bleed=.02, line=.66,
                   line_color=self.pal['line'], volume=max(int(r * .5), 3), side=0)
        if spiral:
            pts = []
            for k in range(18):
                a = k * .75
                rr = r * (.74 - k * .036)
                pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
            layer.pencil(pts, self.pal['line'], 1.7, .46)

    def tie(self, layer, x, y, r=15):
        layer.fill([circle(x, y, r, 16)], self.pal['tie'], shade=.25, edge=.08, line=.8, volume=5)


def long_straight(p):
    p.mass(p.back, [spline(R((0, 70), (108, 116), (146, 300), (168, 640), (164, 960), (70, 990), (0, 960))
                           + flip(R((0, 70), (108, 116), (146, 300), (168, 640), (164, 960), (70, 990), (0, 960)))[::-1])], shade=.08)
    p.locks(p.back, 9, (30, 72, 130), (120, 172), 330, (96, 190), 980, 2, 300, 30, shade_lo=.05, shade_hi=.42)
    p.cap()
    p.locks(p.front, 3, (50, 40, 132), (126, 150), 330, (150, 186), 720, 2, 300, 22, shade_lo=.42, shade_hi=.82)


def long_wavy(p):
    outer = R((0, 70), (110, 116), (160, 300), (200, 620), (196, 930), (84, 1000), (0, 960))
    p.mass(p.back, [spline(outer) + flip(spline(outer))[::-1]], shade=.08)
    p.locks(p.back, 12, (30, 72, 130), (126, 192), 320, (96, 226), 985, 24, 215, 34, shade_lo=.05, shade_hi=.5)
    p.cap()
    p.locks(p.front, 3, (50, 40, 132), (128, 160), 330, (164, 214), 720, 22, 190, 22, shade_lo=.45, shade_hi=.86, jitter=60)


def shoulder_wavy(p):
    outer = R((0, 70), (110, 116), (160, 280), (176, 450), (150, 590), (60, 600), (0, 590))
    p.mass(p.back, [spline(outer) + flip(spline(outer))[::-1]], shade=.08)
    p.locks(p.back, 8, (30, 72, 130), (122, 168), 300, (70, 176), 590, 15, 130, 30, shade_lo=.05, shade_hi=.42)
    p.cap()
    p.locks(p.front, 3, (50, 40, 132), (126, 158), 310, (118, 172), 560, 16, 125, 24, shade_lo=.42, shade_hi=.86)


def short_bob(p):
    outer = R((0, 70), (110, 114), (152, 240), (158, 372), (126, 448), (60, 440), (0, 430))
    p.mass(p.back, [spline(outer) + flip(spline(outer))[::-1]], shade=.08)
    p.locks(p.back, 7, (30, 72, 130), (122, 154), 280, (66, 130), 448, 3, 220, 28, shade_lo=.05, shade_hi=.4, jitter=10)
    p.cap()
    p.locks(p.front, 3, (50, 40, 132), (122, 152), 280, (92, 134), 452, 3, 220, 22, shade_lo=.45, shade_hi=.85, jitter=8)
    for i in range(3):
        for side in (1, -1):
            p.front.pencil(_s(R((14 + i * 16, 122), (50 + i * 14, 150 + i * 6), (70 + i * 12, 186 + i * 14)), side), p.pal['mid'], 3, .7)


def curly(p):
    rng = p.rng
    outline = R((0, 54), (136, 96), (196, 260), (214, 470), (190, 640), (84, 700), (0, 680))
    p.mass(p.back, [spline(outline) + flip(spline(outline))[::-1]], shade=.05)
    p.locks(p.back, 13, (30, 72, 130), (118, 204), 300, (64, 214), 690, 25, 86, 27, shade_lo=.05, shade_hi=.5, jitter=46)
    p.cap(part=False)
    for i in range(20):
        side = 1 if i % 2 else -1
        a = .15 + (i // 2) / 10 * 1.35
        x, y = CX + side * math.cos(a) * 138, 196 - math.sin(a) * 128
        p.blob(p.front, x, y, rng.uniform(22, 30), shade=rng.uniform(.4, .8), spiral=False)
    p.locks(p.front, 5, (50, 50, 132), (118, 176), 300, (120, 214), 650, 22, 76, 20, shade_lo=.42, shade_hi=.9, jitter=50)


def high_ponytail(p):
    tail = _flow((CX + 8, 60), (CX + 140, 170), (CX + 160, 760), 16, 170, .6)
    for i, offset in enumerate((-30, 30, -14, 14, 0)):
        line = [(x + offset * min(1, k / 12) * (1 - k / 70), y) for k, (x, y) in enumerate(tail)]
        p.lock(p.back, line, 36, shade=.1 + i * .12)
    p.cap(flat=True, part=False)
    p.tie(p.front, CX + 6, 66, 17)
    p.wisps()


def low_ponytail(p):
    p.cap(flat=True, part=False)
    tail = _flow((CX + 112, 340), (CX + 150, 460), (CX + 136, 860), 13, 170, 1)
    for i, offset in enumerate((-22, 22, -9, 9, 0)):
        line = [(x + offset * min(1, k / 10), y) for k, (x, y) in enumerate(tail)]
        p.lock(p.front, line, 30, shade=.2 + i * .14)
    p.mass(p.back, [spline(R((-120, 170), (-136, 300), (-90, 420), (90, 420), (136, 300), (120, 170)))], shade=.08)
    p.tie(p.front, CX + 114, 344, 16)
    p.wisps(2)


def double_ponytail(p):
    p.mass(p.back, [spline(R((-120, 170), (-136, 300), (-90, 410), (90, 410), (136, 300), (120, 170)))], shade=.08)
    p.cap()
    for side in (1, -1):
        tail = _flow((CX + 128, 322), (CX + 172, 430), (CX + 172, 800), 15, 150, side * .7)
        for i, offset in enumerate((-20, 20, -8, 8, 0)):
            line = [(x + offset * min(1, k / 10), y) for k, (x, y) in enumerate(tail)]
            p.lock(p.front, _s(line, side), 26, shade=.2 + i * .14)
        x = CX + side * 128
        p.tie(p.front, x, 326, 15)


def braided(p):
    p.mass(p.back, [spline(R((-120, 170), (-136, 300), (-90, 410), (90, 410), (136, 300), (120, 170)))], shade=.08)
    p.cap()
    line = resample(spline([(CX + 118, 330), (CX + 138, 480), (CX + 120, 700), (CX + 112, 940)]), 22)
    for i, (x, y) in enumerate(line):
        s = 1 if i % 2 else -1
        w = 34 - i * .55
        poly = ribbon([(x - s * w * .7, y - 26), (x + s * w * .1, y), (x + s * w * .75, y + 28)], [10, w * .72, 8], steps=14)
        p.front.fill([poly], p.tone(.3 + (i % 3) * .2), shade=.4, edge=.1, bleed=.01, line=.68, line_color=p.pal['line'], volume=8, side=0)
    x, y = line[-1]
    tail = _flow((x, y), (x + 4, y + 30), (x + 8, y + 110), 3, 80, 0, count=16)
    p.lock(p.front, tail, 20, shade=.5)
    p.tie(p.front, x, y + 6, 13)
    p.wisps(2)


def messy_bun(p):
    rng = p.rng
    p.cap(flat=True, part=False)
    p.blob(p.front, CX, 66, 48, shade=.3)
    for i in range(10):
        a = i / 10 * 6.28
        p.blob(p.front, CX + math.cos(a) * 34, 66 + math.sin(a) * 26, rng.uniform(17, 26), shade=rng.uniform(.3, .85))
    p.tie(p.front, CX, 104, 11)
    p.wisps(3)


def high_bun(p):
    p.cap(flat=True, part=False)
    p.blob(p.front, CX, 64, 46, shade=.5)
    for r, shade in ((36, .4), (24, .62)):
        pts = [(CX + math.cos(k * .3) * r * (1 - k * .004), 64 + math.sin(k * .3) * r * .92) for k in range(26)]
        p.front.pencil(pts, p.pal['line'], 2.0, .46)
    p.tie(p.front, CX, 106, 11)


def half_up(p):
    long_wavy(p)
    p.blob(p.front, CX, 70, 34, shade=.55)
    p.tie(p.front, CX, 100, 10)


DRAWERS = {
    'long_straight': long_straight, 'long_wavy': long_wavy, 'high_ponytail': high_ponytail,
    'low_ponytail': low_ponytail, 'double_ponytail': double_ponytail, 'braided': braided,
    'messy_bun': messy_bun, 'high_bun': high_bun, 'short_bob': short_bob,
    'shoulder_wavy': shoulder_wavy, 'half_up': half_up, 'curly': curly,
}


def draw_hair(style, back, front, palette):
    rng = random.Random('hair-' + style)
    DRAWERS[style](Painter(back, front, palette, rng))

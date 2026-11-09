#!/usr/bin/env python3
"""Regenerates every illustration and assets/data/catalog.json.

Run from the repository root:  python3 tool/art_pipeline/build.py
Art is deterministic: the same recipe always produces the same file.
"""
import json
import multiprocessing as mp
import os
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import body as B  # noqa: E402
import catalog as C  # noqa: E402
import decor as D  # noqa: E402
import faces as F  # noqa: E402
import hair as HR  # noqa: E402
from engine import H, Layer, W  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ASSETS = os.path.join(ROOT, 'assets')
QUALITY = 84
THUMB = 240
CATEGORY_DIR = dict(tops='tops', bottoms='bottoms', dresses='dresses', jackets='jackets', shoes='shoes', accessories='accessories')


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, '/')


def bbox_of(layer, pad=3):
    ys, xs = np.where(layer.alpha > .012)
    if len(xs) == 0:
        return (0, 0, 1, 1)
    return (max(int(xs.min()) - pad, 0), max(int(ys.min()) - pad, 0), min(int(xs.max()) + pad + 1, W), min(int(ys.max()) + pad + 1, H))


def placement(box):
    x0, y0, x1, y1 = box
    return dict(anchorX=round(x0 / W, 5), anchorY=round(y0 / H, 5), width=round((x1 - x0) / W, 5), height=round((y1 - y0) / H, 5))


def save_crop(layer, box, path, quality=QUALITY):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    layer.to_image().crop(box).save(path, 'WEBP', quality=quality, alpha_quality=92, method=4)


def save_thumb(images, box, path):
    canvas = Image.new('RGBA', (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0))
    for image in images:
        canvas.alpha_composite(image.crop(box))
    canvas.thumbnail((THUMB - 16, THUMB - 16), Image.LANCZOS)
    out = Image.new('RGBA', (THUMB, THUMB), (0, 0, 0, 0))
    out.alpha_composite(canvas, ((THUMB - canvas.width) // 2, (THUMB - canvas.height) // 2))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path, 'WEBP', quality=86, method=4)


def union(a, b):
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))


def build_item(index):
    item = C.ALL[index]
    folder = os.path.join(ASSETS, 'clothing', CATEGORY_DIR[item.category])
    variants = []
    box = None
    extra_meta = []
    for key, label, hex_value in item.variants:
        layer = Layer(item.id)
        item.draw(layer, hex_value)
        if box is None:
            box = bbox_of(layer)
        path = os.path.join(folder, f'{item.id}__{key}.webp')
        save_crop(layer, box, path)
        images = [layer.to_image()]
        extra_paths = {}
        for slot, fn in item.extra:
            extra = Layer(item.id + slot)
            fn(extra, hex_value)
            extra_box = bbox_of(extra)
            extra_path = os.path.join(folder, f'{item.id}__{key}__{slot}.webp')
            save_crop(extra, extra_box, extra_path)
            images.insert(0, extra.to_image())
            extra_paths[slot] = (rel(extra_path), extra_box)
        full = box
        for _, ebox in extra_paths.values():
            full = union(full, ebox)
        thumb = os.path.join(folder, 'thumbs', f'{item.id}__{key}.webp')
        save_thumb(images, full, thumb)
        variants.append(dict(id=key, name=label, swatch=hex_value, assetPath=rel(path), thumbnailPath=rel(thumb),
                             extraAssetPaths=[v[0] for v in extra_paths.values()]))
        if not extra_meta:
            extra_meta = [dict(layerIndex=C.LAYER[slot], **placement(extra_paths[slot][1])) for slot, _ in item.extra]
    data = dict(id=item.id, name=item.name, category=item.category, subgroup=item.subgroup, assetPath=variants[0]['assetPath'],
                thumbnailPath=variants[0]['thumbnailPath'], layerIndex=item.layer, premium=item.premium, compatibleCharacters=[],
                colorVariants=variants if len(variants) > 1 or item.variants[0][0] != 'default' else variants, conflictsWith=item.conflicts,
                extraLayers=extra_meta, **placement(box))
    return data


def build_hair(style):
    folder = os.path.join(ASSETS, 'clothing', 'hairstyles', style)
    os.makedirs(folder, exist_ok=True)
    meta = None
    for ch in C.CHARACTERS:
        back, front = Layer('hair-b-' + style), Layer('hair-f-' + style)
        HR.draw_hair(style, back, front, ch['hair'])
        bb, fb = bbox_of(back), bbox_of(front)
        save_crop(back, bb, os.path.join(folder, f"{ch['id']}_back.webp"))
        save_crop(front, fb, os.path.join(folder, f"{ch['id']}_front.webp"))
        box = union(bb, fb)
        save_thumb([back.to_image(), front.to_image()], box, os.path.join(folder, f"{ch['id']}_thumb.webp"))
        meta = meta or dict(front=placement(fb), back=placement(bb))
    prefix = f'assets/clothing/hairstyles/{style}/{{character}}'
    return dict(id=f'hair_{style}', name=HR.STYLES[style], category='hair', subgroup=None, assetPath=f'{prefix}_front.webp',
                thumbnailPath=f'{prefix}_thumb.webp', layerIndex=C.LAYER['front_hair'], premium=style in ('braided', 'messy_bun'),
                compatibleCharacters=[], colorVariants=[], conflictsWith=[],
                extraLayers=[dict(assetPath=f'{prefix}_back.webp', layerIndex=C.LAYER['back_hair'], **meta['back'])], **meta['front'])


def build_character(index):
    ch = C.CHARACTERS[index]
    folder = os.path.join(ASSETS, 'characters', ch['id'])
    os.makedirs(folder, exist_ok=True)
    # The body takes its skin tone from the character's painted face.
    look = dict(ch['look'], id=ch['id'], skin=F.skin_of(ch['id']))
    figure = Layer('figure')
    B.draw_body(figure, look['skin'])
    B.draw_face(figure, look)
    top, bottom = Layer('base-top'), Layer('base-bottom')
    B.draw_base_top(top)
    B.draw_base_bottom(bottom)
    layers = {}
    for name, layer in (('body', figure), ('base_top', top), ('base_bottom', bottom)):
        box = bbox_of(layer)
        path = os.path.join(folder, name + '.webp')
        save_crop(layer, box, path, 90)
        layers[name] = dict(assetPath=rel(path), **placement(box))
    back, front = Layer('hair-b-' + ch['style']), Layer('hair-f-' + ch['style'])
    HR.draw_hair(ch['style'], back, front, ch['hair'])
    composed = Layer('c')
    composed.stamp(back)
    composed.stamp(figure)
    composed.stamp(bottom)
    composed.stamp(top)
    composed.stamp(front)
    for acc_id in ch['accessories']:
        item = C._by_id[acc_id]
        acc = Layer(item.id)
        item.draw(acc, item.variants[0][2])
        composed.stamp(acc)
    image = composed.to_image()
    # Portraits are the supplied paintings, not script-drawn art.
    source = Image.open(os.path.join(os.path.dirname(__file__), 'reference', ch['id'] + '_portrait.png'))
    portrait = source.convert('RGBA').resize((320, 320), Image.LANCZOS)
    portrait.save(os.path.join(folder, 'portrait.webp'), 'WEBP', quality=88, method=4)
    preview = image.resize((512, 1024), Image.LANCZOS)
    preview.save(os.path.join(folder, 'preview.webp'), 'WEBP', quality=88, method=4)
    return dict(id=ch['id'], name=ch['name'], order=index + 1, tagline=ch['tagline'], portraitPath=f'assets/characters/{ch["id"]}/portrait.webp',
                previewPath=f'assets/characters/{ch["id"]}/preview.webp', defaultHairstyleId='hair_' + ch['style'],
                defaultAccessoryIds=ch['accessories'], body=layers['body'], baseTop=dict(layerIndex=C.LAYER['base_top'], **layers['base_top']),
                baseBottom=dict(layerIndex=C.LAYER['base_bottom'], **layers['base_bottom']), bodyLayerIndex=C.LAYER['body'])


def build_decor():
    out = os.path.join(ASSETS, 'decorations')
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(ASSETS, 'backgrounds'), exist_ok=True)
    D.sketchbook(os.path.join(ASSETS, 'backgrounds', 'sketchbook.webp'))
    pieces = dict(mannequin=D.mannequin, polaroid=D.polaroid, vase=D.vase_flowers, room=D.window_vanity,
                  sprig=lambda l: D.sprig(l, 200, 460, 400, .7, 2, seed=3), hearts=D.hearts_doodle)
    for name, fn in pieces.items():
        layer = Layer(name)
        fn(layer)
        box = bbox_of(layer, 6)
        layer.to_image().crop(box).save(os.path.join(out, name + '.webp'), 'WEBP', quality=86, alpha_quality=90, method=4)
    banner = D.banner()
    banner.to_image().crop(bbox_of(banner, 4)).save(os.path.join(out, 'banner.webp'), 'WEBP', quality=86, alpha_quality=90, method=4)


def main():
    for sub in ('characters', 'clothing'):
        shutil.rmtree(os.path.join(ASSETS, sub), ignore_errors=True)
    os.makedirs(os.path.join(ASSETS, 'data'), exist_ok=True)
    build_decor()
    with mp.Pool(max(os.cpu_count() - 1, 2)) as pool:
        characters = pool.map(build_character, range(len(C.CHARACTERS)))
        items = pool.map(build_item, range(len(C.ALL)), chunksize=4)
        hair = pool.map(build_hair, list(HR.STYLES))
    data = dict(canvas=dict(width=W, height=H), characters=characters, items=items + hair)
    with open(os.path.join(ASSETS, 'data', 'catalog.json'), 'w') as fp:
        json.dump(data, fp, indent=1)
    print(f'Wrote {len(items)} items, {len(hair)} hairstyles, {len(characters)} characters')


if __name__ == '__main__':
    main()

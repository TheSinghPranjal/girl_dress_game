#!/usr/bin/env python3
"""Checks every asset against assets/data/catalog.json.

Reports missing files, wrong dimensions, invalid formats, missing metadata,
duplicate ids and folders absent from pubspec.yaml. Exits non-zero on failure.
Run from anywhere:  python3 tool/validate_assets.py
"""
import json
import os
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ITEM_FIELDS = ('id', 'name', 'category', 'assetPath', 'thumbnailPath', 'layerIndex', 'anchorX', 'anchorY', 'width', 'height',
               'premium', 'compatibleCharacters', 'colorVariants', 'conflictsWith')
FORMATS = {'WEBP', 'PNG'}
CATEGORY_MINIMUM = dict(tops=20, bottoms=20, dresses=20, jackets=10, shoes=10)
THUMB_SIZE = (240, 240)
errors = []
checked = 0


def fail(message):
    errors.append(message)


def check_image(path, expected=None, needs_alpha=True, owner=''):
    global checked
    full = os.path.join(ROOT, path)
    if not os.path.isfile(full):
        fail(f'{owner}: missing file {path}')
        return
    checked += 1
    try:
        with Image.open(full) as image:
            if image.format not in FORMATS:
                fail(f'{owner}: {path} is {image.format}, expected WEBP or PNG')
            if needs_alpha and image.mode not in ('RGBA', 'LA'):
                fail(f'{owner}: {path} has no transparency')
            if expected and (abs(image.width - expected[0]) > 1 or abs(image.height - expected[1]) > 1):
                fail(f'{owner}: {path} is {image.size}, metadata says {expected}')
    except OSError as error:
        fail(f'{owner}: {path} could not be read ({error})')


def expected_size(meta, canvas):
    return (round(meta['width'] * canvas[0]), round(meta['height'] * canvas[1]))


def main():
    with open(os.path.join(ROOT, 'assets', 'data', 'catalog.json')) as handle:
        data = json.load(handle)
    canvas = (data['canvas']['width'], data['canvas']['height'])
    characters = data['characters']
    if [c['id'] for c in characters] != ['mia', 'emma', 'lily', 'sofia', 'ava']:
        fail('characters: expected mia, emma, lily, sofia, ava in order')
    item_ids = [i.get('id') for i in data['items']]
    for duplicate in sorted({i for i in item_ids if item_ids.count(i) > 1}):
        fail(f'duplicate item id: {duplicate}')
    known = set(item_ids)
    for character in characters:
        for key in ('body', 'baseTop', 'baseBottom'):
            check_image(character[key]['assetPath'], expected_size(character[key], canvas), owner=character['id'])
        check_image(character['portraitPath'], (320, 320), needs_alpha=False, owner=character['id'])
        check_image(character['previewPath'], (512, 1024), owner=character['id'])
        for ref in [character['defaultHairstyleId'], *character['defaultAccessoryIds']]:
            if ref not in known:
                fail(f"{character['id']}: unknown default item {ref}")
    counts = {}
    for item in data['items']:
        missing = [field for field in ITEM_FIELDS if field not in item]
        owner = item.get('id', '<no id>')
        if missing:
            fail(f'{owner}: missing metadata {missing}')
            continue
        counts[item['category']] = counts.get(item['category'], 0) + 1
        for other in item['conflictsWith']:
            if other not in known:
                fail(f'{owner}: conflictsWith unknown item {other}')
        size = expected_size(item, canvas)
        if '{character}' in item['assetPath']:
            for character in characters:
                for path, want in ((item['assetPath'], size), (item['thumbnailPath'], THUMB_SIZE)):
                    check_image(path.replace('{character}', character['id']), want, owner=owner)
                for extra in item['extraLayers']:
                    check_image(extra['assetPath'].replace('{character}', character['id']), expected_size(extra, canvas), owner=owner)
            continue
        if not item['colorVariants']:
            fail(f'{owner}: has no artwork variants')
        ids = [v['id'] for v in item['colorVariants']]
        if len(ids) != len(set(ids)):
            fail(f'{owner}: duplicate colour variants')
        for variant in item['colorVariants']:
            check_image(variant['assetPath'], size, owner=owner)
            check_image(variant['thumbnailPath'], THUMB_SIZE, owner=owner)
            for extra_meta, path in zip(item['extraLayers'], variant.get('extraAssetPaths', [])):
                check_image(path, expected_size(extra_meta, canvas), owner=owner)
    for category, minimum in CATEGORY_MINIMUM.items():
        if counts.get(category, 0) < minimum:
            fail(f'{category}: {counts.get(category, 0)} items, need at least {minimum}')
    for path in ('assets/screens/home.webp', 'assets/screens/splash.webp', 'assets/backgrounds/sketchbook.webp'):
        check_image(path, needs_alpha=False, owner='screen')
    with open(os.path.join(ROOT, 'pubspec.yaml')) as handle:
        pubspec = handle.read()
    for folder, _, files in os.walk(os.path.join(ROOT, 'assets')):
        rel = os.path.relpath(folder, ROOT).replace(os.sep, '/')
        if rel.startswith('assets/fonts') or not files:
            continue
        if f'- {rel}/' not in pubspec:
            fail(f'pubspec.yaml does not list {rel}/')
    if errors:
        print(f'FAILED: {len(errors)} problem(s)')
        for message in errors:
            print(' -', message)
        return 1
    print(f'OK: {checked} images and {len(item_ids)} items validated. Counts: {counts}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

# Artwork guide

All character and clothing art in `assets/characters` and `assets/clothing` was drawn by the
script in `tool/art_pipeline`. It is a working, aligned set in a pencil-and-watercolour style,
but it is simpler than the hand-painted reference screens. Replace it file by file with
final illustrations whenever they are ready. No code changes are needed.

These use the supplied paintings directly, not script-drawn art:

- `assets/screens/home.webp` and `assets/screens/splash.webp`.
- Each character's `portrait.webp`, from `tool/art_pipeline/reference/<id>_portrait.png`.
- Each character's face on `body.webp`, cut from `tool/art_pipeline/reference/<id>_head.png`
  by `tool/art_pipeline/faces.py`. Body skin tone is sampled from the same painting.

## Drawing rules

- Canvas: 1024 x 2048, transparent, drawn over the shared figure in `tool/art_pipeline/body.py`.
- Pose: front-facing, arms slightly away from the body, identical for all five characters.
- Key heights on the canvas: crown 56, chin 360, shoulder 474, waist 834, hip 1064,
  knee 1470, ankle 1866, sole 2000. Body centre x = 512.
- Keep arms clear of skirts down to y = 1260, so hands remain visible.

## Replacing a file

1. Export the garment on the full canvas, or trimmed to its visible area.
2. Save as WebP or PNG at the same path, listed in `assets/data/catalog.json`.
3. Update the item's `anchorX`, `anchorY`, `width` and `height`. A full-canvas export uses
   0, 0, 1, 1. Values are fractions of the canvas.
4. Make a 240 x 240 transparent thumbnail at `thumbnailPath`.
5. Run `python3 tool/validate_assets.py`.

Running `tool/art_pipeline/build.py` regenerates and overwrites these folders, so stop using
it once final art is in place.

## What is needed per item

| Group | Files |
| --- | --- |
| Each character (5) | `body`, `base_top`, `base_bottom`, `portrait` (320 x 320), `preview` (512 x 1024) |
| Each garment | One full image and one thumbnail per colour |
| Backpack | Also a `__back` layer per colour |
| Each hairstyle (12) | `<character>_back`, `<character>_front`, `<character>_thumb` for all 5 characters |

Any file that is missing shows a labelled "Missing art" placeholder in the app.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/clothing_layer.dart';
import 'clothing_asset_loader.dart';
import 'clothing_position_resolver.dart';

/// A finished character picture at full canvas resolution.
class ComposedOutfit {
  ComposedOutfit(this.picture, this.canvasSize, this.missing);

  final ui.Picture picture;
  final Size canvasSize;

  /// Labels of layers drawn as placeholders because their art is missing.
  final List<String> missing;

  void dispose() => picture.dispose();
}

/// Builds and remembers composed pictures, so undo and repeat looks are instant.
class ClothingComposer {
  ClothingComposer(
    this._loader, {
    required this.canvasSize,
    this.resolver = const ClothingPositionResolver(),
    this.maxCached = 12,
  });

  final ClothingAssetLoader _loader;
  final ClothingPositionResolver resolver;
  final Size canvasSize;
  final int maxCached;
  final _cache = <String, ComposedOutfit>{};

  Future<ComposedOutfit> compose(List<ClothingLayer> layers) async {
    final signature = layers.map((l) => l.assetPath).join('|');
    final cached = _cache.remove(signature);
    if (cached != null) {
      _cache[signature] = cached;
      return cached;
    }
    final images = await Future.wait(layers.map((l) => _loader.load(l.assetPath)));
    final raced = _cache.remove(signature);
    if (raced != null) {
      _cache[signature] = raced;
      _disposeAll(images);
      return raced;
    }
    final composed = _paint(layers, images);
    _disposeAll(images);
    _cache[signature] = composed;
    while (_cache.length > maxCached) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
    return composed;
  }

  void _disposeAll(List<ui.Image?> images) {
    for (final image in images) {
      image?.dispose();
    }
  }

  ComposedOutfit _paint(List<ClothingLayer> layers, List<ui.Image?> images) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & canvasSize);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final missing = <String>[];
    for (var i = 0; i < layers.length; i++) {
      final rect = resolver.rectFor(layers[i].placement, canvasSize);
      final image = images[i];
      if (image == null) {
        missing.add(layers[i].label);
        _paintPlaceholder(canvas, rect, layers[i].label);
        continue;
      }
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );
    }
    return ComposedOutfit(recorder.endRecording(), canvasSize, missing);
  }

  void _paintPlaceholder(Canvas canvas, Rect rect, String label) {
    final fill = Paint()..color = AppColors.cream;
    final border = Paint()
      ..color = AppColors.rosePink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final box = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas
      ..drawRRect(box, fill)
      ..drawRRect(box, border);
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 34,
      maxLines: 4,
    ))
      ..pushStyle(ui.TextStyle(color: AppColors.charcoal))
      ..addText('Missing art:\n$label');
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: rect.width - 16));
    canvas.drawParagraph(
      paragraph,
      Offset(rect.left + 8, rect.center.dy - paragraph.height / 2),
    );
  }

  void dispose() {
    for (final composed in _cache.values) {
      composed.dispose();
    }
    _cache.clear();
  }
}

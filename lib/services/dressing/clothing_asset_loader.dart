import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Decodes layer images once and keeps recent ones ready to reuse.
///
/// Callers receive their own handle and must dispose it when finished.
class ClothingAssetLoader {
  ClothingAssetLoader({AssetBundle? bundle, this.maxEntries = 90})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final int maxEntries;
  final _cache = <String, ui.Image?>{};
  final _pending = <String, Future<ui.Image?>>{};

  /// Null means the file is missing or unreadable.
  Future<ui.Image?> load(String path) async {
    if (_cache.containsKey(path)) {
      final image = _cache.remove(path);
      _cache[path] = image;
      return image?.clone();
    }
    final image = await (_pending[path] ??= _decode(path));
    return image?.clone();
  }

  Future<ui.Image?> _decode(String path) async {
    ui.Image? image;
    try {
      final data = await _bundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ));
      image = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Exception {
      image = null;
    }
    _cache[path] = image;
    _pending.remove(path);
    _evict();
    return image;
  }

  void _evict() {
    while (_cache.length > maxEntries) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest)?.dispose();
    }
  }

  void dispose() {
    for (final image in _cache.values) {
      image?.dispose();
    }
    _cache.clear();
  }
}

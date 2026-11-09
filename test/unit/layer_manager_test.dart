import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:girl_dress_game/models/clothing_layer.dart';
import 'package:girl_dress_game/models/outfit.dart';
import 'package:girl_dress_game/models/outfit_history.dart';
import 'package:girl_dress_game/services/dressing/clothing_layer_manager.dart';
import 'package:girl_dress_game/services/dressing/clothing_position_resolver.dart';

import '../helpers/test_support.dart';

void main() {
  final catalog = realCatalog();
  final manager = ClothingLayerManager(catalog);
  final mia = Outfit.initial(catalog.character('mia'));

  int indexOf(List<ClothingLayer> layers, String fragment) =>
      layers.indexWhere((l) => l.assetPath.contains(fragment));

  test('base outfit shows until replaced', () {
    final base = manager.resolve(mia);
    expect(indexOf(base, 'base_top'), greaterThan(-1));
    expect(indexOf(base, 'base_bottom'), greaterThan(-1));
    final dressed = manager.resolve(mia.copyWith(topId: 'top_white_floral_tee'));
    expect(indexOf(dressed, 'base_top'), -1);
    expect(indexOf(dressed, 'base_bottom'), greaterThan(-1));
  });

  test('a dress hides both base pieces', () {
    final layers = manager.resolve(mia.copyWith(dressId: 'dress_pink_summer'));
    expect(indexOf(layers, 'base_top'), -1);
    expect(indexOf(layers, 'base_bottom'), -1);
  });

  test('layers paint in the documented order', () {
    final layers = manager.resolve(mia.copyWith(
      topId: 'top_white_floral_tee',
      bottomId: 'bottom_blue_wide_jeans',
      jacketId: 'jacket_blue_denim',
      shoeId: 'shoes_white_sneakers',
    ));
    final order = layers.map((l) => l.layerIndex).toList();
    expect(order, [...order]..sort());
    expect(indexOf(layers, '_back.webp'), lessThan(indexOf(layers, '/body.webp')));
    expect(indexOf(layers, 'shoes_white'), lessThan(indexOf(layers, 'bottom_blue')));
    expect(indexOf(layers, 'bottom_blue'), lessThan(indexOf(layers, 'top_white')));
    expect(indexOf(layers, 'top_white'), lessThan(indexOf(layers, 'jacket_blue')));
    expect(indexOf(layers, 'jacket_blue'), lessThan(indexOf(layers, '_front.webp')));
  });

  test('characters use their own body and hair files', () {
    final layers = manager.resolve(Outfit.initial(catalog.character('lily')));
    expect(layers.first.layerIndex, LayerOrder.backHair);
    expect(layers.any((l) => l.assetPath == 'assets/characters/lily/body.webp'), isTrue);
    expect(layers.any((l) => l.assetPath.contains('short_bob/lily_front')), isTrue);
    expect(layers.any((l) => l.assetPath.contains('{character}')), isFalse);
  });

  test('selected colour chooses the pre-painted artwork', () {
    final outfit = mia.copyWith(
      topId: 'top_pink_knit_sweater',
      colorVariants: {'top_pink_knit_sweater': 'blue'},
    );
    expect(manager.resolve(outfit).any((l) => l.assetPath.endsWith('sweater__blue.webp')), isTrue);
  });

  test('multi-layer accessories include their back layer', () {
    final outfit = mia.copyWith(accessoryIds: ['acc_bag_white_backpack']);
    final layers = manager.resolve(outfit);
    expect(layers.first.assetPath, contains('backpack__white__back'));
    expect(layers.first.layerIndex, LayerOrder.backAccessories);
  });

  test('normalised placement scales with the canvas', () {
    const placement = LayerPlacement(anchorX: .25, anchorY: .5, width: .5, height: .25);
    expect(const ClothingPositionResolver().rectFor(placement, const Size(400, 800)),
        const Rect.fromLTWH(100, 400, 200, 200));
  });

  group('history', () {
    final a = mia.copyWith(topId: 'top_white_floral_tee');
    final b = mia.copyWith(topId: 'top_pink_heart_tee');

    test('undo restores the previous outfit', () {
      expect(OutfitHistory(present: mia).record(a).undo().present, mia);
    });

    test('redo reapplies the undone outfit', () {
      expect(OutfitHistory(present: mia).record(a).undo().redo().present, a);
    });

    test('a new change clears redo', () {
      final history = OutfitHistory(present: mia).record(a).undo().record(b);
      expect(history.canRedo, isFalse);
      expect(history.present, b);
    });

    test('recording the same outfit adds nothing', () {
      expect(OutfitHistory(present: mia).record(mia).canUndo, isFalse);
    });

    test('history length is bounded', () {
      var history = OutfitHistory(present: mia);
      for (var i = 0; i < 200; i++) {
        history = history.record(mia.copyWith(shoeId: 'shoe$i'));
      }
      expect(history.past.length, OutfitHistory.maxEntries);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:girl_dress_game/features/dressing_room/controllers/outfit_rules.dart';
import 'package:girl_dress_game/models/clothing_item.dart';
import 'package:girl_dress_game/models/outfit.dart';
import 'package:girl_dress_game/models/wardrobe_catalog.dart';

import '../helpers/test_support.dart';

void main() {
  late WardrobeCatalog catalog;
  late OutfitRules rules;
  late Outfit start;

  ClothingItem item(String id) => catalog.item(id)!;
  Outfit wear(Outfit outfit, List<String> ids) =>
      ids.fold(outfit, (o, id) => rules.select(o, item(id)));

  setUp(() {
    catalog = realCatalog();
    rules = OutfitRules(catalog);
    start = Outfit.initial(catalog.character('mia'));
  });

  test('catalogue loads five characters in order with enough items', () {
    expect(catalog.characters.map((c) => c.name),
        ['Mia', 'Emma', 'Lily', 'Sofia', 'Ava']);
    final counts = {
      for (final c in WardrobeCategory.values) c: catalog.itemsFor(c, 'mia').length,
    };
    expect(counts[WardrobeCategory.tops], greaterThanOrEqualTo(20));
    expect(counts[WardrobeCategory.bottoms], greaterThanOrEqualTo(20));
    expect(counts[WardrobeCategory.dresses], greaterThanOrEqualTo(20));
    expect(counts[WardrobeCategory.jackets], greaterThanOrEqualTo(10));
    expect(counts[WardrobeCategory.shoes], greaterThanOrEqualTo(10));
    expect(counts[WardrobeCategory.hair], greaterThanOrEqualTo(12));
  });

  test('every character starts barefoot in the base outfit', () {
    for (final character in catalog.characters) {
      final outfit = Outfit.initial(character);
      expect(outfit.topId, isNull);
      expect(outfit.bottomId, isNull);
      expect(outfit.dressId, isNull);
      expect(outfit.shoeId, isNull);
      expect(outfit.hairstyleId, character.defaultHairstyleId);
    }
  });

  test('a top replaces the previous top and preserves everything else', () {
    final dressed = wear(start, [
      'top_white_floral_tee',
      'bottom_blue_wide_jeans',
      'shoes_white_sneakers',
      'acc_bag_pink_shoulder',
      'hair_high_bun',
    ]);
    final next = rules.select(dressed, item('top_pink_heart_tee'));
    expect(next.topId, 'top_pink_heart_tee');
    expect(next.bottomId, 'bottom_blue_wide_jeans');
    expect(next.shoeId, 'shoes_white_sneakers');
    expect(next.accessoryIds, contains('acc_bag_pink_shoulder'));
    expect(next.hairstyleId, 'hair_high_bun');
  });

  test('a bottom replaces the previous bottom and preserves the top', () {
    final dressed = wear(start, ['top_white_floral_tee', 'bottom_blue_wide_jeans']);
    final next = rules.select(dressed, item('bottom_denim_shorts'));
    expect(next.bottomId, 'bottom_denim_shorts');
    expect(next.topId, 'top_white_floral_tee');
  });

  test('a dress removes top and bottom but keeps accessories and hair', () {
    final dressed = wear(start, [
      'top_white_floral_tee',
      'bottom_blue_wide_jeans',
      'acc_necklace_heart',
      'hair_curly',
    ]);
    final next = rules.select(dressed, item('dress_pink_summer'));
    expect(next.dressId, 'dress_pink_summer');
    expect(next.topId, isNull);
    expect(next.bottomId, isNull);
    expect(next.accessoryIds, contains('acc_necklace_heart'));
    expect(next.hairstyleId, 'hair_curly');
  });

  test('a dress drops accessories it conflicts with', () {
    final dressed = wear(start, ['acc_bag_white_backpack']);
    final next = rules.select(dressed, item('dress_pink_princess'));
    expect(next.accessoryIds, isNot(contains('acc_bag_white_backpack')));
  });

  test('a top over a dress removes the dress and uses the default bottom', () {
    final dressed = wear(start, ['dress_pink_summer']);
    final next = rules.select(dressed, item('top_white_floral_tee'));
    expect(next.dressId, isNull);
    expect(next.topId, 'top_white_floral_tee');
    expect(next.bottomId, isNull);
  });

  test('a bottom over a dress removes the dress and uses the default top', () {
    final dressed = wear(start, ['dress_pink_summer']);
    final next = rules.select(dressed, item('bottom_denim_shorts'));
    expect(next.dressId, isNull);
    expect(next.bottomId, 'bottom_denim_shorts');
    expect(next.topId, isNull);
  });

  test('a jacket keeps the top and bottom', () {
    final dressed = wear(start, ['top_white_floral_tee', 'bottom_denim_shorts']);
    final next = rules.select(dressed, item('jacket_blue_denim'));
    expect(next.jacketId, 'jacket_blue_denim');
    expect(next.topId, 'top_white_floral_tee');
    expect(next.bottomId, 'bottom_denim_shorts');
  });

  test('shoes replace previous shoes', () {
    final next = wear(start, ['shoes_white_sneakers', 'shoes_pink_heels']);
    expect(next.shoeId, 'shoes_pink_heels');
  });

  test('tapping worn shoes returns to barefoot', () {
    expect(wear(start, ['shoes_white_sneakers', 'shoes_white_sneakers']).shoeId, isNull);
  });

  test('compatible accessories combine', () {
    final next = wear(start, ['acc_necklace_heart', 'acc_bag_pink_shoulder', 'acc_hat_sun']);
    expect(next.accessoryIds,
        containsAll(['acc_necklace_heart', 'acc_bag_pink_shoulder', 'acc_hat_sun']));
  });

  test('tapping a worn accessory removes it and never duplicates it', () {
    final once = wear(start, ['acc_necklace_heart']);
    expect(once.accessoryIds.where((id) => id == 'acc_necklace_heart').length, 1);
    final twice = rules.select(once, item('acc_necklace_heart'));
    expect(twice.accessoryIds, isNot(contains('acc_necklace_heart')));
  });

  test('accessories in the same group replace each other', () {
    final next = wear(start, ['acc_bag_pink_shoulder', 'acc_bag_beige_handbag']);
    expect(next.accessoryIds, contains('acc_bag_beige_handbag'));
    expect(next.accessoryIds, isNot(contains('acc_bag_pink_shoulder')));
  });

  test('hairstyles switch, and tapping again restores the original', () {
    final styled = rules.select(start, item('hair_messy_bun'));
    expect(styled.hairstyleId, 'hair_messy_bun');
    expect(rules.select(styled, item('hair_messy_bun')).hairstyleId,
        catalog.character('mia').defaultHairstyleId);
  });

  test('colour selection stores a real variant and ignores unknown ones', () {
    final top = item('top_pink_knit_sweater');
    final blue = rules.setColor(start, top, 'blue');
    expect(blue.colorVariants[top.id], 'blue');
    expect(rules.setColor(blue, top, 'tartan').colorVariants[top.id], 'blue');
  });

  test('sanitize removes locked premium items', () {
    final dressed = wear(start, ['dress_pink_princess']);
    expect(rules.sanitize(dressed, premiumUnlocked: false).dressId, isNull);
    expect(rules.sanitize(dressed, premiumUnlocked: true).dressId, 'dress_pink_princess');
  });
}

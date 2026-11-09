import '../../../models/character.dart';
import '../../../models/clothing_item.dart';
import '../../../models/outfit.dart';
import '../../../models/wardrobe_catalog.dart';

/// Every dressing rule, as pure functions from one outfit to the next.
class OutfitRules {
  const OutfitRules(this.catalog);

  final WardrobeCatalog catalog;

  /// The outfit after the player taps [item]. Tapping a worn item takes it off.
  Outfit select(Outfit outfit, ClothingItem item) {
    return switch (item.category) {
      WardrobeCategory.tops => outfit.copyWith(
          topId: outfit.topId == item.id ? null : item.id,
          dressId: null,
        ),
      WardrobeCategory.bottoms => outfit.copyWith(
          bottomId: outfit.bottomId == item.id ? null : item.id,
          dressId: null,
        ),
      WardrobeCategory.dresses => _selectDress(outfit, item),
      WardrobeCategory.jackets => outfit.copyWith(
          jacketId: outfit.jacketId == item.id ? null : item.id,
        ),
      WardrobeCategory.shoes => outfit.copyWith(
          shoeId: outfit.shoeId == item.id ? null : item.id,
        ),
      WardrobeCategory.accessories => _toggleAccessory(outfit, item),
      WardrobeCategory.hair => _selectHair(outfit, item),
    };
  }

  Outfit _selectDress(Outfit outfit, ClothingItem dress) {
    if (outfit.dressId == dress.id) return outfit.copyWith(dressId: null);
    return outfit.copyWith(
      dressId: dress.id,
      topId: null,
      bottomId: null,
      accessoryIds: outfit.accessoryIds
          .where((id) => !_conflict(catalog.item(id), dress))
          .toList(),
    );
  }

  Outfit _toggleAccessory(Outfit outfit, ClothingItem accessory) {
    if (outfit.accessoryIds.contains(accessory.id)) {
      return outfit.copyWith(
        accessoryIds:
            outfit.accessoryIds.where((id) => id != accessory.id).toList(),
      );
    }
    final kept = outfit.accessoryIds
        .where((id) => !_conflict(catalog.item(id), accessory))
        .toList();
    final clashingDress = _conflict(catalog.item(outfit.dressId), accessory);
    return outfit.copyWith(
      accessoryIds: [...kept, accessory.id],
      dressId: clashingDress ? null : outfit.dressId,
    );
  }

  Outfit _selectHair(Outfit outfit, ClothingItem hair) {
    if (outfit.hairstyleId != hair.id) {
      return outfit.copyWith(hairstyleId: hair.id);
    }
    final original = catalog.character(outfit.characterId).defaultHairstyleId;
    return outfit.copyWith(hairstyleId: original);
  }

  bool _conflict(ClothingItem? a, ClothingItem b) {
    if (a == null) return false;
    return a.conflictsWith.contains(b.id) || b.conflictsWith.contains(a.id);
  }

  /// Chooses a colourway for an item. Unknown colours are ignored.
  Outfit setColor(Outfit outfit, ClothingItem item, String variantId) {
    if (!item.colorVariants.any((v) => v.id == variantId)) return outfit;
    return outfit.copyWith(
      colorVariants: {...outfit.colorVariants, item.id: variantId},
    );
  }

  Outfit reset(Character character) => Outfit.initial(character);

  /// Drops anything no longer in the catalogue or no longer unlocked.
  Outfit sanitize(Outfit outfit, {required bool premiumUnlocked}) {
    final character = catalog.character(outfit.characterId);
    String? keep(String? id) {
      final item = catalog.item(id);
      if (item == null || !item.fits(character.id)) return null;
      if (item.premium && !premiumUnlocked) return null;
      return id;
    }

    return outfit.copyWith(
      topId: keep(outfit.topId),
      bottomId: keep(outfit.bottomId),
      dressId: keep(outfit.dressId),
      jacketId: keep(outfit.jacketId),
      shoeId: keep(outfit.shoeId),
      hairstyleId: keep(outfit.hairstyleId) ?? character.defaultHairstyleId,
      accessoryIds: outfit.accessoryIds.where((id) => keep(id) != null).toList(),
    );
  }
}

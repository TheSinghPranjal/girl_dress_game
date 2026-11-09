import '../../models/character.dart';
import '../../models/clothing_item.dart';
import '../../models/clothing_layer.dart';
import '../../models/outfit.dart';
import '../../models/wardrobe_catalog.dart';

/// Turns an outfit into the ordered list of images to paint.
class ClothingLayerManager {
  const ClothingLayerManager(this.catalog);

  final WardrobeCatalog catalog;

  List<ClothingLayer> resolve(Outfit outfit) {
    final character = catalog.character(outfit.characterId);
    final layers = <ClothingLayer>[
      _base(character.body, '${character.name} body'),
    ];
    if (outfit.dressId == null) {
      if (outfit.topId == null) {
        layers.add(_base(character.baseTop, 'Base camisole'));
      }
      if (outfit.bottomId == null) {
        layers.add(_base(character.baseBottom, 'Base shorts'));
      }
    }
    final worn = [
      outfit.hairstyleId,
      outfit.topId,
      outfit.bottomId,
      outfit.dressId,
      outfit.jacketId,
      outfit.shoeId,
      ...outfit.accessoryIds,
    ];
    for (final id in worn) {
      final item = catalog.item(id);
      if (item != null) layers.addAll(_itemLayers(item, outfit));
    }
    // Stable sort: equal indices keep the order above.
    final ordered = layers.asMap().entries.toList()
      ..sort((a, b) {
        final byLayer = a.value.layerIndex.compareTo(b.value.layerIndex);
        return byLayer != 0 ? byLayer : a.key.compareTo(b.key);
      });
    return [for (final entry in ordered) entry.value];
  }

  ClothingLayer _base(CharacterLayer layer, String label) => ClothingLayer(
        assetPath: layer.assetPath,
        layerIndex: layer.layerIndex,
        placement: layer.placement,
        label: label,
      );

  Iterable<ClothingLayer> _itemLayers(ClothingItem item, Outfit outfit) sync* {
    final variantId = outfit.colorVariants[item.id];
    final variant = item.variantById(variantId);
    yield ClothingLayer(
      assetPath: item.resolvedAsset(outfit.characterId, variantId),
      layerIndex: item.layerIndex,
      placement: item.placement,
      label: item.name,
    );
    for (var i = 0; i < item.extraLayers.length; i++) {
      final extra = item.extraLayers[i];
      final path = extra.assetPath ??
          (variant != null && i < variant.extraAssetPaths.length
              ? variant.extraAssetPaths[i]
              : null);
      if (path == null) continue;
      yield ClothingLayer(
        assetPath: path.replaceAll('{character}', outfit.characterId),
        layerIndex: extra.layerIndex,
        placement: extra.placement,
        label: item.name,
      );
    }
  }
}

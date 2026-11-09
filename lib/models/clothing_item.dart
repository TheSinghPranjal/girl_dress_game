import 'clothing_layer.dart';

enum WardrobeCategory {
  tops('Tops', 'assets/icons/cat_tops.svg'),
  bottoms('Bottoms', 'assets/icons/cat_bottoms.svg'),
  dresses('Dresses', 'assets/icons/cat_dresses.svg'),
  jackets('Jackets', 'assets/icons/cat_jackets.svg'),
  shoes('Shoes', 'assets/icons/cat_shoes.svg'),
  accessories('Accessories', 'assets/icons/cat_accessories.svg'),
  hair('Hair', 'assets/icons/cat_hair.svg');

  const WardrobeCategory(this.label, this.iconPath);

  final String label;
  final String iconPath;
}

/// A pre-painted colourway. Using separate artwork keeps the watercolour
/// shading and pencil lines intact, unlike a runtime colour filter.
class ColorVariant {
  const ColorVariant({
    required this.id,
    required this.name,
    required this.swatch,
    required this.assetPath,
    required this.thumbnailPath,
    this.extraAssetPaths = const [],
  });

  factory ColorVariant.fromJson(Map<String, dynamic> json) => ColorVariant(
        id: json['id'] as String,
        name: json['name'] as String,
        swatch: int.parse('FF${(json['swatch'] as String).substring(1)}',
            radix: 16),
        assetPath: json['assetPath'] as String,
        thumbnailPath: json['thumbnailPath'] as String,
        extraAssetPaths: List<String>.unmodifiable(
            (json['extraAssetPaths'] as List?) ?? const []),
      );

  final String id;
  final String name;

  /// ARGB colour shown in the swatch picker.
  final int swatch;
  final String assetPath;
  final String thumbnailPath;
  final List<String> extraAssetPaths;
}

/// A further image belonging to one item, such as the back half of a hairstyle.
class ExtraLayer {
  const ExtraLayer({
    required this.layerIndex,
    required this.placement,
    this.assetPath,
  });

  factory ExtraLayer.fromJson(Map<String, dynamic> json) => ExtraLayer(
        layerIndex: (json['layerIndex'] as num).toInt(),
        placement: LayerPlacement.fromJson(json),
        assetPath: json['assetPath'] as String?,
      );

  final int layerIndex;
  final LayerPlacement placement;
  final String? assetPath;
}

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.thumbnailPath,
    required this.layerIndex,
    required this.placement,
    this.subgroup,
    this.premium = false,
    this.compatibleCharacters = const [],
    this.colorVariants = const [],
    this.conflictsWith = const [],
    this.extraLayers = const [],
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: WardrobeCategory.values.byName(json['category'] as String),
        subgroup: json['subgroup'] as String?,
        assetPath: json['assetPath'] as String,
        thumbnailPath: json['thumbnailPath'] as String,
        layerIndex: (json['layerIndex'] as num).toInt(),
        placement: LayerPlacement.fromJson(json),
        premium: json['premium'] as bool? ?? false,
        compatibleCharacters: List<String>.unmodifiable(
            (json['compatibleCharacters'] as List?) ?? const []),
        colorVariants: List<ColorVariant>.unmodifiable(
          ((json['colorVariants'] as List?) ?? const []).map(
            (e) => ColorVariant.fromJson(e as Map<String, dynamic>),
          ),
        ),
        conflictsWith: List<String>.unmodifiable(
            (json['conflictsWith'] as List?) ?? const []),
        extraLayers: List<ExtraLayer>.unmodifiable(
          ((json['extraLayers'] as List?) ?? const []).map(
            (e) => ExtraLayer.fromJson(e as Map<String, dynamic>),
          ),
        ),
      );

  final String id;
  final String name;
  final WardrobeCategory category;
  final String? subgroup;
  final String assetPath;
  final String thumbnailPath;
  final int layerIndex;
  final LayerPlacement placement;
  final bool premium;

  /// Empty means every character can wear this item.
  final List<String> compatibleCharacters;
  final List<ColorVariant> colorVariants;
  final List<String> conflictsWith;
  final List<ExtraLayer> extraLayers;

  bool fits(String characterId) =>
      compatibleCharacters.isEmpty ||
      compatibleCharacters.contains(characterId);

  /// True when there is a real choice of colour to offer.
  bool get hasColorChoice => colorVariants.length > 1;

  ColorVariant? variantById(String? id) {
    if (colorVariants.isEmpty) return null;
    for (final variant in colorVariants) {
      if (variant.id == id) return variant;
    }
    return colorVariants.first;
  }

  String resolvedAsset(String characterId, String? variantId) =>
      _forCharacter(variantById(variantId)?.assetPath ?? assetPath, characterId);

  String resolvedThumbnail(String characterId, String? variantId) =>
      _forCharacter(
          variantById(variantId)?.thumbnailPath ?? thumbnailPath, characterId);

  String _forCharacter(String path, String characterId) =>
      path.replaceAll('{character}', characterId);
}

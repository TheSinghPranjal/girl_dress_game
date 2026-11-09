import 'character.dart';
import 'clothing_item.dart';

/// All characters and wardrobe items, read from assets/data/catalog.json.
class WardrobeCatalog {
  WardrobeCatalog({
    required this.canvasWidth,
    required this.canvasHeight,
    required List<Character> characters,
    required List<ClothingItem> items,
  })  : characters = List.unmodifiable(
            [...characters]..sort((a, b) => a.order.compareTo(b.order))),
        items = List.unmodifiable(items),
        _charactersById = {for (final c in characters) c.id: c},
        _itemsById = {for (final i in items) i.id: i};

  factory WardrobeCatalog.fromJson(Map<String, dynamic> json) {
    final canvas = json['canvas'] as Map<String, dynamic>;
    return WardrobeCatalog(
      canvasWidth: (canvas['width'] as num).toDouble(),
      canvasHeight: (canvas['height'] as num).toDouble(),
      characters: (json['characters'] as List)
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((e) => ClothingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final double canvasWidth;
  final double canvasHeight;
  final List<Character> characters;
  final List<ClothingItem> items;
  final Map<String, Character> _charactersById;
  final Map<String, ClothingItem> _itemsById;

  Character character(String id) => _charactersById[id] ?? characters.first;
  ClothingItem? item(String? id) => id == null ? null : _itemsById[id];

  List<ClothingItem> itemsFor(WardrobeCategory category, String characterId) =>
      items
          .where((i) => i.category == category && i.fits(characterId))
          .toList(growable: false);
}

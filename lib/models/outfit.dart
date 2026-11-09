import 'dart:convert';

import 'character.dart';

const _unset = Object();

/// What one character is currently wearing. Immutable.
///
/// A null [topId] or [bottomId] means the neutral base outfit shows in that
/// slot, unless a dress is being worn.
class Outfit {
  Outfit({
    required this.characterId,
    required this.hairstyleId,
    this.topId,
    this.bottomId,
    this.dressId,
    this.jacketId,
    this.shoeId,
    List<String> accessoryIds = const [],
    Map<String, String> colorVariants = const {},
  })  : accessoryIds = List.unmodifiable(accessoryIds),
        colorVariants = Map.unmodifiable(colorVariants);

  factory Outfit.initial(Character character) => Outfit(
        characterId: character.id,
        hairstyleId: character.defaultHairstyleId,
        accessoryIds: character.defaultAccessoryIds,
      );

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        characterId: json['characterId'] as String,
        hairstyleId: json['hairstyleId'] as String,
        topId: json['topId'] as String?,
        bottomId: json['bottomId'] as String?,
        dressId: json['dressId'] as String?,
        jacketId: json['jacketId'] as String?,
        shoeId: json['shoeId'] as String?,
        accessoryIds: ((json['accessoryIds'] as List?) ?? const [])
            .cast<String>()
            .toList(),
        colorVariants: ((json['colorVariants'] as Map?) ?? const {})
            .cast<String, String>(),
      );

  final String characterId;
  final String hairstyleId;
  final String? topId;
  final String? bottomId;
  final String? dressId;
  final String? jacketId;
  final String? shoeId;
  final List<String> accessoryIds;

  /// Selected colourway per item id.
  final Map<String, String> colorVariants;

  /// Every wardrobe item currently worn, including the hairstyle.
  Set<String> get wornIds => {
        hairstyleId,
        ?topId,
        ?bottomId,
        ?dressId,
        ?jacketId,
        ?shoeId,
        ...accessoryIds,
      };

  Outfit copyWith({
    Object? topId = _unset,
    Object? bottomId = _unset,
    Object? dressId = _unset,
    Object? jacketId = _unset,
    Object? shoeId = _unset,
    String? hairstyleId,
    List<String>? accessoryIds,
    Map<String, String>? colorVariants,
  }) =>
      Outfit(
        characterId: characterId,
        hairstyleId: hairstyleId ?? this.hairstyleId,
        topId: identical(topId, _unset) ? this.topId : topId as String?,
        bottomId:
            identical(bottomId, _unset) ? this.bottomId : bottomId as String?,
        dressId: identical(dressId, _unset) ? this.dressId : dressId as String?,
        jacketId:
            identical(jacketId, _unset) ? this.jacketId : jacketId as String?,
        shoeId: identical(shoeId, _unset) ? this.shoeId : shoeId as String?,
        accessoryIds: accessoryIds ?? this.accessoryIds,
        colorVariants: colorVariants ?? this.colorVariants,
      );

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'hairstyleId': hairstyleId,
        'topId': topId,
        'bottomId': bottomId,
        'dressId': dressId,
        'jacketId': jacketId,
        'shoeId': shoeId,
        'accessoryIds': accessoryIds,
        'colorVariants': colorVariants,
      };

  @override
  bool operator ==(Object other) =>
      other is Outfit && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// An outfit the player chose to keep.
class SavedOutfit {
  const SavedOutfit({
    required this.id,
    required this.name,
    required this.outfit,
    required this.thumbnailPath,
    required this.createdAt,
    this.characterConfiguration = const {},
  });

  factory SavedOutfit.fromJson(Map<String, dynamic> json) => SavedOutfit(
        id: json['id'] as String,
        name: json['name'] as String,
        outfit: Outfit.fromJson(json['outfit'] as Map<String, dynamic>),
        thumbnailPath: json['thumbnailPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        characterConfiguration:
            (json['characterConfiguration'] as Map?)?.cast<String, dynamic>() ??
                const {},
      );

  final String id;
  final String name;
  final Outfit outfit;
  final String? thumbnailPath;
  final DateTime createdAt;
  final Map<String, dynamic> characterConfiguration;

  SavedOutfit copyWith({
    String? name,
    Outfit? outfit,
    String? thumbnailPath,
  }) =>
      SavedOutfit(
        id: id,
        name: name ?? this.name,
        outfit: outfit ?? this.outfit,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        createdAt: createdAt,
        characterConfiguration: characterConfiguration,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'outfit': outfit.toJson(),
        'thumbnailPath': thumbnailPath,
        'createdAt': createdAt.toIso8601String(),
        'characterConfiguration': characterConfiguration,
      };
}

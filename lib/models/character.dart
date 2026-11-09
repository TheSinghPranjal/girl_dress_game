import 'clothing_layer.dart';

class CharacterLayer {
  const CharacterLayer({
    required this.assetPath,
    required this.layerIndex,
    required this.placement,
  });

  factory CharacterLayer.fromJson(
    Map<String, dynamic> json, {
    int? layerIndex,
    String? assetPath,
  }) =>
      CharacterLayer(
        assetPath: assetPath ?? json['assetPath'] as String,
        layerIndex: layerIndex ?? (json['layerIndex'] as num).toInt(),
        placement: LayerPlacement.fromJson(json),
      );

  final String assetPath;
  final int layerIndex;
  final LayerPlacement placement;
}

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.order,
    required this.tagline,
    required this.portraitPath,
    required this.previewPath,
    required this.defaultHairstyleId,
    required this.defaultAccessoryIds,
    required this.body,
    required this.baseTop,
    required this.baseBottom,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    final bodyIndex = (json['bodyLayerIndex'] as num).toInt();
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      tagline: json['tagline'] as String,
      portraitPath: json['portraitPath'] as String,
      previewPath: json['previewPath'] as String,
      defaultHairstyleId: json['defaultHairstyleId'] as String,
      defaultAccessoryIds:
          List<String>.unmodifiable(json['defaultAccessoryIds'] as List),
      body: CharacterLayer.fromJson(
        json['body'] as Map<String, dynamic>,
        layerIndex: bodyIndex,
      ),
      baseTop: CharacterLayer.fromJson(json['baseTop'] as Map<String, dynamic>),
      baseBottom:
          CharacterLayer.fromJson(json['baseBottom'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;
  final int order;
  final String tagline;
  final String portraitPath;
  final String previewPath;
  final String defaultHairstyleId;
  final List<String> defaultAccessoryIds;
  final CharacterLayer body;
  final CharacterLayer baseTop;
  final CharacterLayer baseBottom;
}

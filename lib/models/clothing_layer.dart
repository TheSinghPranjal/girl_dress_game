/// Normalised position of an image on the shared character canvas.
///
/// All values are fractions of the canvas, so art stays aligned at any size.
class LayerPlacement {
  const LayerPlacement({
    required this.anchorX,
    required this.anchorY,
    required this.width,
    required this.height,
  });

  factory LayerPlacement.fromJson(Map<String, dynamic> json) => LayerPlacement(
        anchorX: (json['anchorX'] as num).toDouble(),
        anchorY: (json['anchorY'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  static const fullCanvas =
      LayerPlacement(anchorX: 0, anchorY: 0, width: 1, height: 1);

  final double anchorX;
  final double anchorY;
  final double width;
  final double height;
}

/// One transparent image in the composed character, ready to paint.
class ClothingLayer {
  const ClothingLayer({
    required this.assetPath,
    required this.layerIndex,
    required this.placement,
    required this.label,
  });

  final String assetPath;
  final int layerIndex;
  final LayerPlacement placement;

  /// Shown on the placeholder if the artwork file is missing.
  final String label;
}

/// Paint order on the character. Lower values are painted first.
///
/// Shoes sit below bottoms so wide-leg hems fall over them, and hair
/// accessories sit above the front hair so they are never hidden.
abstract final class LayerOrder {
  static const backAccessories = 10;
  static const backHair = 20;
  static const body = 30;
  static const baseBottom = 40;
  static const baseTop = 41;
  static const shoes = 50;
  static const bottoms = 60;
  static const tops = 70;
  static const dresses = 80;
  static const jackets = 90;
  static const neckAccessories = 100;
  static const frontAccessories = 110;
  static const frontHair = 120;
  static const hairAccessories = 130;
  static const eyewear = 132;
  static const hats = 135;
}

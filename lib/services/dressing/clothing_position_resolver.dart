import 'dart:ui';

import '../../models/clothing_layer.dart';

/// Converts normalised placement into pixels on a canvas of any size.
class ClothingPositionResolver {
  const ClothingPositionResolver();

  Rect rectFor(LayerPlacement placement, Size canvas) => Rect.fromLTWH(
        placement.anchorX * canvas.width,
        placement.anchorY * canvas.height,
        placement.width * canvas.width,
        placement.height * canvas.height,
      );
}

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shows a full-screen painting and keeps overlays aligned to it.
///
/// The painting has extra paper above and below its central 9:16 art. Taller
/// phones reveal that paper, and wider screens keep the whole art visible.
class FullBleedArt extends StatelessWidget {
  const FullBleedArt({
    super.key,
    required this.asset,
    required this.imageSize,
    required this.artTop,
    required this.artHeight,
    required this.overlays,
  });

  final String asset;
  final Size imageSize;
  final double artTop;
  final double artHeight;

  /// Builds overlays. The mapper turns image pixels into screen pixels.
  final List<Widget> Function(Rect Function(Rect imageRect) map) overlays;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.warmPaper,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            var scale = width / imageSize.width;
            if (artHeight * scale > height) scale = height / artHeight;
            if (imageSize.height * scale < height) {
              scale = height / imageSize.height;
            }
            final origin = Offset(
              (width - imageSize.width * scale) / 2,
              (height - imageSize.height * scale) / 2,
            );
            Rect map(Rect r) => Rect.fromLTWH(
                  origin.dx + r.left * scale,
                  origin.dy + r.top * scale,
                  r.width * scale,
                  r.height * scale,
                );
            return ClipRect(
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: map(Offset.zero & imageSize),
                    child: Image.asset(asset, fit: BoxFit.fill, gaplessPlayback: true),
                  ),
                  ...overlays(map),
                ],
              ),
            );
          },
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// An invisible button over a button painted into full-screen art.
class ArtHotspot extends StatefulWidget {
  const ArtHotspot({
    super.key,
    required this.rect,
    required this.label,
    required this.onTap,
    this.radius = 24,
  });

  final Rect rect;
  final String label;
  final VoidCallback onTap;
  final double radius;

  @override
  State<ArtHotspot> createState() => _ArtHotspotState();
}

class _ArtHotspotState extends State<ArtHotspot> {
  bool _pressed = false;

  void _set(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: widget.rect,
        child: Semantics(
          button: true,
          label: widget.label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _set(true),
            onTapCancel: () => _set(false),
            onTapUp: (_) => _set(false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.rosePink.withValues(alpha: .28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(widget.radius),
              ),
            ),
          ),
        ),
      );
}

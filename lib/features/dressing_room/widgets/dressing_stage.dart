import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../character_selection/widgets/character_portrait.dart';
import '../controllers/dressing_controller.dart';
import 'character_canvas.dart';

/// Everything above the wardrobe: room art, portraits, character and controls.
class DressingStage extends ConsumerWidget {
  const DressingStage({
    super.key,
    required this.boundaryKey,
    required this.zoom,
    required this.savedPulse,
    required this.decoration,
    required this.onViewport,
    required this.onReset,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final GlobalKey boundaryKey;
  final TransformationController zoom;
  final int savedPulse;

  /// 1 shows the room decorations, 0 removes them on very small screens.
  final double decoration;
  final ValueChanged<Size> onViewport;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  static const _aspect = .5;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          onViewport(Size(width, height));
          // The hands reach 15.6% of the figure's height from its centre.
          final stripEdge = width * .205 + 22;
          final figureHeight =
              math.min(height - 8, (width / 2 - stripEdge - 4) / .156);
          return Stack(
            children: [
              if (decoration > 0) ..._decorations(width, height),
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: zoom,
                  minScale: 1,
                  maxScale: 4,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: figureHeight * .34,
                            height: figureHeight * .03,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80),
                              gradient: RadialGradient(colors: [
                                AppColors.rosePink.withValues(alpha: .34),
                                AppColors.rosePink.withValues(alpha: 0),
                              ]),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: figureHeight * _aspect,
                          height: figureHeight,
                          child: RepaintBoundary(
                            key: boundaryKey,
                            child: const CharacterCanvas(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 4,
                bottom: 62,
                width: width * .205,
                child: const _PortraitStrip(),
              ),
              Positioned(
                right: 6,
                top: 4,
                width: width * .3,
                child: const _NameTag(),
              ),
              Positioned(
                left: 24,
                right: 10,
                bottom: 22,
                child: Row(
                  children: [
                    PillSketchButton(
                      key: const Key('dress_reset'),
                      label: 'Reset',
                      icon: SketchIcons.reset,
                      onPressed: onReset,
                    ),
                    const Spacer(),
                    Consumer(
                      builder: (context, ref, _) => RoundSketchButton(
                        key: const Key('dress_redo'),
                        icon: SketchIcons.redo,
                        tooltip: 'Redo',
                        size: 46,
                        onPressed: ref.watch(canRedoProvider)
                            ? () => ref
                                .read(dressingControllerProvider.notifier)
                                .redo(ref.read(selectedCharacterIdProvider))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundSketchButton(
                      key: const Key('dress_zoom_out'),
                      icon: SketchIcons.zoomOut,
                      tooltip: 'Zoom out',
                      size: 46,
                      onPressed: onZoomOut,
                    ),
                    const SizedBox(width: 8),
                    RoundSketchButton(
                      key: const Key('dress_zoom_in'),
                      icon: SketchIcons.zoomIn,
                      tooltip: 'Zoom in',
                      size: 46,
                      onPressed: onZoomIn,
                    ),
                  ],
                ),
              ),
              if (savedPulse > 0) _SavedPop(key: ValueKey(savedPulse)),
            ],
          );
        },
      );

  List<Widget> _decorations(double width, double height) => [
        Positioned(
          left: width * .19,
          top: height * .02,
          height: height * .72,
          child: const IgnorePointer(child: SketchImage('assets/decorations/room.webp')),
        ),
        Positioned(
          right: width * .03,
          top: height * .135,
          height: height * .31,
          child: const IgnorePointer(child: SketchImage('assets/decorations/mannequin.webp')),
        ),
        Positioned(
          right: width * .045,
          top: height * .46,
          height: height * .2,
          child: const IgnorePointer(child: SketchImage('assets/decorations/polaroid.webp')),
        ),
        Positioned(
          right: width * .03,
          top: height * .665,
          height: height * .21,
          child: const IgnorePointer(child: SketchImage('assets/decorations/vase.webp')),
        ),
      ];
}

class _PortraitStrip extends ConsumerWidget {
  const _PortraitStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final selected = ref.watch(selectedCharacterIdProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBEEDC).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.brownInk.withValues(alpha: .3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownInk.withValues(alpha: .12),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxHeight / catalog.characters.length;
          final size = (slot / 1.28).clamp(30.0, constraints.maxWidth - 10);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final character in catalog.characters)
                CharacterPortrait(
                  key: Key('strip_${character.id}'),
                  character: character,
                  selected: character.id == selected,
                  size: size,
                  onTap: () => ref
                      .read(selectedCharacterIdProvider.notifier)
                      .select(character.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NameTag extends ConsumerWidget {
  const _NameTag();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(selectedCharacterProvider.select((c) => c.name));
    return IgnorePointer(
      child: SizedBox(
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/decorations/banner.webp',
                fit: BoxFit.fill, width: double.infinity, height: 50),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                name,
                key: ValueKey(name),
                style: const TextStyle(
                  fontFamily: AppFonts.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  height: 1,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const Positioned(left: 2, top: 2, child: HeartBeat(size: 16)),
          ],
        ),
      ),
    );
  }
}

class _SavedPop extends StatelessWidget {
  const _SavedPop({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            builder: (_, t, child) {
              final scale = Curves.elasticOut.transform((t / .35).clamp(0, 1));
              final opacity = t < .75 ? 1.0 : (1 - t) / .25;
              return Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.rosePink, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SketchIcon(SketchIcons.heart, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Outfit saved!',
                    style: TextStyle(
                      fontFamily: AppFonts.hand,
                      fontSize: 19,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

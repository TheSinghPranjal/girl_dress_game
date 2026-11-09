import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/full_bleed_art.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Where the loading bar sits in the supplied painting.
  static const _imageSize = Size(941, 2039);
  static const _artTop = 184.0;
  static const _bar = Rect.fromLTWH(230, 1525 + _artTop, 482, 42);

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  List<String> _paths() {
    final catalog = ref.read(catalogProvider);
    return [
      'assets/screens/home.webp',
      'assets/backgrounds/sketchbook.webp',
      'assets/decorations/banner.webp',
      'assets/decorations/mannequin.webp',
      'assets/decorations/polaroid.webp',
      'assets/decorations/vase.webp',
      'assets/decorations/room.webp',
      for (final character in catalog.characters) ...[
        character.portraitPath,
        character.previewPath,
      ],
    ];
  }

  Future<void> _load() async {
    final minimum = Future<void>.delayed(const Duration(milliseconds: 1800));
    final paths = _paths();
    for (var i = 0; i < paths.length; i++) {
      if (!mounted) return;
      await precacheImage(AssetImage(paths[i]), context, onError: (_, _) {});
      unawaited(_progress.animateTo((i + 1) / paths.length * .9));
    }
    final layers = ref.read(currentLayersProvider);
    await ref.read(composerProvider).compose(layers);
    await minimum;
    if (!mounted) return;
    await _progress.animateTo(1);
    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Semantics(
          label: 'Loading',
          child: FullBleedArt(
            asset: 'assets/screens/splash.webp',
            imageSize: _imageSize,
            artTop: _artTop,
            artHeight: 1671,
            overlays: (map) => [
              Positioned.fromRect(
                rect: map(_bar),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, _) =>
                      CustomPaint(painter: _LoadingBarPainter(_progress.value)),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Replaces the loading bar painted into the art with one that really moves.
class _LoadingBarPainter extends CustomPainter {
  _LoadingBarPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas
      ..drawRRect(track, Paint()..color = const Color(0xFFFBEFE4))
      ..save()
      ..clipRRect(track);
    final fillWidth = size.width * value.clamp(0, 1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillWidth, size.height),
      Paint()..color = AppColors.rosePink,
    );
    final stripe = Paint()
      ..color = AppColors.softPink.withValues(alpha: .7)
      ..strokeWidth = size.height * .26;
    canvas.clipRect(Rect.fromLTWH(0, 0, fillWidth, size.height));
    for (var x = -size.height; x < fillWidth + size.height; x += size.height * .9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
    canvas
      ..restore()
      ..drawRRect(
        track,
        Paint()
          ..color = AppColors.brownInk.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
  }

  @override
  bool shouldRepaint(_LoadingBarPainter old) => old.value != value;
}

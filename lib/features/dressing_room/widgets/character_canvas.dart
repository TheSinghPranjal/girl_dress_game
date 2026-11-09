import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';
import '../../../services/dressing/clothing_composer.dart';

/// Paints the composed character, with an entrance on switching characters
/// and a small settle when clothing changes.
class CharacterCanvas extends ConsumerStatefulWidget {
  const CharacterCanvas({super.key});

  @override
  ConsumerState<CharacterCanvas> createState() => _CharacterCanvasState();
}

class _CharacterCanvasState extends ConsumerState<CharacterCanvas>
    with TickerProviderStateMixin {
  ComposedOutfit? _composed;
  String? _shownCharacter;
  int _requestId = 0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 0,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_compose());
  }

  Future<void> _compose() async {
    final request = ++_requestId;
    final characterId = ref.read(selectedCharacterIdProvider);
    final layers = ref.read(currentLayersProvider);
    final composed = await ref.read(composerProvider).compose(layers);
    if (!mounted || request != _requestId) return;
    final switched = characterId != _shownCharacter;
    setState(() {
      _composed = composed;
      _shownCharacter = characterId;
    });
    if (switched) {
      unawaited(_entrance.forward(from: 0));
    } else {
      unawaited(_settle.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentLayersProvider, (_, _) => unawaited(_compose()));
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .025), end: Offset.zero).animate(fade),
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1, end: 1.012), weight: 40),
            TweenSequenceItem(tween: Tween(begin: 1.012, end: 1), weight: 60),
          ]).animate(_settle),
          child: CustomPaint(
            key: const Key('character_canvas'),
            size: Size.infinite,
            painter: _ComposedPainter(_composed),
          ),
        ),
      ),
    );
  }
}

class _ComposedPainter extends CustomPainter {
  _ComposedPainter(this.composed);

  final ComposedOutfit? composed;

  @override
  void paint(Canvas canvas, Size size) {
    final image = composed;
    if (image == null) return;
    final scale = size.width / image.canvasSize.width;
    canvas
      ..save()
      ..scale(scale)
      ..drawPicture(image.picture)
      ..restore();
  }

  @override
  bool shouldRepaint(_ComposedPainter old) => !identical(old.composed, composed);
}

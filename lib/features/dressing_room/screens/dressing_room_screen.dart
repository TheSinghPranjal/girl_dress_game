import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../../models/outfit.dart';
import '../../saved_outfits/providers/saved_outfits_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../wardrobe/widgets/wardrobe_panel.dart';
import '../controllers/dressing_controller.dart';
import '../widgets/dressing_stage.dart';
import '../widgets/save_outfit_sheet.dart';

class DressingRoomScreen extends ConsumerStatefulWidget {
  const DressingRoomScreen({super.key});

  @override
  ConsumerState<DressingRoomScreen> createState() => _DressingRoomScreenState();
}

class _DressingRoomScreenState extends ConsumerState<DressingRoomScreen>
    with SingleTickerProviderStateMixin {
  static const _tabletBreakpoint = 700.0;

  final _boundaryKey = GlobalKey();
  final _zoom = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTween;
  Size _viewport = Size.zero;
  int _savedPulse = 0;

  @override
  void initState() {
    super.initState();
    _zoomAnimation.addListener(() {
      final tween = _zoomTween;
      if (tween != null) _zoom.value = tween.value;
    });
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _zoom.dispose();
    super.dispose();
  }

  RenderRepaintBoundary get _boundary => _boundaryKey.currentContext!
      .findRenderObject()! as RenderRepaintBoundary;

  String get _characterId => ref.read(selectedCharacterIdProvider);
  DressingController get _controller =>
      ref.read(dressingControllerProvider.notifier);

  void _animateZoom(double target) {
    final clamped = target.clamp(1.0, 4.0);
    // Zoom around the middle of the view, which keeps the character centred.
    final focus = Offset(_viewport.width / 2, _viewport.height / 2);
    final next = Matrix4.identity()
      ..translateByDouble(focus.dx, focus.dy, 0, 1)
      ..scaleByDouble(clamped, clamped, clamped, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1);
    _zoomTween = Matrix4Tween(begin: _zoom.value, end: next).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOut),
    );
    _zoomAnimation.forward(from: 0);
  }

  double get _currentScale => _zoom.value.getMaxScaleOnAxis();

  void _reset() {
    final id = _characterId;
    final before = ref.read(currentOutfitProvider);
    _controller.reset(id);
    _animateZoom(1);
    if (before == ref.read(currentOutfitProvider)) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Back to the starting outfit'),
        action: SnackBarAction(label: 'Undo', onPressed: () => _controller.undo(id)),
      ));
  }

  Future<void> _openSave() async {
    final outfit = ref.read(currentOutfitProvider);
    final editing = ref.read(editingOutfitProvider);
    final editingThis = editing?.outfit.characterId == outfit.characterId;
    final result = await showModalBottomSheet<SaveSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SaveOutfitSheet(
        initialName: editingThis ? editing!.name : '',
        canUpdate: editingThis,
        exportBackground: ref.read(exportBackgroundProvider),
      ),
    );
    if (result == null || !mounted) return;
    if (result.action == SaveAction.share) {
      await _share(result.withBackground);
      return;
    }
    final updating = result.action == SaveAction.update ? editing : null;
    await _save(outfit, result.name, updating);
  }

  Future<void> _save(Outfit outfit, String name, SavedOutfit? updating) async {
    final id = updating?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final character = ref.read(selectedCharacterProvider);
    try {
      final thumb = await ref.read(exportServiceProvider).writeThumbnail(_boundary, id);
      final saved = updating?.copyWith(name: name, outfit: outfit, thumbnailPath: thumb) ??
          SavedOutfit(
            id: id,
            name: name,
            outfit: outfit,
            thumbnailPath: thumb,
            createdAt: DateTime.now(),
            characterConfiguration: {
              'defaultHairstyleId': character.defaultHairstyleId,
              'defaultAccessoryIds': character.defaultAccessoryIds,
            },
          );
      await ref.read(savedOutfitsProvider.notifier).put(saved);
      ref.read(editingOutfitProvider.notifier).set(saved);
      if (mounted) setState(() => _savedPulse++);
    } on Exception catch (error) {
      _message('That outfit could not be saved. ($error)');
    }
  }

  Future<void> _share(bool withBackground) async {
    final catalog = ref.read(catalogProvider);
    final service = ref.read(exportServiceProvider);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final file = await service.exportBoundary(
        _boundary,
        canvasHeight: catalog.canvasHeight,
        withBackground: withBackground,
      );
      await service.share(
        file,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } on Exception catch (error) {
      _message('The picture could not be exported. ($error)');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _header() {
    final canUndo = ref.watch(canUndoProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 6, 10, 2),
      child: Row(
        children: [
          RoundSketchButton(
            key: const Key('dress_back'),
            icon: SketchIcons.back,
            tooltip: 'Back',
            pink: true,
            size: 50,
            onPressed: () => popOrHome(context),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: LogoBanner(height: 58),
            ),
          ),
          RoundSketchButton(
            key: const Key('dress_undo'),
            icon: SketchIcons.undo,
            tooltip: 'Undo',
            size: 50,
            onPressed: canUndo ? () => _controller.undo(_characterId) : null,
          ),
          const SizedBox(width: 8),
          RoundSketchButton(
            key: const Key('dress_save'),
            icon: SketchIcons.save,
            tooltip: 'Save',
            pink: true,
            size: 50,
            onPressed: _openSave,
          ),
        ],
      ),
    );
  }

  Widget _stage(double decoration) => DressingStage(
        boundaryKey: _boundaryKey,
        zoom: _zoom,
        savedPulse: _savedPulse,
        decoration: decoration,
        onViewport: (size) => _viewport = size,
        onReset: _reset,
        onZoomIn: () => _animateZoom(_currentScale * 1.4),
        onZoomOut: () => _animateZoom(_currentScale / 1.4),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SketchbookBackground(
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                if (width >= _tabletBreakpoint) {
                  return Column(
                    children: [
                      _header(),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(flex: 11, child: _stage(1)),
                            const Expanded(
                              flex: 10,
                              child: WardrobePanel(sideBySide: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                final collapsed = math.max(height * .385, 268.0);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: height - collapsed - 4,
                      child: Column(
                        children: [
                          _header(),
                          Expanded(child: _stage(width < 340 ? 0 : 1)),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: WardrobePanel(
                        collapsedHeight: collapsed,
                        expandedHeight: height * .72,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

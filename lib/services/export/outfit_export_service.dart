import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../dressing/clothing_composer.dart';

/// Writes composed characters to PNG files and hands them to the share sheet.
class OutfitExportService {
  OutfitExportService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const _backgroundAsset = 'assets/backgrounds/sketchbook.webp';

  /// Captures the on-screen character only, at full art resolution.
  ///
  /// The boundary sits inside the zoom view, so zoom never affects the result.
  Future<File> exportBoundary(
    RenderRepaintBoundary boundary, {
    required double canvasHeight,
    required bool withBackground,
  }) async {
    final ratio = canvasHeight / boundary.size.height;
    final image = await boundary.toImage(pixelRatio: ratio);
    return _finish(image, withBackground, 'help_me_dress');
  }

  /// Renders a saved look at full resolution without showing it.
  Future<File> exportComposed(
    ComposedOutfit composed, {
    required bool withBackground,
  }) async {
    final image = await composed.picture.toImage(
      composed.canvasSize.width.toInt(),
      composed.canvasSize.height.toInt(),
    );
    return _finish(image, withBackground, 'help_me_dress');
  }

  /// Small transparent PNG for the saved-outfits gallery.
  Future<String> writeThumbnail(
    RenderRepaintBoundary boundary,
    String outfitId,
  ) async {
    final ratio = 720 / boundary.size.height;
    final image = await boundary.toImage(pixelRatio: ratio);
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(directory.path, 'outfit_thumbnails'));
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, '$outfitId.png'));
    await _writePng(image, file);
    return file.path;
  }

  Future<File> _finish(ui.Image image, bool withBackground, String name) async {
    final output = withBackground ? await _onSketchbook(image) : image;
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(directory.path, '${name}_$stamp.png'));
    await _writePng(output, file);
    if (!identical(output, image)) image.dispose();
    return file;
  }

  Future<ui.Image> _onSketchbook(ui.Image character) async {
    final data = await _bundle.load(_backgroundAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final background = (await codec.getNextFrame()).image;
    codec.dispose();
    final size = ui.Size(character.width.toDouble(), character.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    final scale = size.height / background.height;
    final sourceWidth = size.width / scale;
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
    canvas
      ..drawImageRect(
        background,
        ui.Rect.fromLTWH(0, 0, sourceWidth, background.height.toDouble()),
        ui.Offset.zero & size,
        paint,
      )
      ..drawImage(character, ui.Offset.zero, paint);
    background.dispose();
    final picture = recorder.endRecording();
    final merged = await picture.toImage(character.width, character.height);
    picture.dispose();
    return merged;
  }

  Future<void> _writePng(ui.Image image, File file) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('The image could not be encoded as PNG.');
    }
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }

  Future<void> share(File file, {ui.Rect? origin, String? text}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: text,
      sharePositionOrigin: origin,
    ));
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girl_dress_game/app/app.dart';
import 'package:girl_dress_game/app/bootstrap.dart';
import 'package:girl_dress_game/core/storage/app_providers.dart';
import 'package:girl_dress_game/features/dressing_room/controllers/dressing_controller.dart';
import 'package:girl_dress_game/features/saved_outfits/providers/saved_outfits_provider.dart';
import 'package:girl_dress_game/features/saved_outfits/screens/saved_outfits_screen.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_support.dart';

Future<void> settle(WidgetTester tester, [int seconds = 1]) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dress Mia, save, switch to Emma, restore Mia', (tester) async {
    final overrides = await bootstrap();
    final container = ProviderContainer(overrides: [
      ...overrides,
      // The store is replaced: this flow does not exercise billing.
      purchaseGatewayProvider.overrideWithValue(FakeGateway()),
    ]);
    addTearDown(container.dispose);
    await container.read(outfitStorageProvider).clearAll();
    container.invalidate(dressingControllerProvider);
    container.invalidate(savedOutfitsProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const HelpMeDressApp(),
    ));

    // Launch: splash loads art and moves on to Home by itself.
    await settle(tester, 5);
    expect(find.byKey(const Key('home_play')), findsOneWidget);

    await tap(tester, 'home_characters');
    await tap(tester, 'pick_mia');
    await tap(tester, 'start_dressing');
    await settle(tester, 2);

    await tap(tester, 'item_top_white_floral_tee');
    await tap(tester, 'category_bottoms');
    await tap(tester, 'item_bottom_blue_wide_jeans');
    await tap(tester, 'category_shoes');
    await tap(tester, 'item_shoes_white_sneakers');
    await tap(tester, 'category_accessories');
    await tap(tester, 'item_acc_bag_pink_shoulder');

    final dressed = container.read(currentOutfitProvider);
    expect(dressed.topId, 'top_white_floral_tee');
    expect(dressed.bottomId, 'bottom_blue_wide_jeans');
    expect(dressed.shoeId, 'shoes_white_sneakers');
    expect(dressed.accessoryIds, contains('acc_bag_pink_shoulder'));

    await tap(tester, 'dress_save');
    await tester.enterText(find.byKey(const Key('save_name')), 'Weekend Look');
    await settle(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await tap(tester, 'save_confirm');
    await settle(tester, 2);

    final saved = container.read(savedOutfitsProvider);
    expect(saved.single.name, 'Weekend Look');
    expect(saved.single.outfit, dressed);
    expect(saved.single.thumbnailPath, isNotNull);

    // Export: full-resolution PNG, with and without the sketchbook page.
    final boundary = tester.renderObject<RenderRepaintBoundary>(find
        .ancestor(
          of: find.byKey(const Key('character_canvas')),
          matching: find.byType(RepaintBoundary),
        )
        .first);
    final export = container.read(exportServiceProvider);
    Future<ui.Image> exported(bool withBackground) async {
      final file = await export.exportBoundary(
        boundary,
        canvasHeight: 2048,
        withBackground: withBackground,
      );
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      return (await codec.getNextFrame()).image;
    }

    final image = await exported(false);
    expect(image.width, 1024);
    expect(image.height, 2048);
    final pixels = (await image.toByteData())!;
    expect(pixels.getUint8(3), 0, reason: 'Corners must be transparent');
    final page = await exported(true);
    final pagePixels = (await page.toByteData())!;
    expect(pagePixels.getUint8(3), 255, reason: 'Sketchbook page must be opaque');

    await tap(tester, 'strip_emma');
    expect(container.read(selectedCharacterIdProvider), 'emma');
    expect(container.read(currentOutfitProvider).topId, isNull);

    await tap(tester, 'strip_mia');
    expect(container.read(currentOutfitProvider), dressed);

    await tap(tester, 'dress_back');
    await tap(tester, 'home_saved');
    expect(find.byType(SavedOutfitsScreen), findsOneWidget);
    expect(find.text('Weekend Look'), findsOneWidget);
  });
}

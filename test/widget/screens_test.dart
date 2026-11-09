import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girl_dress_game/app/app.dart';
import 'package:girl_dress_game/app/router.dart';
import 'package:girl_dress_game/core/storage/app_providers.dart';
import 'package:girl_dress_game/features/character_selection/screens/character_selection_screen.dart';
import 'package:girl_dress_game/features/dressing_room/screens/dressing_room_screen.dart';
import 'package:girl_dress_game/features/premium/screens/premium_screen.dart';
import 'package:girl_dress_game/features/saved_outfits/screens/saved_outfits_screen.dart';
import 'package:girl_dress_game/features/settings/screens/settings_screen.dart';
import 'package:girl_dress_game/models/clothing_item.dart';
import 'package:girl_dress_game/models/outfit.dart';
import 'package:girl_dress_game/services/purchase/purchase_gateway.dart';
import 'package:girl_dress_game/services/storage/outfit_storage_service.dart';

import '../helpers/test_support.dart';

const phone = Size(390, 844);
const compactPhone = Size(360, 640);
const tablet = Size(1024, 1366);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> launch(
  WidgetTester tester, {
  String route = Routes.home,
  Size size = phone,
  FakeGateway? gateway,
  OutfitStorageService? storage,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final overrides = await tester.runAsync(() => testOverrides(
        initialRoute: route,
        gateway: gateway,
        storage: storage,
      ));
  final container = ProviderContainer(overrides: overrides!);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const HelpMeDressApp(),
  ));
  await settle(tester);
  return container;
}

void main() {
  group('Home', () {
    final destinations = {
      'home_play': DressingRoomScreen,
      'home_characters': CharacterSelectionScreen,
      'home_saved': SavedOutfitsScreen,
      'home_settings': SettingsScreen,
    };
    destinations.forEach((key, screen) {
      testWidgets('$key opens $screen', (tester) async {
        await launch(tester);
        await tester.tap(find.byKey(Key(key)));
        await settle(tester);
        expect(find.byType(screen), findsOneWidget);
      });
    });

    for (final size in [compactPhone, phone, const Size(430, 932), tablet]) {
      testWidgets('buttons stay on screen at $size', (tester) async {
        await launch(tester, size: size);
        for (final key in destinations.keys) {
          final rect = tester.getRect(find.byKey(Key(key)));
          expect(Offset.zero & size, _Contains(rect));
        }
      });
    }
  });

  testWidgets('character selection updates the selected character', (tester) async {
    final c = await launch(tester, route: Routes.characters);
    expect(find.byKey(const Key('pick_ava')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick_sofia')));
    await settle(tester);
    expect(c.read(selectedCharacterIdProvider), 'sofia');
    expect(find.text('Dress Sofia'), findsOneWidget);
  });

  group('Dressing room', () {
    for (final size in [compactPhone, phone, tablet]) {
      testWidgets('lays out without overflow at $size', (tester) async {
        await launch(tester, route: Routes.dress, size: size);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('character_canvas')), findsOneWidget);
        expect(find.byKey(const Key('strip_ava')), findsOneWidget);
      });
    }

    testWidgets('tapping a card dresses the character', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      await tester.tap(find.byKey(const Key('item_top_white_floral_tee')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).topId, 'top_white_floral_tee');
    });

    testWidgets('all seven categories switch the grid', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      for (final category in WardrobeCategory.values) {
        await tester.tap(find.byKey(Key('category_${category.name}')));
        await settle(tester);
        final first = c.read(categoryItemsProvider).first;
        expect(c.read(selectedCategoryProvider), category);
        expect(find.byKey(Key('item_${first.id}')), findsOneWidget);
      }
    });

    testWidgets('a locked item opens the premium screen', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      final locked = c.read(categoryItemsProvider).firstWhere((i) => i.premium);
      await tester.dragUntilVisible(
        find.byKey(Key('item_${locked.id}')),
        find.byType(GridView),
        const Offset(0, -120),
      );
      await tester.tap(find.byKey(Key('item_${locked.id}')));
      await settle(tester);
      expect(find.byType(PremiumScreen), findsOneWidget);
      expect(c.read(currentOutfitProvider).wornIds, isNot(contains(locked.id)));
    });

    testWidgets('colour swatches appear for the worn item', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      await tester.tap(find.byKey(const Key('item_top_white_floral_tee')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('swatch_sage')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).colorVariants['top_white_floral_tee'], 'sage');
    });

    testWidgets('undo, redo and reset buttons work', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      await tester.tap(find.byKey(const Key('item_top_white_floral_tee')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('dress_undo')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).topId, isNull);
      await tester.tap(find.byKey(const Key('dress_redo')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).topId, 'top_white_floral_tee');
      await tester.tap(find.byKey(const Key('dress_reset')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).topId, isNull);
    });

    testWidgets('the portrait strip switches characters', (tester) async {
      final c = await launch(tester, route: Routes.dress);
      await tester.tap(find.byKey(const Key('strip_lily')));
      await settle(tester);
      expect(c.read(selectedCharacterIdProvider), 'lily');
      expect(find.text('Lily'), findsWidgets);
    });

    testWidgets('zoom buttons change and restore the view', (tester) async {
      await launch(tester, route: Routes.dress);
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final zoom = viewer.transformationController!;
      await tester.tap(find.byKey(const Key('dress_zoom_in')));
      await settle(tester);
      expect(zoom.value.getMaxScaleOnAxis(), greaterThan(1.2));
      await tester.tap(find.byKey(const Key('dress_reset')));
      await settle(tester);
      expect(zoom.value.getMaxScaleOnAxis(), closeTo(1, .01));
    });
  });

  group('Premium', () {
    testWidgets('with no store, purchase is disabled and nothing unlocks', (tester) async {
      final c = await launch(tester, route: Routes.premium);
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(find.byKey(const Key('premium_message')), findsOneWidget);
      await tester.tap(find.byKey(const Key('premium_buy')));
      await settle(tester);
      expect(c.read(currentOutfitProvider).dressId, isNull);
    });

    testWidgets('plans come from the store and buying calls it', (tester) async {
      final gateway = FakeGateway(
        available: true,
        products: const [StoreProduct(id: 'yearly', title: 'Yearly', price: '\$9')],
      );
      await launch(tester, route: Routes.premium, gateway: gateway);
      expect(find.text('\$9'), findsOneWidget);
      await tester.tap(find.byKey(const Key('premium_buy')));
      await settle(tester);
      expect(gateway.bought, ['yearly']);
    });

    testWidgets('restore calls the store', (tester) async {
      final gateway = FakeGateway();
      await launch(tester, route: Routes.premium, gateway: gateway);
      await tester.tap(find.byKey(const Key('premium_restore')));
      await settle(tester);
      expect(gateway.restoreCalls, 1);
    });
  });

  group('Saved outfits', () {
    SavedOutfit sample() => SavedOutfit(
          id: 'abc',
          name: 'Garden Party',
          outfit: Outfit.initial(realCatalog().character('emma'))
              .copyWith(topId: 'top_white_floral_tee'),
          thumbnailPath: null,
          createdAt: DateTime(2026),
        );

    Future<OutfitStorageService> seeded(WidgetTester tester) async {
      final storage = OutfitStorageService(
        saved: MemoryStringStore(),
        session: MemoryStringStore(),
      );
      await tester.runAsync(() => storage.put(sample()));
      return storage;
    }

    testWidgets('shows an empty state', (tester) async {
      await launch(tester, route: Routes.saved);
      expect(find.textContaining('saved looks'), findsOneWidget);
    });

    testWidgets('open loads the outfit on the right character', (tester) async {
      final c = await launch(tester, route: Routes.saved, storage: await seeded(tester));
      expect(find.text('Garden Party'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open_abc')));
      await settle(tester);
      expect(c.read(selectedCharacterIdProvider), 'emma');
      expect(c.read(currentOutfitProvider).topId, 'top_white_floral_tee');
      expect(find.byType(DressingRoomScreen), findsOneWidget);
    });

    testWidgets('delete asks first, then removes', (tester) async {
      await launch(tester, route: Routes.saved, storage: await seeded(tester));
      await tester.tap(find.byKey(const Key('delete_abc')));
      await settle(tester);
      expect(find.text('Garden Party'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_delete')));
      await settle(tester);
      expect(find.text('Garden Party'), findsNothing);
    });
  });
}

class _Contains extends Matcher {
  const _Contains(this.inner);

  final Rect inner;

  @override
  Description describe(Description description) => description.add('contains $inner');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final outer = item as Rect;
    return outer.left <= inner.left &&
        outer.top <= inner.top &&
        outer.right >= inner.right &&
        outer.bottom >= inner.bottom;
  }
}

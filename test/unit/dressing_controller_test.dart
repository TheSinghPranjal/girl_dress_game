import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girl_dress_game/core/storage/app_providers.dart';
import 'package:girl_dress_game/features/dressing_room/controllers/dressing_controller.dart';
import 'package:girl_dress_game/features/premium/providers/premium_provider.dart';
import 'package:girl_dress_game/models/outfit.dart';
import 'package:girl_dress_game/services/purchase/purchase_gateway.dart';
import 'package:girl_dress_game/services/storage/outfit_storage_service.dart';
import 'package:hive/hive.dart';

import '../helpers/test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = realCatalog();

  Future<ProviderContainer> container({
    FakeGateway? gateway,
    OutfitStorageService? storage,
  }) async {
    final result = ProviderContainer(
      overrides: await testOverrides(gateway: gateway, storage: storage),
    );
    addTearDown(result.dispose);
    return result;
  }

  DressingController controllerOf(ProviderContainer c) =>
      c.read(dressingControllerProvider.notifier);
  Outfit outfitOf(ProviderContainer c, String id) =>
      c.read(dressingControllerProvider).history(id).present;

  test('characters keep independent outfits when switching', () async {
    final c = await container();
    controllerOf(c).select('mia', catalog.item('top_white_floral_tee')!);
    c.read(selectedCharacterIdProvider.notifier).select('emma');
    expect(c.read(currentOutfitProvider).characterId, 'emma');
    expect(c.read(currentOutfitProvider).topId, isNull);
    c.read(selectedCharacterIdProvider.notifier).select('mia');
    expect(c.read(currentOutfitProvider).topId, 'top_white_floral_tee');
  });

  test('undo, redo and reset act only on one character', () async {
    final c = await container();
    final controller = controllerOf(c);
    controller.select('mia', catalog.item('top_white_floral_tee')!);
    controller.select('emma', catalog.item('shoes_white_sneakers')!);
    controller.undo('mia');
    expect(outfitOf(c, 'mia').topId, isNull);
    expect(outfitOf(c, 'emma').shoeId, 'shoes_white_sneakers');
    controller.redo('mia');
    expect(outfitOf(c, 'mia').topId, 'top_white_floral_tee');
    controller.reset('mia');
    expect(outfitOf(c, 'mia'), Outfit.initial(catalog.character('mia')));
    expect(c.read(selectedCharacterIdProvider), 'mia');
  });

  test('reset restores the hairstyle and signature accessories', () async {
    final c = await container();
    final controller = controllerOf(c);
    controller.select('mia', catalog.item('hair_curly')!);
    controller.select('mia', catalog.item('acc_hat_sun')!);
    controller.reset('mia');
    final outfit = outfitOf(c, 'mia');
    expect(outfit.hairstyleId, catalog.character('mia').defaultHairstyleId);
    expect(outfit.accessoryIds, catalog.character('mia').defaultAccessoryIds);
  });

  test('locked premium items are never applied', () async {
    final c = await container();
    final outcome = controllerOf(c).select('mia', catalog.item('dress_pink_princess')!);
    expect(outcome, SelectionOutcome.locked);
    expect(outfitOf(c, 'mia').dressId, isNull);
  });

  test('premium unlocks only from a store event', () async {
    final gateway = FakeGateway(
      available: true,
      products: const [StoreProduct(id: 'a', title: 'A', price: '1')],
    );
    final c = await container(gateway: gateway);
    c.read(premiumProvider);
    await pumpEventQueue();
    await c.read(premiumProvider.notifier).buy(gateway.products.first);
    await pumpEventQueue();
    expect(gateway.bought, ['a']);
    expect(c.read(isPremiumProvider), isFalse);
    gateway.controller.add(const StoreEvent(StoreEventType.entitled));
    await pumpEventQueue();
    expect(c.read(isPremiumProvider), isTrue);
    expect(
      controllerOf(c).select('mia', catalog.item('dress_pink_princess')!),
      SelectionOutcome.applied,
    );
  });

  test('a failed purchase leaves premium locked', () async {
    final gateway = FakeGateway(available: true);
    final c = await container(gateway: gateway);
    c.read(premiumProvider);
    await pumpEventQueue();
    gateway.controller.add(const StoreEvent(StoreEventType.failed, message: 'no'));
    await pumpEventQueue();
    expect(c.read(isPremiumProvider), isFalse);
  });

  group('persistence', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('hmd_hive');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Future<OutfitStorageService> open() async => OutfitStorageService(
          saved: HiveStringStore(await Hive.openBox<String>('saved')),
          session: HiveStringStore(await Hive.openBox<String>('session')),
        );

    test('saved outfits survive closing the database', () async {
      final storage = await open();
      final outfit = Outfit.initial(catalog.character('ava')).copyWith(
        topId: 'top_pink_heart_tee',
        colorVariants: {'top_pink_heart_tee': 'white'},
      );
      await storage.put(SavedOutfit(
        id: 'one',
        name: 'Picnic',
        outfit: outfit,
        thumbnailPath: '/tmp/x.png',
        createdAt: DateTime(2026, 1, 2),
      ));
      await Hive.close();
      final reopened = (await open()).loadAll();
      expect(reopened.single.name, 'Picnic');
      expect(reopened.single.outfit, outfit);
      expect(reopened.single.thumbnailPath, '/tmp/x.png');
      expect(reopened.single.createdAt, DateTime(2026, 1, 2));
    });

    test('deleting removes a saved outfit', () async {
      final storage = await open();
      await storage.put(SavedOutfit(
        id: 'x',
        name: 'x',
        outfit: Outfit.initial(catalog.character('mia')),
        thumbnailPath: null,
        createdAt: DateTime(2026),
      ));
      await storage.remove('x');
      expect(storage.loadAll(), isEmpty);
    });

    test('working outfits restore per character after restart', () async {
      final storage = await open();
      final first = await container(storage: storage);
      controllerOf(first).select('sofia', catalog.item('top_white_floral_tee')!);
      await pumpEventQueue();
      await Hive.close();
      final second = await container(storage: await open());
      expect(outfitOf(second, 'sofia').topId, 'top_white_floral_tee');
      expect(outfitOf(second, 'mia').topId, isNull);
    });

    test('a corrupt record is skipped rather than crashing', () async {
      final storage = await open();
      await storage.saved.write('bad', 'not json');
      expect(storage.loadAll(), isEmpty);
    });
  });
}

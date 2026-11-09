import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:girl_dress_game/app/router.dart';
import 'package:girl_dress_game/core/storage/app_providers.dart';
import 'package:girl_dress_game/models/wardrobe_catalog.dart';
import 'package:girl_dress_game/services/dressing/clothing_asset_loader.dart';
import 'package:girl_dress_game/services/purchase/purchase_gateway.dart';
import 'package:girl_dress_game/services/storage/outfit_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real shipped catalogue, so tests also cover the real data.
WardrobeCatalog realCatalog() => WardrobeCatalog.fromJson(
      jsonDecode(File('assets/data/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );

class FakeGateway implements PurchaseGateway {
  FakeGateway({this.available = false, this.products = const []});

  final bool available;
  final List<StoreProduct> products;
  final controller = StreamController<StoreEvent>.broadcast();
  final bought = <String>[];
  int restoreCalls = 0;

  @override
  Stream<StoreEvent> get events => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<StoreProduct>> loadProducts() async => products;

  @override
  Future<void> buy(StoreProduct product) async => bought.add(product.id);

  @override
  Future<void> restore() async => restoreCalls++;

  @override
  void dispose() => controller.close();
}

/// Reports every layer as missing, so widget tests need no image decoding.
class NoImagesLoader extends ClothingAssetLoader {
  @override
  Future<ui.Image?> load(String path) async => null;
}

Future<List<Override>> testOverrides({
  FakeGateway? gateway,
  String initialRoute = Routes.home,
  OutfitStorageService? storage,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    catalogProvider.overrideWithValue(realCatalog()),
    sharedPreferencesProvider.overrideWithValue(prefs),
    outfitStorageProvider.overrideWithValue(storage ??
        OutfitStorageService(
          saved: MemoryStringStore(),
          session: MemoryStringStore(),
        )),
    purchaseGatewayProvider.overrideWithValue(gateway ?? FakeGateway()),
    assetLoaderProvider.overrideWithValue(NoImagesLoader()),
    initialRouteProvider.overrideWithValue(initialRoute),
  ];
}

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/app_providers.dart';
import '../models/wardrobe_catalog.dart';
import '../services/purchase/purchase_gateway.dart';
import '../services/storage/outfit_storage_service.dart';

Future<WardrobeCatalog> loadCatalog([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString('assets/data/catalog.json');
  return WardrobeCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Opens storage and the catalogue before the first frame.
Future<List<Override>> bootstrap() async {
  await Hive.initFlutter();
  final saved = await Hive.openBox<String>('saved_outfits');
  final session = await Hive.openBox<String>('session_outfits');
  final prefs = await SharedPreferences.getInstance();
  final catalog = await loadCatalog();
  return [
    catalogProvider.overrideWithValue(catalog),
    sharedPreferencesProvider.overrideWithValue(prefs),
    outfitStorageProvider.overrideWithValue(OutfitStorageService(
      saved: HiveStringStore(saved),
      session: HiveStringStore(session),
    )),
    purchaseGatewayProvider.overrideWith((ref) {
      final gateway = InAppPurchaseGateway();
      ref.onDispose(gateway.dispose);
      return gateway;
    }),
  ];
}

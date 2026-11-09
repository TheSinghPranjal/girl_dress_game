import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/character.dart';
import '../../models/clothing_item.dart';
import '../../models/clothing_layer.dart';
import '../../models/outfit.dart';
import '../../models/wardrobe_catalog.dart';
import '../../services/dressing/clothing_asset_loader.dart';
import '../../services/dressing/clothing_composer.dart';
import '../../services/dressing/clothing_layer_manager.dart';
import '../../services/export/outfit_export_service.dart';
import '../../services/purchase/purchase_gateway.dart';
import '../../services/storage/outfit_storage_service.dart';
import '../../features/dressing_room/controllers/dressing_controller.dart';

/// These are supplied at launch in `main`, and by fakes in tests.
final catalogProvider = Provider<WardrobeCatalog>(
    (ref) => throw UnimplementedError('catalogProvider must be overridden'));
final outfitStorageProvider = Provider<OutfitStorageService>(
    (ref) => throw UnimplementedError('outfitStorageProvider must be overridden'));
final sharedPreferencesProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'));
final purchaseGatewayProvider = Provider<PurchaseGateway>(
    (ref) => throw UnimplementedError('purchaseGatewayProvider must be overridden'));

final assetLoaderProvider = Provider<ClothingAssetLoader>((ref) {
  final loader = ClothingAssetLoader();
  ref.onDispose(loader.dispose);
  return loader;
});

final composerProvider = Provider<ClothingComposer>((ref) {
  final catalog = ref.watch(catalogProvider);
  final composer = ClothingComposer(
    ref.watch(assetLoaderProvider),
    canvasSize: Size(catalog.canvasWidth, catalog.canvasHeight),
  );
  ref.onDispose(composer.dispose);
  return composer;
});

final layerManagerProvider = Provider<ClothingLayerManager>(
    (ref) => ClothingLayerManager(ref.watch(catalogProvider)));

final exportServiceProvider =
    Provider<OutfitExportService>((ref) => OutfitExportService());

const _selectedCharacterKey = 'selected_character';

final selectedCharacterIdProvider =
    NotifierProvider<SelectedCharacterNotifier, String>(
        SelectedCharacterNotifier.new);

class SelectedCharacterNotifier extends Notifier<String> {
  @override
  String build() {
    final catalog = ref.watch(catalogProvider);
    final stored =
        ref.watch(sharedPreferencesProvider).getString(_selectedCharacterKey);
    final known = catalog.characters.any((c) => c.id == stored);
    return known ? stored! : catalog.characters.first.id;
  }

  void select(String characterId) {
    state = characterId;
    ref.read(sharedPreferencesProvider)
        .setString(_selectedCharacterKey, characterId);
  }
}

final selectedCharacterProvider = Provider<Character>((ref) => ref
    .watch(catalogProvider)
    .character(ref.watch(selectedCharacterIdProvider)));

final currentOutfitProvider = Provider<Outfit>((ref) {
  final id = ref.watch(selectedCharacterIdProvider);
  return ref.watch(
      dressingControllerProvider.select((s) => s.history(id).present));
});

final canUndoProvider = Provider<bool>((ref) {
  final id = ref.watch(selectedCharacterIdProvider);
  return ref
      .watch(dressingControllerProvider.select((s) => s.history(id).canUndo));
});

final canRedoProvider = Provider<bool>((ref) {
  final id = ref.watch(selectedCharacterIdProvider);
  return ref
      .watch(dressingControllerProvider.select((s) => s.history(id).canRedo));
});

final currentLayersProvider = Provider<List<ClothingLayer>>((ref) => ref
    .watch(layerManagerProvider)
    .resolve(ref.watch(currentOutfitProvider)));

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, WardrobeCategory>(
        SelectedCategoryNotifier.new);

class SelectedCategoryNotifier extends Notifier<WardrobeCategory> {
  @override
  WardrobeCategory build() => WardrobeCategory.tops;

  void select(WardrobeCategory category) => state = category;
}

final categoryItemsProvider = Provider<List<ClothingItem>>((ref) => ref
    .watch(catalogProvider)
    .itemsFor(ref.watch(selectedCategoryProvider),
        ref.watch(selectedCharacterIdProvider)));

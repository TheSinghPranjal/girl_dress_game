import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';
import '../../../models/outfit.dart';

final savedOutfitsProvider =
    NotifierProvider<SavedOutfitsNotifier, List<SavedOutfit>>(
        SavedOutfitsNotifier.new);

class SavedOutfitsNotifier extends Notifier<List<SavedOutfit>> {
  @override
  List<SavedOutfit> build() => ref.watch(outfitStorageProvider).loadAll();

  Future<void> put(SavedOutfit outfit) async {
    await ref.read(outfitStorageProvider).put(outfit);
    state = ref.read(outfitStorageProvider).loadAll();
  }

  Future<void> delete(SavedOutfit outfit) async {
    await ref.read(outfitStorageProvider).remove(outfit.id);
    final path = outfit.thumbnailPath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    state = ref.read(outfitStorageProvider).loadAll();
  }

  Future<void> clear() async {
    for (final outfit in [...state]) {
      await delete(outfit);
    }
  }
}

/// The saved look being edited in the dressing room, if any.
final editingOutfitProvider =
    NotifierProvider<EditingOutfitNotifier, SavedOutfit?>(
        EditingOutfitNotifier.new);

class EditingOutfitNotifier extends Notifier<SavedOutfit?> {
  @override
  SavedOutfit? build() => null;

  void set(SavedOutfit? outfit) => state = outfit;
}

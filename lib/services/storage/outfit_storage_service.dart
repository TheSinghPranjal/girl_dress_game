import 'dart:convert';

import 'package:hive/hive.dart';

import '../../models/outfit.dart';

/// Minimal string store, so storage logic can run without a device.
abstract class StringStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Iterable<String> get keys;
}

class HiveStringStore implements StringStore {
  HiveStringStore(this._box);

  final Box<String> _box;

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}

class MemoryStringStore implements StringStore {
  final _data = <String, String>{};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Iterable<String> get keys => _data.keys;
}

/// Saved looks and each character's working outfit.
class OutfitStorageService {
  OutfitStorageService({required this.saved, required this.session});

  final StringStore saved;
  final StringStore session;

  List<SavedOutfit> loadAll() {
    final outfits = <SavedOutfit>[];
    for (final key in saved.keys) {
      final raw = saved.read(key);
      if (raw == null) continue;
      try {
        outfits.add(SavedOutfit.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return outfits..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> put(SavedOutfit outfit) =>
      saved.write(outfit.id, jsonEncode(outfit.toJson()));

  Future<void> remove(String id) => saved.delete(id);

  Outfit? loadSession(String characterId) {
    final raw = session.read(characterId);
    if (raw == null) return null;
    try {
      return Outfit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> saveSession(Outfit outfit) =>
      session.write(outfit.characterId, jsonEncode(outfit.toJson()));

  Future<void> clearAll() async {
    for (final key in saved.keys.toList()) {
      await saved.delete(key);
    }
    for (final key in session.keys.toList()) {
      await session.delete(key);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';
import '../../../models/clothing_item.dart';
import '../../../models/outfit.dart';
import '../../../models/outfit_history.dart';
import '../../premium/providers/premium_provider.dart';
import 'outfit_rules.dart';

enum SelectionOutcome { applied, locked, incompatible }

/// One independent undo history per character.
class DressingState {
  DressingState(Map<String, OutfitHistory> histories)
      : histories = Map.unmodifiable(histories);

  final Map<String, OutfitHistory> histories;

  OutfitHistory history(String characterId) => histories[characterId]!;
}

final outfitRulesProvider =
    Provider<OutfitRules>((ref) => OutfitRules(ref.watch(catalogProvider)));

final dressingControllerProvider =
    NotifierProvider<DressingController, DressingState>(DressingController.new);

class DressingController extends Notifier<DressingState> {
  OutfitRules get _rules => ref.read(outfitRulesProvider);

  @override
  DressingState build() {
    final catalog = ref.watch(catalogProvider);
    final storage = ref.watch(outfitStorageProvider);
    final unlocked = ref.read(isPremiumProvider);
    final rules = OutfitRules(catalog);
    return DressingState({
      for (final character in catalog.characters)
        character.id: OutfitHistory(
          present: rules.sanitize(
            storage.loadSession(character.id) ?? Outfit.initial(character),
            premiumUnlocked: unlocked,
          ),
        ),
    });
  }

  void _commit(String characterId, OutfitHistory history) {
    state = DressingState({...state.histories, characterId: history});
    ref.read(outfitStorageProvider).saveSession(history.present);
  }

  SelectionOutcome select(String characterId, ClothingItem item) {
    if (!item.fits(characterId)) return SelectionOutcome.incompatible;
    if (item.premium && !ref.read(isPremiumProvider)) {
      return SelectionOutcome.locked;
    }
    final history = state.history(characterId);
    _commit(characterId, history.record(_rules.select(history.present, item)));
    return SelectionOutcome.applied;
  }

  void setColor(String characterId, ClothingItem item, String variantId) {
    final history = state.history(characterId);
    _commit(characterId,
        history.record(_rules.setColor(history.present, item, variantId)));
  }

  void undo(String characterId) =>
      _commit(characterId, state.history(characterId).undo());

  void redo(String characterId) =>
      _commit(characterId, state.history(characterId).redo());

  void reset(String characterId) {
    final character = ref.read(catalogProvider).character(characterId);
    final history = state.history(characterId);
    _commit(characterId, history.record(_rules.reset(character)));
  }

  /// Puts a saved look on its character. Undo returns to the previous look.
  void load(Outfit outfit) {
    final clean = _rules.sanitize(
      outfit,
      premiumUnlocked: ref.read(isPremiumProvider),
    );
    final history = state.history(outfit.characterId);
    _commit(outfit.characterId, history.record(clean));
  }
}

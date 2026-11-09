import 'outfit.dart';

/// Undo and redo stacks around the current outfit. Immutable.
class OutfitHistory {
  OutfitHistory({
    required this.present,
    List<Outfit> past = const [],
    List<Outfit> future = const [],
  })  : past = List.unmodifiable(past),
        future = List.unmodifiable(future);

  static const maxEntries = 60;

  final Outfit present;
  final List<Outfit> past;
  final List<Outfit> future;

  bool get canUndo => past.isNotEmpty;
  bool get canRedo => future.isNotEmpty;

  /// Adds a change. Re-applying the current outfit records nothing.
  OutfitHistory record(Outfit next) {
    if (next == present) return this;
    final trimmed = [...past, present];
    if (trimmed.length > maxEntries) trimmed.removeAt(0);
    return OutfitHistory(present: next, past: trimmed);
  }

  OutfitHistory undo() {
    if (!canUndo) return this;
    return OutfitHistory(
      present: past.last,
      past: past.sublist(0, past.length - 1),
      future: [present, ...future],
    );
  }

  OutfitHistory redo() {
    if (!canRedo) return this;
    return OutfitHistory(
      present: future.first,
      past: [...past, present],
      future: future.sublist(1),
    );
  }
}

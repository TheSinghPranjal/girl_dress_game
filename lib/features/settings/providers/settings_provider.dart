import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';

const _exportBackgroundKey = 'export_background';

final exportBackgroundProvider =
    NotifierProvider<ExportBackgroundNotifier, bool>(
        ExportBackgroundNotifier.new);

class ExportBackgroundNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_exportBackgroundKey) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_exportBackgroundKey, value);
  }
}

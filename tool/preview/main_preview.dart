// Development launcher for screenshots. It is not part of the shipped app.
//
// Reads preview.json from the app documents folder:
// {"route": "/dress", "character": "lily", "outfit": "id,id"}.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:girl_dress_game/app/app.dart';
import 'package:girl_dress_game/app/bootstrap.dart';
import 'package:girl_dress_game/app/router.dart';
import 'package:girl_dress_game/core/storage/app_providers.dart';
import 'package:girl_dress_game/features/dressing_room/controllers/dressing_controller.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documents = await getApplicationDocumentsDirectory();
  final file = File('${documents.path}/preview.json');
  final env = file.existsSync()
      ? (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>).cast<String, String>()
      : <String, String>{};
  final container = ProviderContainer(overrides: [
    ...await bootstrap(),
    initialRouteProvider.overrideWithValue(env['route'] ?? Routes.splash),
  ]);
  final character = env['character'];
  if (character != null) {
    container.read(selectedCharacterIdProvider.notifier).select(character);
  }
  final id = container.read(selectedCharacterIdProvider);
  final catalog = container.read(catalogProvider);
  final controller = container.read(dressingControllerProvider.notifier);
  controller.reset(id);
  for (final itemId in (env['outfit'] ?? '').split(',')) {
    final item = catalog.item(itemId);
    if (item != null) controller.select(id, item);
  }
  runApp(UncontrolledProviderScope(
    container: container,
    child: const HelpMeDressApp(),
  ));
}

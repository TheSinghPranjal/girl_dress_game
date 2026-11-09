import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final isPhone = view.physicalSize.shortestSide / view.devicePixelRatio < 600;
  if (isPhone) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp]);
  }
  final overrides = await bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const HelpMeDressApp()));
}

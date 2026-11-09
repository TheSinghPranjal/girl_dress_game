import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class HelpMeDressApp extends ConsumerWidget {
  const HelpMeDressApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Help Me Dress',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: ref.watch(routerProvider),
      );
}

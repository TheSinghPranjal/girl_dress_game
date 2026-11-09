import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/character_selection/screens/character_selection_screen.dart';
import '../features/dressing_room/screens/dressing_room_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/saved_outfits/screens/saved_outfits_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/splash/screens/splash_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const characters = '/characters';
  static const dress = '/dress';
  static const saved = '/saved';
  static const premium = '/premium';
  static const settings = '/settings';
}

/// Tests override this to start on a specific screen.
final initialRouteProvider = Provider<String>((ref) => Routes.splash);

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.watch(initialRouteProvider),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.characters,
        builder: (_, _) => const CharacterSelectionScreen(),
      ),
      GoRoute(path: Routes.dress, builder: (_, _) => const DressingRoomScreen()),
      GoRoute(path: Routes.saved, builder: (_, _) => const SavedOutfitsScreen()),
      GoRoute(path: Routes.premium, builder: (_, _) => const PremiumScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

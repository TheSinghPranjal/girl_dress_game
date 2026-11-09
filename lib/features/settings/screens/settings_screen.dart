import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../dressing_room/controllers/dressing_controller.dart';
import '../../premium/providers/premium_provider.dart';
import '../../saved_outfits/providers/saved_outfits_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete all saved outfits?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete all')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(savedOutfitsProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved outfits deleted')),
        );
      }
    }
  }

  void _startOver(BuildContext context, WidgetRef ref) {
    final catalog = ref.read(catalogProvider);
    final controller = ref.read(dressingControllerProvider.notifier);
    for (final character in catalog.characters) {
      controller.reset(character.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Everyone is back in their starting outfit')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = ref.watch(exportBackgroundProvider);
    final premium = ref.watch(isPremiumProvider);
    return Scaffold(
      body: SketchbookBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SketchPageHeader(title: 'Settings'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(30, 4, 12, 24),
                  children: [
                    SwitchListTile(
                      key: const Key('settings_background'),
                      title: const Text('Sketchbook background on exported pictures'),
                      value: background,
                      onChanged: ref.read(exportBackgroundProvider.notifier).set,
                    ),
                    ListTile(
                      key: const Key('settings_premium'),
                      title: const Text('Premium wardrobe'),
                      subtitle: Text(premium ? 'Active' : 'Not active'),
                      trailing: const SketchIcon(SketchIcons.crown),
                      onTap: () => context.push(Routes.premium),
                    ),
                    ListTile(
                      key: const Key('settings_reset_all'),
                      title: const Text('Reset every character'),
                      subtitle: const Text('Back to the starting outfit'),
                      onTap: () => _startOver(context, ref),
                    ),
                    ListTile(
                      key: const Key('settings_clear_saved'),
                      title: const Text('Delete all saved outfits'),
                      onTap: () => _clear(context, ref),
                    ),
                    const AboutListTile(
                      applicationName: 'Help Me Dress',
                      applicationVersion: '1.0.0',
                      child: Text('About'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../../models/outfit.dart';
import '../../dressing_room/controllers/dressing_controller.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/saved_outfits_provider.dart';

class SavedOutfitsScreen extends ConsumerWidget {
  const SavedOutfitsScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, SavedOutfit saved, {required bool edit}) {
    ref.read(selectedCharacterIdProvider.notifier).select(saved.outfit.characterId);
    ref.read(dressingControllerProvider.notifier).load(saved.outfit);
    ref.read(editingOutfitProvider.notifier).set(edit ? saved : null);
    context.push(Routes.dress);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SavedOutfit saved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Delete "${saved.name}"?'),
        content: const Text('This outfit will be removed from your sketchbook.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const Key('confirm_delete'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(savedOutfitsProvider.notifier).delete(saved);
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref, SavedOutfit saved) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final service = ref.read(exportServiceProvider);
    try {
      final composed = await ref
          .read(composerProvider)
          .compose(ref.read(layerManagerProvider).resolve(saved.outfit));
      final file = await service.exportComposed(
        composed,
        withBackground: ref.read(exportBackgroundProvider),
      );
      await service.share(
        file,
        text: saved.name,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('The picture could not be shared. ($error)')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(savedOutfitsProvider);
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      body: SketchbookBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SketchPageHeader(title: 'Saved Outfits'),
              Expanded(
                child: outfits.isEmpty
                    ? const _EmptySaved()
                    : LayoutBuilder(
                        builder: (context, constraints) => GridView.builder(
                          padding: const EdgeInsets.fromLTRB(30, 6, 12, 24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .54,
                          ),
                          itemCount: outfits.length,
                          itemBuilder: (context, index) {
                            final saved = outfits[index];
                            return _SavedCard(
                              key: Key('saved_${saved.id}'),
                              saved: saved,
                              characterName: catalog.character(saved.outfit.characterId).name,
                              onOpen: () => _open(context, ref, saved, edit: false),
                              onEdit: () => _open(context, ref, saved, edit: true),
                              onDelete: () => _delete(context, ref, saved),
                              onShare: () => _share(context, ref, saved),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(44, 0, 28, 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeartBeat(size: 44),
              SizedBox(height: 12),
              Text(
                'Your saved looks will appear here.\nDress someone up and tap Save!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.hand,
                  fontSize: 18,
                  color: AppColors.brownInk,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    super.key,
    required this.saved,
    required this.characterName,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  final SavedOutfit saved;
  final String characterName;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final path = saved.thumbnailPath;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brownInk.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              key: Key('open_${saved.id}'),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: path == null
                    ? const MissingArt()
                    : Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const MissingArt(),
                      ),
              ),
            ),
          ),
          Text(
            saved.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.hand,
              fontSize: 17,
              color: AppColors.charcoal,
            ),
          ),
          Text(
            characterName,
            style: const TextStyle(
              fontFamily: AppFonts.label,
              fontSize: 14,
              color: AppColors.brownInk,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(SketchIcons.edit, 'Edit', onEdit, Key('edit_${saved.id}')),
              _action(SketchIcons.share, 'Share', onShare, Key('share_${saved.id}')),
              _action(SketchIcons.trash, 'Delete', onDelete, Key('delete_${saved.id}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String icon, String tooltip, VoidCallback onTap, Key key) => IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onTap,
        icon: SketchIcon(icon, size: 22),
      );
}

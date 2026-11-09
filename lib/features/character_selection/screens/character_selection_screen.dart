import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../widgets/character_portrait.dart';

class CharacterSelectionScreen extends ConsumerWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final selected = ref.watch(selectedCharacterProvider);
    return Scaffold(
      body: SketchbookBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SketchPageHeader(title: 'Choose Your Girl'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Image.asset(
                      selected.previewPath,
                      key: ValueKey(selected.id),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Text(
                selected.name,
                style: const TextStyle(
                  fontFamily: AppFonts.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 42,
                  height: 1.05,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                selected.tagline,
                style: const TextStyle(
                  fontFamily: AppFonts.hand,
                  fontSize: 15,
                  color: AppColors.brownInk,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 12, 0),
                child: FittedBox(
                  child: Row(
                    children: [
                      for (final character in catalog.characters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: CharacterPortrait(
                            key: Key('pick_${character.id}'),
                            character: character,
                            selected: character.id == selected.id,
                            onTap: () => ref
                                .read(selectedCharacterIdProvider.notifier)
                                .select(character.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(44, 0, 28, 18),
                child: PillSketchButton(
                  key: const Key('start_dressing'),
                  label: 'Dress ${selected.name}',
                  pink: true,
                  expand: true,
                  onPressed: () => context.pushReplacement(Routes.dress),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../../services/purchase/purchase_gateway.dart';
import '../providers/premium_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String? _chosenId;

  static const _benefits = [
    'Every crowned top, dress, jacket and shoe',
    'Exclusive bags, jewellery and hairstyles',
    'New looks whenever the wardrobe grows',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);
    final catalog = ref.watch(catalogProvider);
    final characterId = ref.watch(selectedCharacterIdProvider);
    final preview = catalog.items.where((i) => i.premium).take(8).toList();
    final chosen = state.products.where((p) => p.id == _chosenId).firstOrNull ??
        state.products.firstOrNull;
    final busy = state.phase == PremiumPhase.purchasing;
    return Scaffold(
      body: SketchbookBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SketchPageHeader(title: 'Premium Wardrobe'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(34, 6, 18, 24),
                  children: [
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: preview.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) => Container(
                          width: 90,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.brownInk.withValues(alpha: .3),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SketchImage(
                                  preview[index].resolvedThumbnail(characterId, null),
                                  cacheWidth: 240,
                                ),
                              ),
                              const Positioned(
                                right: 0,
                                top: 0,
                                child: PremiumCrown(size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final benefit in _benefits)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const SketchIcon(SketchIcons.heart, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                benefit,
                                style: const TextStyle(
                                  fontFamily: AppFonts.hand,
                                  fontSize: 17,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (state.unlocked)
                      const _Note('Your premium wardrobe is active.')
                    else if (state.phase == PremiumPhase.loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      for (final product in state.products)
                        _PlanTile(
                          key: Key('plan_${product.id}'),
                          product: product,
                          selected: product.id == chosen?.id,
                          onTap: () => setState(() => _chosenId = product.id),
                        ),
                    if (state.message != null) _Note(state.message!),
                    const SizedBox(height: 14),
                    if (!state.unlocked)
                      PillSketchButton(
                        key: const Key('premium_buy'),
                        label: busy ? 'Please wait…' : 'Purchase',
                        pink: true,
                        expand: true,
                        onPressed: chosen == null || busy ? null : () => notifier.buy(chosen),
                      ),
                    const SizedBox(height: 10),
                    PillSketchButton(
                      key: const Key('premium_restore'),
                      label: 'Restore purchases',
                      expand: true,
                      onPressed: busy ? null : notifier.restore,
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

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          key: const Key('premium_message'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.brownInk),
        ),
      );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final StoreProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: selected ? AppColors.softPink : AppColors.ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AppColors.rosePink : AppColors.brownInk.withValues(alpha: .35),
              width: selected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: onTap,
            title: Text(product.title),
            trailing: Text(
              product.price,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
}

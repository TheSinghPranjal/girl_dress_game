import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/app_providers.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../../models/clothing_item.dart';
import '../../dressing_room/controllers/dressing_controller.dart';
import '../../premium/providers/premium_provider.dart';

/// The paper wardrobe sheet: drag handle, categories, colours and item grid.
class WardrobePanel extends StatefulWidget {
  const WardrobePanel({
    super.key,
    this.collapsedHeight = 0,
    this.expandedHeight = 0,
    this.sideBySide = false,
  });

  final double collapsedHeight;
  final double expandedHeight;
  final bool sideBySide;

  @override
  State<WardrobePanel> createState() => _WardrobePanelState();
}

class _WardrobePanelState extends State<WardrobePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheet;

  @override
  void initState() {
    super.initState();
    _sheet = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  double get _range =>
      (widget.expandedHeight - widget.collapsedHeight).clamp(1.0, double.infinity);

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _toggle() => _sheet.value > .5 ? _sheet.reverse() : _sheet.forward();

  void _drag(DragUpdateDetails details) =>
      _sheet.value -= details.primaryDelta! / _range;

  void _settle(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      _sheet.forward();
    } else if (velocity > 200) {
      _sheet.reverse();
    } else {
      _sheet.value > .5 ? _sheet.forward() : _sheet.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF1E7),
        borderRadius: widget.sideBySide
            ? const BorderRadius.only(topLeft: Radius.circular(34))
            : const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border.all(color: AppColors.brownInk.withValues(alpha: .55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownInk.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!widget.sideBySide)
            Semantics(
              button: true,
              label: 'Expand or collapse wardrobe',
              child: GestureDetector(
                key: const Key('wardrobe_handle'),
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                onVerticalDragUpdate: _drag,
                onVerticalDragEnd: _settle,
                child: SizedBox(
                  height: 22,
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.brownInk.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),
          const _CategoryBar(),
          Divider(
            height: 10,
            indent: 14,
            endIndent: 14,
            color: AppColors.brownInk.withValues(alpha: .18),
          ),
          const _ColorStrip(),
          const Expanded(child: _ItemGrid()),
        ],
      ),
    );
    if (widget.sideBySide) return body;
    return AnimatedBuilder(
      animation: _sheet,
      builder: (_, child) => SizedBox(
        height: widget.collapsedHeight + _range * _sheet.value,
        child: child,
      ),
      child: body,
    );
  }
}

class _CategoryBar extends ConsumerWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        const categories = WardrobeCategory.values;
        final extent = (constraints.maxWidth - 12) / categories.length;
        final tile = extent.clamp(48.0, 110.0);
        return SizedBox(
          height: 78,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemExtent: tile,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                key: Key('category_${category.name}'),
                category: category,
                selected: category == selected,
                onTap: () =>
                    ref.read(selectedCategoryProvider.notifier).select(category),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final WardrobeCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: category.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.softPink : AppColors.cream.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: SvgPicture.asset(category.iconPath)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.label,
                    style: const TextStyle(
                      fontFamily: AppFonts.label,
                      fontSize: 15,
                      height: 1.1,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Colour picker for the item being worn in the open category.
class _ColorStrip extends ConsumerWidget {
  const _ColorStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final category = ref.watch(selectedCategoryProvider);
    final outfit = ref.watch(currentOutfitProvider);
    final items = catalog.items.where((item) =>
        item.category == category && item.hasColorChoice && outfit.wornIds.contains(item.id));
    final item = items.isEmpty ? null : items.last;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: item == null
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Center(
                    child: Text(
                      'Colour',
                      style: TextStyle(
                        fontFamily: AppFonts.label,
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  for (final variant in item.colorVariants)
                    _Swatch(
                      key: Key('swatch_${variant.id}'),
                      variant: variant,
                      selected: item.variantById(outfit.colorVariants[item.id])?.id == variant.id,
                      onTap: () => ref.read(dressingControllerProvider.notifier).setColor(
                            outfit.characterId,
                            item,
                            variant.id,
                          ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ColorVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: variant.name,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selected ? 32 : 28,
                height: selected ? 32 : 28,
                decoration: BoxDecoration(
                  color: Color(variant.swatch),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.rosePink
                        : AppColors.brownInk.withValues(alpha: .5),
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ItemGrid extends ConsumerWidget {
  const _ItemGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);
    final items = ref.watch(categoryItemsProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: LayoutBuilder(
        key: ValueKey(category),
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 360 ? 5 : 4;
          return GridView.builder(
            key: PageStorageKey('grid_${category.name}'),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: .92,
            ),
            itemCount: items.length,
            itemBuilder: (_, index) => _ItemCard(
              key: Key('item_${items[index].id}'),
              item: items[index],
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({super.key, required this.item});

  final ClothingItem item;

  void _tap(BuildContext context, WidgetRef ref) {
    final outcome = ref
        .read(dressingControllerProvider.notifier)
        .select(ref.read(selectedCharacterIdProvider), item);
    if (outcome == SelectionOutcome.locked) context.push(Routes.premium);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      currentOutfitProvider.select((o) => o.wornIds.contains(item.id)),
    );
    final thumbnail = ref.watch(currentOutfitProvider.select(
      (o) => item.resolvedThumbnail(o.characterId, o.colorVariants[item.id]),
    ));
    final locked = item.premium && !ref.watch(isPremiumProvider);
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '${item.name}, premium, locked' : item.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(context, ref),
        child: AnimatedScale(
          scale: selected ? 1.03 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.rosePink
                    : AppColors.brownInk.withValues(alpha: .28),
                width: selected ? 2.4 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: SketchImage(thumbnail, cacheWidth: 240),
                  ),
                ),
                if (locked)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0C9),
                        shape: BoxShape.circle,
                      ),
                      child: const PremiumCrown(size: 16),
                    ),
                  ),
                if (selected)
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: SketchIcon(SketchIcons.check, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

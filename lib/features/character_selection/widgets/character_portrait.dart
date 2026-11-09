import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/sketch_widgets.dart';
import '../../../models/character.dart';

/// Round portrait with a paper name tag and pink selected ring.
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    super.key,
    required this.character,
    required this.selected,
    required this.onTap,
    this.size = 66,
  });

  final Character character;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tagHeight = size * .34;
    return Semantics(
      button: true,
      selected: selected,
      label: character.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size + 10,
          height: size + tagHeight * .6,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: size + 6,
                height: size + 6,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ivory,
                  border: Border.all(
                    color: selected ? AppColors.rosePink : Colors.transparent,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: const Color(0xFFF9E3D6),
                    child: SketchImage(
                      character.portraitPath,
                      fit: BoxFit.cover,
                      cacheWidth: 220,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: tagHeight,
                  constraints: BoxConstraints(minWidth: size * .72),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.brownInk.withValues(alpha: .55),
                    ),
                  ),
                  child: FittedBox(
                    child: Text(
                      character.name,
                      style: const TextStyle(
                        fontFamily: AppFonts.label,
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../constants/app_colors.dart';

abstract final class SketchIcons {
  static const back = 'assets/icons/back.svg';
  static const undo = 'assets/icons/undo.svg';
  static const redo = 'assets/icons/redo.svg';
  static const save = 'assets/icons/save.svg';
  static const reset = 'assets/icons/reset.svg';
  static const zoomIn = 'assets/icons/zoom_in.svg';
  static const zoomOut = 'assets/icons/zoom_out.svg';
  static const share = 'assets/icons/share.svg';
  static const trash = 'assets/icons/trash.svg';
  static const edit = 'assets/icons/edit.svg';
  static const crown = 'assets/icons/crown.svg';
  static const check = 'assets/icons/check.svg';
  static const heart = 'assets/icons/heart.svg';
}

class SketchIcon extends StatelessWidget {
  const SketchIcon(this.asset, {super.key, this.size = 24});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, width: size, height: size);
}

/// The ruled sketchbook page behind every screen.
class SketchbookBackground extends StatelessWidget {
  const SketchbookBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/backgrounds/sketchbook.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            gaplessPlayback: true,
          ),
          child,
        ],
      );
}

class RoundSketchButton extends StatelessWidget {
  const RoundSketchButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.pink = false,
    this.size = 52,
  });

  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool pink;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .42,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: pink ? AppColors.softPink : AppColors.ivory,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.brownInk, width: 1.4),
          ),
          elevation: 1.5,
          shadowColor: AppColors.brownInk.withValues(alpha: .4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: SketchIcon(icon, size: size * .52)),
            ),
          ),
        ),
      ),
    );
  }
}

class PillSketchButton extends StatelessWidget {
  const PillSketchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.pink = false,
    this.expand = false,
  });

  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final bool pink;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[SketchIcon(icon!, size: 22), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.hand,
              fontSize: 17,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: Material(
        color: pink ? AppColors.softPink : AppColors.ivory,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.brownInk, width: 1.3),
        ),
        elevation: 1.5,
        shadowColor: AppColors.brownInk.withValues(alpha: .4),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Handwritten logo on its torn-paper banner.
class LogoBanner extends StatelessWidget {
  const LogoBanner({super.key, this.height = 62, this.title = 'Help Me Dress'});

  final double height;
  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/decorations/banner.webp',
                fit: BoxFit.fill, width: double.infinity),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: height * .4),
              child: FittedBox(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.title,
                        fontWeight: FontWeight.w700,
                        fontSize: 44,
                        height: 1,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const HeartBeat(size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class HeartBeat extends StatefulWidget {
  const HeartBeat({super.key, this.size = 18});

  final double size;

  @override
  State<HeartBeat> createState() => _HeartBeatState();
}

class _HeartBeatState extends State<HeartBeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween<double>(begin: .86, end: 1.14).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: SketchIcon(SketchIcons.heart, size: widget.size),
      );
}

class PremiumCrown extends StatefulWidget {
  const PremiumCrown({super.key, this.size = 20});

  final double size;

  @override
  State<PremiumCrown> createState() => _PremiumCrownState();
}

class _PremiumCrownState extends State<PremiumCrown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: Tween<double>(begin: -.018, end: .018).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: SketchIcon(SketchIcons.crown, size: widget.size),
      );
}

class SketchPageHeader extends StatelessWidget {
  const SketchPageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(26, 8, 14, 8),
        child: Row(
          children: [
            RoundSketchButton(
              key: const Key('page_back'),
              icon: SketchIcons.back,
              tooltip: 'Back',
              pink: true,
              size: 48,
              onPressed: () => popOrHome(context),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.title,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ),
            SizedBox(width: 48, child: trailing),
          ],
        ),
      );
}

void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.home);
  }
}

class SketchImage extends StatelessWidget {
  const SketchImage(this.asset, {super.key, this.fit = BoxFit.contain, this.cacheWidth});

  final String asset;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const MissingArt(),
      );
}

/// Clear stand-in, so missing art is never silently swapped for something else.
class MissingArt extends StatelessWidget {
  const MissingArt({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.rosePink),
        ),
        alignment: Alignment.center,
        child: const FittedBox(
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text('Missing\nart', textAlign: TextAlign.center),
          ),
        ),
      );
}

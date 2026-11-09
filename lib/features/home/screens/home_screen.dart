import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/full_bleed_art.dart';
import '../widgets/art_hotspot.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Button positions in the supplied painting. The art starts 185px down.
  static const _imageSize = Size(942, 2040);
  static const _artTop = 185.0;
  static const _play = Rect.fromLTWH(226, 1128 + _artTop, 494, 168);
  static const _characters = Rect.fromLTWH(92, 1344 + _artTop, 228, 172);
  static const _saved = Rect.fromLTWH(367, 1344 + _artTop, 230, 172);
  static const _settings = Rect.fromLTWH(644, 1344 + _artTop, 230, 172);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FullBleedArt(
          asset: 'assets/screens/home.webp',
          imageSize: _imageSize,
          artTop: _artTop,
          artHeight: 1670,
          overlays: (map) => [
            ArtHotspot(
              key: const Key('home_play'),
              rect: map(_play),
              label: 'Play',
              radius: 80,
              onTap: () => context.push(Routes.dress),
            ),
            ArtHotspot(
              key: const Key('home_characters'),
              rect: map(_characters),
              label: 'Characters',
              onTap: () => context.push(Routes.characters),
            ),
            ArtHotspot(
              key: const Key('home_saved'),
              rect: map(_saved),
              label: 'Saved Outfits',
              onTap: () => context.push(Routes.saved),
            ),
            ArtHotspot(
              key: const Key('home_settings'),
              rect: map(_settings),
              label: 'Settings',
              onTap: () => context.push(Routes.settings),
            ),
          ],
        ),
      );
}

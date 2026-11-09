# Help Me Dress

A 2D fashion dress-up game for iOS and Android, built with Flutter.

## Run

    flutter pub get
    flutter run

## Check

    flutter analyze
    flutter test
    flutter test integration_test -d <simulator id>
    python3 tool/validate_assets.py

## Before release

- Create the subscriptions `help_me_dress_premium_monthly` and `help_me_dress_premium_yearly`
  in App Store Connect and Google Play Console.
- Purchases are confirmed on the device. Add server receipt validation to detect
  refunds and expired subscriptions.
- Set up Android release signing. The current release build uses debug keys.
- Replace the default app icon.

See `docs/ART_REQUIREMENTS.md` for replacing illustrations. Everything is 2D and layered,
and wardrobe content lives in `assets/data/catalog.json`.

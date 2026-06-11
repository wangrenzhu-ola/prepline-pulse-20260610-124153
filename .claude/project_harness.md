# Project Harness

tech_stack: flutter

## Required Commands

- `flutter pub get`
- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `flutter build ios --simulator`

## Layout Guardrails

- Keep the product surface between 10 and 13 navigable pages.
- Keep mobile bottom navigation in `Scaffold.bottomNavigationBar`.
- Keep major pages scannable: one primary action, one readback, one status summary.
- At least three pages must show a large operational image.
- Do not let product cards, protocol pages, or bottom navigation overflow on 320px wide screens.

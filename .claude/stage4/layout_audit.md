# Stage 4 Layout Audit

## Scope

- Simplify visible navigation to 4 primary tabs while retaining the 10-page route contract.
- Confirm at least three large image pages: Board, Batch, Timeline.
- Confirm all 25 Store product cards and protocol WebView entry surfaces fit small screens.

## Findings

- passed: Core bottom navigation now has 4 tabs: Board, Batch, Photos, Store; 10 route contracts remain in `pageContracts`.
- passed: Board, Batch, and Photos all render large user-photo surfaces; upload uses relative-path app storage and the primary image exposes system album export.
- passed: Store renders all 25 product cards with a responsive single-column mobile grid and three-column wide layout.
- passed: Store and Settings expose in-app User Agreement and Privacy Policy WebView entries.
- passed: Board station cards no longer overflow on the iOS simulator viewport, and the save action now states what is recorded.
- evidence: `flutter analyze`; `flutter test`; `flutter build ios --simulator`; `/private/tmp/prepline-board-save-records.png`.

## Test Images Generated

| File | Scene Description | Intended Page | Visual Risk |
|------|-------------------|---------------|-------------|
| `assets/images/kitchen_prep_01.jpg` | European woman chef chopping vegetables at a professional prep counter with mise en place containers and steam rising | Line Board (hero / proof photo placeholder) | Assumes kitchen prep context; no actual app UI visible |
| `assets/images/fresh_ingredients_01.jpg` | Woman organizing fresh produce in labeled batch containers on a stainless steel counter | Batch Detail (ingredient / batch visual context) | Generic prep scene; may need crop for card aspect ratios |
| `assets/images/finished_dish_01.jpg` | Chef carefully plating an elegant finished dish with microgreens garnish | Photos (completed proof / plating showcase) | Fine-dining aesthetic may not match all restaurant tiers |
| `assets/images/kitchen_station_01.jpg` | Sous chef at a busy station with multiple pans, team working in background | Store / Settings (professional kitchen ambiance) | Background figures are not the focus; acceptable for ambient use |

**Generation Constraints Verified:**
- All images feature European/American women in kitchen-related scenarios.
- No mobile phones, tablets, or electronic devices visible.
- No text or watermarks.
- Portrait orientation, suitable for mobile hero images.
- High quality (8K photorealistic prompt).

**Assets Registered:** All 4 images added to `pubspec.yaml` under `flutter.assets`.

verification_skill_names: autobuya-ios-compliance, setup-iap

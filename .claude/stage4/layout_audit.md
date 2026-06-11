# Stage 4 Layout Audit

## Scope

- Simplify visible navigation to 4 primary tabs while retaining the 10-page route contract.
- Confirm at least three large image pages: Board, Batch, Timeline.
- Confirm all 27 Store product cards and protocol WebView entry surfaces fit small screens.

## Findings

- passed: Core bottom navigation now has 4 tabs: Board, Batch, Photos, Store; 10 route contracts remain in `pageContracts`.
- passed: Board, Batch, and Photos all render large user-photo surfaces; upload uses relative-path app storage and the primary image exposes system album export.
- passed: Store renders all 27 product cards with a responsive single-column mobile grid and three-column wide layout.
- passed: Store and Settings expose in-app User Agreement and Privacy Policy WebView entries.
- passed: Board station cards no longer overflow on the iOS simulator viewport, and the save action now states what is recorded.
- evidence: `flutter analyze`; `flutter test`; `flutter build ios --simulator`; `/private/tmp/prepline-board-save-records.png`.

verification_skill_names: autobuya-ios-compliance, setup-iap

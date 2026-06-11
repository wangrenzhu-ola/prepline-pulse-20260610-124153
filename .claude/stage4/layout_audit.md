# Stage 4 Layout Audit

## Scope

- Simplify pages to a 10-page core navigation model.
- Confirm at least three large image pages: Board, Batch, Timeline.
- Confirm Store product cards and protocol WebView surfaces fit small screens.

## Findings

- passed: Core navigation now has 10 pages: Board, Batch, Entry, Clock, Timeline, Exceptions, Rules, Store, Settings, About.
- passed: Board, Batch, and Timeline all render large image surfaces; media panels support user upload, relative-path app storage, and system album export.
- passed: Store product cards use a responsive single-column mobile grid and three-column wide layout.
- passed: Settings exposes in-app User Agreement and Privacy Policy WebView entries.
- evidence: `flutter analyze`; `flutter test`; `flutter build ios --simulator`.

verification_skill_names: autobuya-ios-compliance, setup-iap

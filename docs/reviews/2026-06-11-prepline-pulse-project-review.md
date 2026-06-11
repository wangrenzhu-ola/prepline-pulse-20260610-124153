# PrepLine Pulse Project Review Findings

Date: 2026-06-11

Scope: project-wide review of feature completeness, data flow, state management,
media loading/display, UI/UX completeness, and page background treatment.

## Summary

PrepLine Pulse has a broad set of Flutter screens and several useful interaction
prototypes, but it is not yet ready to treat as a complete product flow. The
largest risk is not an isolated UI defect; it is that the app currently has
multiple state sources and several pages read static or page-local data. As a
result, user actions can appear to save or resolve work in one page while other
pages continue to show stale or unrelated data.

The media assets are present and declared in `pubspec.yaml`, but image handling
is inconsistent. Some surfaces render images with `Image.asset`, while the shared
preview component attempts to read the same image paths as text. The current
visual assets are also abstract pixel/gradient images rather than recognizable
prep-line or batch photos, so the page background and hero treatment still feel
unfinished.

## Follow-up Documentation and Skill Originals

The two user-requested skills were added to this PR as complete original files,
copied byte-for-byte from the local Codex skill sources:

- `docs/skills/original/autobuya-ios-compliance/SKILL.md`
  - Source: `/Users/zhoujinyu/.codex/skills/autobuya-ios-compliance/SKILL.md`
  - SHA-256: `a3c098bee4e67fae46192083ddefe8472afc9f6f62c68ed9814cedb4ed32fc9a`
- `docs/skills/original/setup-iap/SKILL.md`
  - Source: `/Users/zhoujinyu/.codex/skills/setup-iap/SKILL.md`
  - SHA-256: `54723eccdf22e8a568205bb6b8aee6ae8cbd6b3144bd1ab7f8656735c9e53ebf`

### Documentation Change Round 1

The first documentation update recorded the app simplification and Stage 3
iOS/IAP implementation work:

- Simplified the product surface to 10 core pages with less dense page content.
- Recorded three large-image pages: Line Board, Batch Detail, and Station
  Timeline.
- Recorded user image upload, relative-path media persistence, image preview,
  and save-to-album support.
- Recorded `autobuya-ios-compliance` work in
  `.claude/stage3/compliance_tracker.md`, `.claude/test_matrix.md`, and
  `.claude/event_log.ndjson`.
- Recorded `setup-iap` work in `.claude/stage3/iap_tracker.md`,
  `.claude/stage3/iap_closeout_review.md`,
  `.claude/feature_coverage_matrix.md`, `.claude/test_matrix.md`, and
  `.claude/event_log.ndjson`.

### Documentation Change Round 2

The second documentation update recorded the runtime-open fixes found while
running the app on the iOS simulator:

- `SceneDelegate` now owns Flutter plugin registration for the scene-created
  `FlutterViewController`.
- ATT authorization now runs through a native SceneDelegate `MethodChannel`
  after the first Flutter frame.
- `app_tracking_transparency` was removed because simulator crash reports showed
  Swift plugin registration crashing before the app reached a stable first
  frame under the current SceneDelegate lifecycle.
- `Main.storyboard`, `Assets.xcassets`, and `LaunchScreen.storyboard` were
  restored to the Runner resources phase so `Runner.app` contains `Assets.car`,
  app icons, and compiled storyboards.
- Runtime evidence was written back to `.claude/stage3/compliance_tracker.md`,
  `.claude/test_matrix.md`, and `.claude/event_log.ndjson`.

This is an explicit runtime adaptation from the archived
`autobuya-ios-compliance` original text: the original skill describes an ATT
implementation before `runApp`, but the observed simulator crash path required
rendering Flutter first and requesting ATT through the scene-owned native channel.

### Documentation Change Round 3

The third documentation update records the post-screenshot simplification pass.
The provided simulator screenshot paths were no longer readable from their
temporary `/var/folders/.../T/` locations, so the analysis used current source
inspection plus a fresh iOS simulator screenshot.

Root causes found:

- The Store page did not own a settings action; the shared `PrepScaffold`
  injected a settings icon into every page using that scaffold.
- The app still exposed too many peer-level destinations through navigation,
  drawer, and More surfaces, so auxiliary pages competed with the core workflow.
- Built-in `assets/images` PNGs were displayed as large hero/media images,
  which made it unclear whether the user was seeing uploaded album media or
  placeholder art.
- Save-to-album lived in a secondary media panel instead of on the primary proof
  image, so the photo workflow did not feel like the product's main action.

Fixes recorded in this round:

- Primary navigation is now Board, Batch, Photos, and Store.
- The Store page no longer shows a settings icon.
- Board, Batch, and Photos each use the same `PrimaryProofHero`; it shows an
  upload empty state until the user uploads an album photo.
- Uploading a proof photo promotes that user image to all three large-image
  pages.
- Built-in `assets/images` files are no longer rendered as UI photos.
- Save-to-album is attached directly to the large user proof image.

## High Priority Issues

### 1. Split Global State

The app installs both `PrepBoardScope` and legacy `PrepLineScope` in
`lib/screens/app_shell.dart`. Different screens then read from different
controllers:

- `LineBoardScreen`, `StateEntryScreen`, `ExceptionQueueScreen`,
  `PrepRulesScreen`, `SettingsScreen`, and `StateEntryDetailScreen` use
  `PrepBoardController`.
- `BatchDetailScreen`, `StationTimelineScreen`, `LineBoardDetailScreen`, and
  `BatchDetailDetailScreen` use legacy `PrepLineController`.
- `ServiceClockScreen` owns its own static batch list.
- `AboutScreen` reads static seed data directly.

This means the app does not have a single global management layer for batches,
logs, exceptions, media, rules, settings, and readbacks. A save or resolve action
in one part of the app will not reliably update the rest of the product.

Recommended fix: consolidate app state into one store/controller and route all
screens through that single source of truth. Remove the legacy controller after
the screens have been migrated.

### 2. State Entry Save Drops User Inputs

`StateEntryScreen` lets the user choose a station and edit a note, but saving
only passes `nextState` to `PrepBoardController.saveState`. The controller then
hardcodes the saved note as `Saved from Line Board primary update.` and never
persists the selected station or typed note.

This produces a misleading readback: the UI can display the locally selected
station and note even though the underlying model did not save them.

Recommended fix: update the save API to accept and persist station, state, note,
owner, and any other meaningful state-entry fields. Build confirmation/readback
text from the persisted model, not from local widget variables.

### 3. Media Preview Reads PNG Files as Text

`assets/images/prepline_hero.png` and `assets/images/prepline_batch.png` are
valid PNG files and are declared in `pubspec.yaml`. However,
`PrepMediaPreview` calls `rootBundle.loadString(record.assetPath)`. This is only
appropriate for text assets such as `assets/prep_sample.txt`, not PNG images.

Other parts of the app use `Image.asset`, so the same media record can succeed
in one component and fail in another.

Recommended fix: add a media type or infer display mode safely, then use
`Image.asset`/`rootBundle.load` for images and `rootBundle.loadString` only for
text attachments.

### 4. Mobile Navigation Is Incomplete

The mobile bottom navigation exposes five destinations and labels the fifth as
`More`, but selecting it only switches to the station timeline screen. Although
the shell defines a drawer, the visible shell does not provide a reliable way to
open it from the nested page scaffolds.

Recommended fix: make all primary and system pages reachable from mobile. Use a
real more menu, a drawer entry point, or a dedicated overflow destination that
lists Timeline, Exceptions, Rules, Settings, Onboarding, and About.

## Medium Priority Issues

### 5. Static and Page-Local Data Bypass App State

Several screens simulate product behavior with page-local state instead of using
the shared app model:

- `ServiceClockScreen` uses a private const `_batches`.
- `AboutScreen` reads `seedBatches` and `seedExceptions`.
- `SettingsScreen` keeps settings and revisions in local widget state.
- `PrepRulesScreen` keeps editable rule state locally.

Recommended fix: store these concepts in the same global state layer used by the
line board and state entry flows. If persistence is not in scope yet, still keep
one in-memory source of truth for the running app session.

### 6. Background and Hero Treatment Is Not Product-Ready

The common `OperationalPage` uses a plain scaffold background and card stack.
`PrepScaffold` has an abstract gradient hero by default, and only some pages pass
an image asset. The two provided PNGs are abstract pixel/gradient textures rather
than recognizable prep-line, station, or batch imagery.

Recommended fix: add real domain-specific visual assets for the primary screens,
especially the line board, batch detail, station timeline, and onboarding flow.
Background treatment should support the operational workflow without becoming a
decorative-only dark card stack.

### 7. Dark Theme Contrast Risks

The app uses a dark theme globally, but `ServiceClockScreen` contains local
light-colored panels and chips. Some text inside those light surfaces can inherit
dark-theme text colors, which risks low contrast.

Recommended fix: avoid hardcoded light panels inside the dark theme, or set
explicit text/icon colors for every light surface.

## Verification Notes

Checks attempted:

- Source review across `lib/screens`, `lib/state`, `lib/data`, `lib/widgets`,
  `lib/theme`, `pubspec.yaml`, and `test/widget_test.dart`.
- Asset file check confirmed:
  - `assets/images/prepline_hero.png`: PNG image, 900 x 620.
  - `assets/images/prepline_batch.png`: PNG image, 900 x 520.
  - `assets/prep_sample.txt`: ASCII text.
- `flutter analyze` attempted.
- `flutter test` attempted.

Validation blocker:

The local Flutter SDK is `Flutter 3.24.5` with `Dart 3.5.4`, while the project
requires `sdk: ^3.11.5`. Both `flutter analyze` and `flutter test` stop at
dependency resolution:

```text
Because app_20260610_124153 requires SDK version ^3.11.5, version solving failed.
```

Before accepting the app as complete, rerun analyze, tests, and an iOS simulator
build with a Flutter SDK that includes Dart 3.11.5 or newer.

## Recommended Fix Order

1. Consolidate the two controllers and static screen data into one app-wide
   state source.
2. Fix `StateEntryScreen` and `PrepBoardController.saveState` so all user inputs
   are persisted and readbacks come from saved data.
3. Replace PNG-as-text media loading with a typed media rendering path.
4. Make all primary and system pages reachable from mobile navigation.
5. Replace abstract placeholder imagery with domain-specific prep-line visuals
   and improve page background treatment.
6. Normalize theme usage and check contrast on all light/dark mixed surfaces.
7. Re-run `flutter analyze`, `flutter test`, and a simulator build under a
   compatible Flutter/Dart SDK.

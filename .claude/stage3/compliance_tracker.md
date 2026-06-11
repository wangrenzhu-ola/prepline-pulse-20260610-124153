# Stage 3A Compliance Tracker

skill_name: autobuya-ios-compliance
phase: completed

## Planning

Scope: Implement ATT, iOS permission keys/macros, in-app protocol WebView, relative-path media storage, and small-screen protocol safety.

Files: `lib/main.dart`, `pubspec.yaml`, `ios/Runner/Info.plist`, `ios/Podfile`, `lib/services/prepline_permission_service.dart`, `lib/services/prepline_document_media_store.dart`, `lib/screens/protocol_screen.dart`, `lib/screens/settings_screen.dart`, `.claude/test_matrix.md`, `.claude/event_log.ndjson`.

Order: add dependencies; implement ATT before runApp; configure Info.plist and Podfile; add permission service; add relative path media store; add protocol WebView entries; verify with analyze, tests, iOS simulator build.

Verification: `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build ios --simulator`.

Risks: Permission copy must match prep-line media capture/import/export usage; iOS sandbox paths must not persist absolute paths; protocol WebView must retry instead of white-screening; small screens must avoid protocol layout overflow.

## Next Actions

- Implement compliance surfaces and tests.
- Re-read tracker, test matrix, and event log before closeout.

## Compliance Contract Checklist

| Item | Status | Evidence |
| --- | --- | --- |
| att_requested_at_app_start | passed | `lib/main.dart`; `flutter analyze` |
| att_prefixed_storage_key | passed | `lib/main.dart` uses `prepLinePulseAttRequested` |
| tracking_usage_description_localized | passed | `ios/Runner/Info.plist` |
| permission_keys_complete | passed | `ios/Runner/Info.plist`; `flutter build ios --simulator` |
| permission_copy_matches_real_usage | passed | `ios/Runner/Info.plist`; media upload/export UI |
| podfile_macros_configured | passed | `ios/Podfile`; `flutter build ios --simulator` |
| relative_path_storage_only | passed | `lib/services/prepline_document_media_store.dart`; `flutter test` |
| runtime_path_rebuild_correct | passed | `lib/services/prepline_document_media_store.dart`; `lib/widgets/media_widgets.dart` |
| image_refill_uses_rebuilt_full_path | passed | `lib/widgets/prep_widgets.dart`; `lib/widgets/media_widgets.dart` |
| privacy_policy_entry_present | passed | `lib/screens/settings_screen.dart`; `lib/screens/protocol_screen.dart` |
| user_agreement_entry_present | passed | `lib/screens/settings_screen.dart`; `lib/screens/protocol_screen.dart` |
| protocol_webview_accessible | passed | `lib/screens/protocol_screen.dart`; `flutter build ios --simulator` |
| small_screen_protocol_layout_safe | passed | `lib/screens/protocol_screen.dart`; `flutter analyze` |

## Compliance Contract Evidence Map

- att_requested_at_app_start: `main()` awaits `prepLinePulseResolveTrackingAuthorization()` before `runApp()`.
- permission_keys_complete: Info.plist contains ATT, camera, microphone, photo read, and photo add descriptions.
- relative_path_storage_only: uploaded images are copied to app documents and stored as `station_images/<file>`.
- runtime_path_rebuild_correct: previews and album export call `rebuildFile(relativePath)` before file access.
- protocol_webview_accessible: Settings opens User Agreement and Privacy Policy via in-app WebView with retry.
- verification: `flutter analyze`; `flutter test`; `flutter build ios --simulator`.

## Blockers

- none

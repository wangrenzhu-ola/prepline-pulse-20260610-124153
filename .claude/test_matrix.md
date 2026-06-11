# Test Matrix

## Functional Tests

| Area | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| state_sync | Save station state and read it back globally | passed | `flutter test` |
| ios_att | ATT request runs after first frame through the SceneDelegate native channel with prefixed key | passed | `lib/main.dart`; `ios/Runner/SceneDelegate.swift`; `simctl launch` |
| ios_permissions | Camera, microphone, photos, ATT keys and macros exist | passed | `ios/Runner/Info.plist`; `ios/Podfile`; `flutter build ios --simulator` |
| ios_resources | App icons, LaunchScreen, and Main storyboard are packaged into Runner.app | passed | `ios/Runner.xcodeproj/project.pbxproj`; `build/ios/iphonesimulator/Runner.app/Assets.car`; `flutter test` |
| relative_paths | Media storage stores relative paths and rebuilds full path | passed | `lib/services/prepline_document_media_store.dart`; `flutter test` |
| iap_init | IAP lazy initialization does not run on startup | passed | `lib/state/prep_board_controller.dart`; `flutter test` |
| iap_purchase | Purchase success credits balance once per delivery key | passed | `test/widget_test.dart`; `flutter test` |
| spend_point | Save state spends exactly 10 units | passed | `lib/state/prep_board_controller.dart`; `lib/screens/state_entry_screen.dart` |
| media_asset_visibility | Built-in `assets/images` are not rendered as UI photos | passed | `lib/widgets/media_widgets.dart`; `test/widget_test.dart`; simulator screenshot |
| media_album_primary | Uploaded album photo becomes the primary proof image for Board, Batch, and Photos | passed | `lib/state/prep_board_controller.dart`; `lib/widgets/media_widgets.dart`; `flutter test` |
| iap_catalog_visible | Store renders all 27 product identifiers from the full catalog | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |

## Page Tests

| Page | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| board | Large upload empty state or uploaded user photo renders without asset image fallback | passed | `lib/screens/line_board_screen.dart`; `/private/tmp/prepline-simplified-board.png`; `flutter test` |
| batch | Large upload empty state or uploaded user photo renders without duplicate media panels | passed | `lib/screens/batch_detail_screen.dart`; `flutter analyze` |
| photos | Large upload empty state or uploaded user photo renders with compact history | passed | `lib/screens/station_timeline_screen.dart`; `flutter analyze` |
| store | All 27 product cards render, settings action is absent, and both policy links are present | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |
| protocols | User agreement and privacy policy open from Store and Settings via in-app WebView | passed | `lib/screens/protocol_screen.dart`; `lib/screens/pulse_store_screen.dart`; `lib/screens/settings_screen.dart`; `flutter build ios --simulator` |

## Linked Tests

| Link | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| core_navigation | Bottom navigation exposes only Board, Batch, Photos, and Store | passed | `lib/screens/app_shell.dart`; `test/widget_test.dart`; simulator screenshot |
| permission_to_ui | Permission status returns without settings jump | passed | `lib/services/prepline_permission_service.dart`; `flutter analyze` |
| purchase_to_balance | Purchase updates balance and visible store header | passed | `test/widget_test.dart`; `flutter test` |
| store_to_protocols | Store exposes User Agreement and Privacy Policy without a settings icon | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |
| settings_to_protocols | Settings retains User Agreement and Privacy Policy entries | passed | `lib/screens/settings_screen.dart`; `test/widget_test.dart` |
| spend_to_store | Low balance routes from spend notice to store | passed | `lib/widgets/pulse_balance_button.dart`; `flutter analyze` |
| launch_to_scene | SceneDelegate owns FlutterViewController plugin registration | passed | `ios/Runner/SceneDelegate.swift`; `simctl launch`; `flutter build ios --simulator` |

verification_skill_names: autobuya-ios-compliance, setup-iap

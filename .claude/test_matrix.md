# Test Matrix

## Functional Tests

| Area | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| state_sync | Save station state and read it back globally | passed | `flutter test` |
| batch_setup_sync | Board and Batch update current batch station and owner before save records are created | passed | `lib/widgets/batch_setup_fields.dart`; `lib/state/prep_board_controller.dart`; `test/widget_test.dart`; `flutter test` |
| ios_att | ATT request runs after first frame through the SceneDelegate native channel with prefixed key | passed | `lib/main.dart`; `ios/Runner/SceneDelegate.swift`; `simctl launch` |
| ios_permissions | Camera, microphone, photos, ATT keys and macros exist | passed | `ios/Runner/Info.plist`; `ios/Podfile`; `flutter build ios --simulator` |
| ios_resources | App icons, LaunchScreen, and Main storyboard are packaged into Runner.app | passed | `ios/Runner.xcodeproj/project.pbxproj`; `build/ios/iphonesimulator/Runner.app/Assets.car`; `flutter test` |
| relative_paths | Media storage stores relative paths and rebuilds full path | passed | `lib/services/prepline_document_media_store.dart`; `flutter test` |
| iap_init | IAP lazy initialization does not run on startup | passed | `lib/state/prep_board_controller.dart`; `flutter test` |
| iap_purchase | Purchase success credits balance once per delivery key | passed | `test/widget_test.dart`; `flutter test` |
| iap_purchase_feedback | Purchase preparing, success, and failure readbacks do not expose product IDs | passed | `lib/services/prepline_purchase_service.dart`; `lib/state/prep_board_controller.dart`; `test/widget_test.dart`; `flutter test` |
| spend_point | Save state spends exactly 10 units and every save surface shows the cost before the button | passed | `lib/state/prep_board_controller.dart`; `lib/widgets/status_widgets.dart`; `test/widget_test.dart` |
| state_local_records | Save state writes batch, station, note, exception, media, and log records to local app storage | passed | `lib/services/prepline_state_store.dart`; `test/widget_test.dart` |
| media_asset_visibility | Built-in `assets/images` are not rendered as UI photos | passed | `lib/widgets/media_widgets.dart`; `test/widget_test.dart`; simulator screenshot |
| media_album_primary | Uploaded album photo becomes the primary proof image for Board, Batch, and Photos | passed | `lib/state/prep_board_controller.dart`; `lib/widgets/media_widgets.dart`; `flutter test` |
| media_album_export | Export proof generates a proof card image from uploaded photo plus batch state and writes that generated card through the Photos album adapter | passed | `lib/state/prep_board_controller.dart`; `lib/services/prepline_document_media_store.dart`; `test/widget_test.dart`; `flutter test` |
| media_save_link | Saved state records link the uploaded proof photo relative path and keep historical proof images after replacement | passed | `lib/state/prep_board_controller.dart`; `lib/widgets/media_widgets.dart`; `test/widget_test.dart` |
| iap_catalog_visible | Store renders all 25 product identifiers from the full catalog | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |

## Page Tests

| Page | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| board | Large uploaded user photo stays visible, while Save ready with photo is the primary record action, export is secondary, the 10-credit spend is shown before save, and current owner/station are editable | passed | `lib/screens/line_board_screen.dart`; `lib/widgets/batch_setup_fields.dart`; `lib/widgets/media_widgets.dart`; `lib/widgets/status_widgets.dart`; `flutter test` |
| batch | Batch page promotes the same proof image, editable current-batch setup, primary state save, pre-save cost notice, and concise recent saved proof records | passed | `lib/screens/batch_detail_screen.dart`; `lib/widgets/batch_setup_fields.dart`; `lib/widgets/status_widgets.dart`; `flutter analyze`; `flutter test` |
| photos | Photos page focuses on saved proof records instead of a generic timeline list | passed | `lib/screens/station_timeline_screen.dart`; `flutter analyze`; `flutter test` |
| store | All 25 product cards render, settings action is absent, and both policy links are present | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |
| protocols | User agreement and privacy policy open from Store and Settings via in-app WebView | passed | `lib/screens/protocol_screen.dart`; `lib/screens/pulse_store_screen.dart`; `lib/screens/settings_screen.dart`; `flutter build ios --simulator` |

## Linked Tests

| Link | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| core_navigation | Bottom navigation exposes only Board, Batch, Photos, and Store | passed | `lib/screens/app_shell.dart`; `test/widget_test.dart`; simulator screenshot |
| batch_setup_to_history | Edited owner/station are written into saved record history instead of falling back to seed values | passed | `lib/state/prep_board_controller.dart`; `test/widget_test.dart` |
| permission_to_ui | Permission status returns without settings jump | passed | `lib/services/prepline_permission_service.dart`; `flutter analyze` |
| purchase_to_balance | Purchase updates balance and visible store header | passed | `test/widget_test.dart`; `flutter test` |
| purchase_feedback_privacy | Purchase result copy hides internal product identifiers from success and failure readbacks | passed | `test/widget_test.dart`; `flutter test` |
| store_to_protocols | Store exposes User Agreement and Privacy Policy without a settings icon | passed | `lib/screens/pulse_store_screen.dart`; `test/widget_test.dart` |
| settings_to_protocols | Settings retains User Agreement and Privacy Policy entries | passed | `lib/screens/settings_screen.dart`; `test/widget_test.dart` |
| spend_to_store | Low balance routes from spend notice to store | passed | `lib/widgets/pulse_balance_button.dart`; `flutter analyze` |
| service_clock_readback | Service Clock readback is derived from current batch data and refresh rebuilds UI | passed | `lib/screens/service_clock_screen.dart`; `flutter analyze` |
| launch_to_scene | SceneDelegate owns FlutterViewController plugin registration | passed | `ios/Runner/SceneDelegate.swift`; `simctl launch`; `flutter build ios --simulator` |

verification_skill_names: autobuya-ios-compliance, setup-iap

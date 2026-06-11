# Test Matrix

## Functional Tests

| Area | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| state_sync | Save station state and read it back globally | passed | `flutter test` |
| ios_att | ATT request runs before `runApp()` with prefixed key | passed | `lib/main.dart`; `flutter analyze` |
| ios_permissions | Camera, microphone, photos, ATT keys and macros exist | passed | `ios/Runner/Info.plist`; `ios/Podfile`; `flutter build ios --simulator` |
| relative_paths | Media storage stores relative paths and rebuilds full path | passed | `lib/services/prepline_document_media_store.dart`; `flutter test` |
| iap_init | IAP lazy initialization does not run on startup | passed | `lib/state/prep_board_controller.dart`; `flutter test` |
| iap_purchase | Purchase success credits balance once per delivery key | passed | `test/widget_test.dart`; `flutter test` |
| spend_point | Save state spends exactly 10 units | passed | `lib/state/prep_board_controller.dart`; `lib/screens/state_entry_screen.dart` |

## Page Tests

| Page | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| board | Large image and simplified board content render | passed | `lib/screens/line_board_screen.dart`; `flutter test` |
| batch | Large image and batch readback render | passed | `lib/screens/batch_detail_screen.dart`; `flutter analyze` |
| timeline | Large image and compact history render | passed | `lib/screens/station_timeline_screen.dart`; `flutter analyze` |
| store | Product cards and balance entry fit small screens | passed | `lib/screens/pulse_store_screen.dart`; `flutter analyze` |
| protocols | User agreement and privacy policy open in-app WebView | passed | `lib/screens/protocol_screen.dart`; `flutter build ios --simulator` |

## Linked Tests

| Link | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| permission_to_ui | Permission status returns without settings jump | passed | `lib/services/prepline_permission_service.dart`; `flutter analyze` |
| purchase_to_balance | Purchase updates balance and visible store header | passed | `test/widget_test.dart`; `flutter test` |
| spend_to_store | Low balance routes from spend notice to store | passed | `lib/widgets/pulse_balance_button.dart`; `flutter analyze` |

verification_skill_names: autobuya-ios-compliance, setup-iap

# Feature Coverage Matrix

| Feature | Surface | Status | Evidence |
| --- | --- | --- | --- |
| simplified_information_architecture | 4 primary tabs with 10 retained route contracts | passed | `lib/screens/app_shell.dart`; `test/widget_test.dart` |
| large_image_pages | Board, Batch, Photos with shared uploaded proof image, generated proof-card export, and primary state-save flow | passed | `lib/widgets/operational_page.dart`; `lib/widgets/media_widgets.dart`; `lib/screens/line_board_screen.dart`; `lib/screens/batch_detail_screen.dart`; `lib/screens/station_timeline_screen.dart` |
| iap_store | Store page renders all 27 products and purchase entries | passed | `lib/screens/pulse_store_screen.dart`; `lib/widgets/pulse_balance_button.dart`; `test/widget_test.dart` |
| balance_spend | State save costs 10 | passed | `lib/state/prep_board_controller.dart`; `lib/screens/state_entry_screen.dart` |
| saved_records | State save writes local records and links uploaded proof photos | passed | `lib/services/prepline_state_store.dart`; `lib/state/prep_board_controller.dart`; `lib/widgets/media_widgets.dart`; `test/widget_test.dart` |
| protocols | In-app WebView agreements from Store and Settings | passed | `lib/screens/protocol_screen.dart`; `lib/screens/pulse_store_screen.dart`; `lib/screens/settings_screen.dart` |

verification_skill_names: setup-iap

# Stage 2 Regression Matrix

| Area | Risk | Status | Evidence |
| --- | --- | --- | --- |
| relative_media_paths | Absolute iOS sandbox paths could break after restart | passed | `lib/services/prepline_document_media_store.dart`; `flutter test` |
| media_cleanup | Deleted media should clear stored resources | passed | `lib/state/prep_board_controller.dart`; `flutter analyze` |

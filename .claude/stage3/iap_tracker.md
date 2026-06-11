# Stage 3B IAP Tracker

skill_name: setup-iap
phase: completed

## Planning

Scope: Implement and re-review the 25 product catalog, lazy StoreKit service, purchase flow, idempotent balance crediting, global balance state, one spend point, discoverable store entry, and Store policy links.

Files: `pubspec.yaml`, `lib/models/pulse_store_models.dart`, `lib/services/prepline_purchase_service.dart`, `lib/services/prepline_state_store.dart`, `lib/state/prep_board_controller.dart`, `lib/screens/pulse_store_screen.dart`, `lib/widgets/pulse_balance_button.dart`, `lib/screens/app_shell.dart`, `lib/screens/state_entry_screen.dart`, `lib/screens/protocol_screen.dart`, `.claude/test_matrix.md`, `.claude/feature_coverage_matrix.md`, `.claude/stage4/layout_audit.md`.

Order: create catalog and wallet persistence; add purchase service with lazy init; wire controller balance and spend point; add store page and entry points; keep all 25 products visible without exposing product IDs in customer-facing cards; keep User Agreement and Privacy Policy reachable from Store; verify idempotent delivery and small-card layout.

Verification: `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build ios --simulator`.

Risks: Product IDs must remain verbatim in internal catalog and StoreKit config
without leaking into Store cards, purchase success, or failure readbacks;
purchase stream duplicate callbacks must not double-credit; balance must
refresh globally; save-state spend point must cost exactly 10; product cards
must not overflow on small screens.

Current user-supplied product table: 25 products, IDs `850221000` through
`850221024`, with price and amount values mirrored from the provided Telta
package screenshot. User Agreement loads
`https://qavix.teltaj.com/ServiceAgreement.html`; Privacy Policy loads
`https://qavix.teltaj.com/privacy-summary.html`.

Unique spend point: `PrepBoardController.saveState`, fixed cost 10 units. Board,
Batch, and State Entry are entry surfaces into that same spend point and must
show the 10-credit cost before the save button.

## Next Actions

- Implement IAP surfaces and tests.
- Re-read tracker, evidence map, test matrix, feature matrix, and layout audit before closeout.

## IAP Contract Checklist

| Item | Status | Evidence |
| --- | --- | --- |
| three_layer_init | passed | `lib/services/prepline_purchase_service.dart`; lazy controller creation |
| product_catalog_25_items | passed | `lib/models/pulse_store_models.dart`; `generated.storekit`; `lib/screens/pulse_store_screen.dart`; `flutter test` |
| product_code_override_applied | passed | product IDs `850221000` through `850221024` are stored verbatim |
| purchase_flow_complete | passed | `lib/screens/pulse_store_screen.dart`; `lib/services/prepline_purchase_service.dart` |
| store_cards_no_product_id | passed | Store product cards hide internal product IDs while showing credits and price |
| purchase_feedback_no_product_id | passed | preparing, success, and failure readbacks hide internal product IDs |
| transaction_cleanup_complete | passed | `_finishPlatformTransaction` guarded by `pendingCompletePurchase` |
| coin_delivery_idempotent | passed | `PulseWalletLedger.addPurchaseOnce`; `flutter test` |
| virtual_currency_persistence | passed | `SharedPreferences` balance ledger |
| single_spend_point_bound | passed | `PrepBoardController.saveState`; `PreplineStateStore.writeSession` |
| spend_point_cost_fixed_10 | passed | `PulseWalletLedger.stateSaveCost` |
| spend_point_notice_visible | passed | Board, Batch, and State Entry show a pre-save cost notice with post-save balance |
| balance_refresh_global | passed | `PrepBoardController` notifies all scoped pages |
| balance_entry_navigation | passed | Board balance button, Store nav item, State Entry balance button |
| iap_entry_accessible_from_normal_flow | passed | main Board page exposes balance entry; AppShell exposes Store |
| themed_product_logo_non_system_coin | passed | custom `CustomPainter` pulse mark in store cards |
| iap_page_ui_complete | passed | balance header, all 25 product cards, confirmation dialog, Store policy links |
| small_screen_card_layout_safe | passed | single-column grid; `flutter analyze`; `flutter test` |

## IAP Contract Evidence Map

- three_layer_init: StoreKit service is not constructed during app/controller startup; it is created only when buying.
- product_catalog_25_items: `pulseStoreCatalog` contains 25 products, IDs `850221000` to `850221024`, and `PulseStoreScreen` renders the full catalog rather than a reduced recommendation subset while hiding those IDs from the visible cards.
- purchase_flow_complete: card tap opens confirmation dialog before `buyConsumable(autoConsume: true)`.
- purchase_feedback_no_product_id: Store header/status feedback uses generic credit-pack copy for preparation and failures, and success copy reports only credited amount.
- transaction_cleanup_complete: purchased, restored, error, and canceled terminal states finish pending platform transactions.
- coin_delivery_idempotent: persisted delivery keys prevent duplicate crediting after repeated callbacks.
- single_spend_point_bound: state save is the only credit spend point, costs exactly 10, writes the saved record to local app storage, and must expose the cost before the save action on every entry surface.
- balance_entry_navigation: Board AppBar/body expose balance buttons; AppShell exposes Store as a primary destination.
- store_policy_links: Store exposes User Agreement and Privacy Policy without reintroducing the removed settings icon, and `ProtocolScreen` maps them to the official qavix.teltaj.com URLs.
- verification: `flutter analyze`; `flutter test`; `flutter build ios --simulator`.

## Blockers

- none

# Stage 3B IAP Tracker

skill_name: setup-iap
phase: completed

## Planning

Scope: Implement and re-review the 27 product catalog, lazy StoreKit service, purchase flow, idempotent balance crediting, global balance state, one spend point, discoverable store entry, and Store policy links.

Files: `pubspec.yaml`, `lib/models/pulse_store_models.dart`, `lib/services/prepline_purchase_service.dart`, `lib/services/prepline_state_store.dart`, `lib/state/prep_board_controller.dart`, `lib/screens/pulse_store_screen.dart`, `lib/widgets/pulse_balance_button.dart`, `lib/screens/app_shell.dart`, `lib/screens/state_entry_screen.dart`, `lib/screens/protocol_screen.dart`, `.claude/test_matrix.md`, `.claude/feature_coverage_matrix.md`, `.claude/stage4/layout_audit.md`.

Order: create catalog and wallet persistence; add purchase service with lazy init; wire controller balance and spend point; add store page and entry points; keep all 27 products visible; keep User Agreement and Privacy Policy reachable from Store; verify idempotent delivery and small-card layout.

Verification: `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build ios --simulator`.

Risks: Product IDs must remain verbatim; purchase stream duplicate callbacks must not double-credit; balance must refresh globally; save-state spend point must cost exactly 10; product cards must not overflow on small screens.

Unique spend point: `StateEntryScreen` save action, fixed cost 10 units.

## Next Actions

- Implement IAP surfaces and tests.
- Re-read tracker, evidence map, test matrix, feature matrix, and layout audit before closeout.

## IAP Contract Checklist

| Item | Status | Evidence |
| --- | --- | --- |
| three_layer_init | passed | `lib/services/prepline_purchase_service.dart`; lazy controller creation |
| product_catalog_27_items | passed | `lib/models/pulse_store_models.dart`; `lib/screens/pulse_store_screen.dart`; `flutter test` |
| product_code_override_applied | passed | product IDs `473900` through `473926` are stored verbatim |
| purchase_flow_complete | passed | `lib/screens/pulse_store_screen.dart`; `lib/services/prepline_purchase_service.dart` |
| transaction_cleanup_complete | passed | `_finishPlatformTransaction` guarded by `pendingCompletePurchase` |
| coin_delivery_idempotent | passed | `PulseWalletLedger.addPurchaseOnce`; `flutter test` |
| virtual_currency_persistence | passed | `SharedPreferences` balance ledger |
| single_spend_point_bound | passed | `PrepBoardController.saveState`; `PreplineStateStore.writeSession` |
| spend_point_cost_fixed_10 | passed | `PulseWalletLedger.stateSaveCost` |
| spend_point_notice_visible | passed | Board, Batch, and State Entry save surfaces |
| balance_refresh_global | passed | `PrepBoardController` notifies all scoped pages |
| balance_entry_navigation | passed | Board balance button, Store nav item, State Entry balance button |
| iap_entry_accessible_from_normal_flow | passed | main Board page exposes balance entry; AppShell exposes Store |
| themed_product_logo_non_system_coin | passed | custom `CustomPainter` pulse mark in store cards |
| iap_page_ui_complete | passed | balance header, all 27 product cards, confirmation dialog, Store policy links |
| small_screen_card_layout_safe | passed | single-column grid; `flutter analyze`; `flutter test` |

## IAP Contract Evidence Map

- three_layer_init: StoreKit service is not constructed during app/controller startup; it is created only when buying.
- product_catalog_27_items: `pulseStoreCatalog` contains 27 products, IDs `473900` to `473926`, and `PulseStoreScreen` renders the full catalog rather than a reduced recommendation subset.
- purchase_flow_complete: card tap opens confirmation dialog before `buyConsumable(autoConsume: true)`.
- transaction_cleanup_complete: purchased, restored, error, and canceled terminal states finish pending platform transactions.
- coin_delivery_idempotent: persisted delivery keys prevent duplicate crediting after repeated callbacks.
- single_spend_point_bound: state save is the only credit spend point, costs exactly 10, and writes the saved record to local app storage.
- balance_entry_navigation: Board AppBar/body expose balance buttons; AppShell exposes Store as a primary destination.
- store_policy_links: Store exposes User Agreement and Privacy Policy without reintroducing the removed settings icon.
- verification: `flutter analyze`; `flutter test`; `flutter build ios --simulator`.

## Blockers

- none

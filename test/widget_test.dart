import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:telta/data/prep_repository.dart';
import 'package:telta/data/prep_seed_data.dart';
import 'package:telta/models/prep_models.dart';
import 'package:telta/models/pulse_store_models.dart';
import 'package:telta/screens/app_shell.dart';
import 'package:telta/screens/batch_detail_screen.dart';
import 'package:telta/screens/line_board_screen.dart';
import 'package:telta/screens/protocol_screen.dart';
import 'package:telta/screens/pulse_store_screen.dart';
import 'package:telta/screens/service_clock_screen.dart';
import 'package:telta/screens/settings_screen.dart';
import 'package:telta/screens/station_timeline_screen.dart';
import 'package:telta/screens/state_entry_screen.dart';
import 'package:telta/services/prepline_document_media_store.dart';
import 'package:telta/services/prepline_permission_service.dart';
import 'package:telta/services/prepline_purchase_service.dart';
import 'package:telta/services/prepline_state_store.dart';
import 'package:telta/state/prep_board_controller.dart';
import 'package:telta/theme/prep_theme.dart';
import 'package:telta/widgets/media_widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('iOS metadata opts into the full-screen launch storyboard', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>UILaunchStoryboardName</key>'));
    expect(plist, contains('<string>LaunchScreen</string>'));
    expect(plist, contains('<key>CFBundleDisplayName</key>'));
    expect(plist, contains('<string>Telta</string>'));
    expect(plist, contains('<key>NSUserTrackingUsageDescription</key>'));
    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(plist, contains('<key>NSMicrophoneUsageDescription</key>'));
    expect(plist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(plist, contains('<key>NSPhotoLibraryAddUsageDescription</key>'));
  });

  test('iOS project packages app resources and registers scene plugins', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final sceneDelegate = File(
      'ios/Runner/SceneDelegate.swift',
    ).readAsStringSync();

    expect(project, contains('Main.storyboard in Resources'));
    expect(project, contains('Assets.xcassets in Resources'));
    expect(project, contains('LaunchScreen.storyboard in Resources'));
    expect(appDelegate, isNot(contains('GeneratedPluginRegistrant.register')));
    expect(
      sceneDelegate,
      contains(
          'GeneratedPluginRegistrant.register(with: flutterViewController)'),
    );
  });

  test('page contract keeps legacy routes outside the four-tab core shell', () {
    expect(pageContracts, hasLength(10));
    expect(pageContracts.map((contract) => contract.pageId), [
      'line-board',
      'batch-detail',
      'state-entry',
      'service-clock',
      'station-timeline',
      'exception-queue',
      'prep-rules',
      'pulse-store',
      'settings',
      'about',
    ]);
  });

  test('store catalog keeps the 25 verbatim product identifiers', () {
    expect(pulseStoreCatalog, hasLength(25));
    expect(pulseStoreCatalog.first.id, '850221000');
    expect(pulseStoreCatalog.first.amount, 100);
    expect(pulseStoreCatalog.first.referencePrice, '\$0.99');
    expect(pulseStoreCatalog.last.id, '850221024');
    expect(pulseStoreCatalog.last.amount, 7500);
    expect(pulseStoreCatalog.last.referencePrice, '\$39.99');
    expect(
      pulseStoreProductIds,
      containsAll(['850221000', '850221015', '850221024']),
    );
    expect(pulseStoreProductIds, isNot(contains('473900')));
  });

  test('generated StoreKit catalog mirrors product ids and policy URLs', () {
    final storeKit = jsonDecode(File('generated.storekit').readAsStringSync())
        as Map<String, dynamic>;
    final appPolicies = storeKit['appPolicies'] as Map<String, dynamic>;
    final policies = appPolicies['policies'] as List<dynamic>;
    final products = storeKit['products'] as List<dynamic>;

    expect(appPolicies['eula'], ProtocolScreen.userAgreementUrl);
    expect(
      (policies.single as Map<String, dynamic>)['policyURL'],
      ProtocolScreen.privacyPolicyUrl,
    );
    expect(products, hasLength(25));
    expect((products.first as Map<String, dynamic>)['productID'], '850221000');
    expect((products.first as Map<String, dynamic>)['displayPrice'], '0.99');
    expect((products.last as Map<String, dynamic>)['productID'], '850221024');
    expect((products.last as Map<String, dynamic>)['displayPrice'], '39.99');
  });

  test('protocol route maps agreement and privacy titles to official URLs', () {
    expect(
      ProtocolScreen.urlForTitle('User Agreement'),
      ProtocolScreen.userAgreementUrl,
    );
    expect(
      ProtocolScreen.urlForTitle('Privacy Policy'),
      ProtocolScreen.privacyPolicyUrl,
    );
  });

  test('relative media paths reject absolute persisted storage', () {
    final store = PreplineDocumentMediaStore();

    expect(store.isRelativePath('station_images/proof.jpg'), isTrue);
    expect(store.isRelativePath('/tmp/proof.jpg'), isFalse);
    expect(store.isRelativePath('../proof.jpg'), isFalse);
  });

  test('purchase delivery is idempotent for the same delivery key', () async {
    final controller = PrepBoardController();
    addTearDown(controller.dispose);

    await controller.addTestPurchaseDelivery(
      deliveryKey: 'delivery-850221000',
      amount: 100,
    );
    await controller.addTestPurchaseDelivery(
      deliveryKey: 'delivery-850221000',
      amount: 100,
    );

    expect(controller.pulseCredits, PulseWalletLedger.initialBalance + 100);
  });

  test('purchase readbacks hide product identifiers on success and failure',
      () async {
    const product = PulseStoreProduct(
      id: '850221001',
      amount: 398,
      referencePrice: '\$3.99',
      promotion: false,
    );

    final failed = Completer<PulsePurchaseResult>();
    final failedController = PrepBoardController(
      purchaseService: _FakePurchaseService(failed.future),
    );
    addTearDown(failedController.dispose);

    final failedPurchase = failedController.purchasePulseProduct(product);
    expect(failedController.storeReadback, 'Preparing credit pack.');
    expect(failedController.storeReadback, isNot(contains(product.id)));

    failed.complete(const PulsePurchaseResult(
      state: PulsePurchaseState.failed,
      message: 'This credit pack is not available yet.',
    ));
    await failedPurchase;

    expect(
      failedController.storeReadback,
      'This credit pack is not available yet.',
    );
    expect(failedController.storeReadback, isNot(contains(product.id)));

    final successful = Completer<PulsePurchaseResult>();
    final successfulController = PrepBoardController(
      purchaseService: _FakePurchaseService(successful.future),
    );
    addTearDown(successfulController.dispose);

    final successfulPurchase =
        successfulController.purchasePulseProduct(product);
    expect(successfulController.storeReadback, 'Preparing credit pack.');
    expect(successfulController.storeReadback, isNot(contains(product.id)));

    successful.complete(const PulsePurchaseResult(
      state: PulsePurchaseState.success,
      message: 'Added 398 prep credits.',
      balance: PulseWalletLedger.initialBalance + 398,
    ));
    await successfulPurchase;

    expect(successfulController.storeReadback, 'Added 398 prep credits.');
    expect(successfulController.storeReadback, isNot(contains(product.id)));
  });

  test('batch setup updates owner and station before saving records', () {
    final controller = PrepBoardController();
    addTearDown(controller.dispose);

    controller.selectBatch('B-126');
    controller.updateSelectedBatchDetails(
      station: 'Hot line',
      owner: 'Ari',
    );

    expect(controller.selectedBatch.station, 'Hot line');
    expect(controller.selectedBatch.owner, 'Ari');
    expect(controller.visibleConfirmation, contains('owner Ari'));

    controller.saveState(nextState: 'Ready', note: 'Owner changed at handoff.');

    expect(controller.latestSavedState.batchId, 'B-126');
    expect(controller.latestSavedState.station, 'Hot line');
    expect(controller.latestSavedState.owner, 'Ari');
    expect(controller.latestSavedState.note, 'Owner changed at handoff.');
  });

  test('Telta theme uses the requested brand color', () {
    expect(PrepTheme.gold.value, 0xFFE09B46);
  });

  test('wallet migrates legacy PrepLine Pulse balance and deliveries',
      () async {
    SharedPreferences.setMockInitialValues({
      'prepLinePulseCreditBalance': 42,
      'prepLinePulseDeliveredPurchases': ['legacy-delivery'],
    });

    final ledger = PulseWalletLedger();

    expect(await ledger.readBalance(), 42);
    expect(await ledger.delivered('legacy-delivery'), isTrue);
    expect(
      await ledger.addPurchaseOnce(
        deliveryKey: 'legacy-delivery',
        amount: 110,
      ),
      42,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('teltaCreditBalance'), 42);
    expect(
      prefs.getStringList('teltaDeliveredPurchases'),
      contains('legacy-delivery'),
    );
  });

  testWidgets('app shell fills the portrait viewport and pins navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(AppShell)),
      const Rect.fromLTWH(0, 0, 393, 852),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    expect(
      find.descendant(of: navBar, matching: find.byType(Text)),
      findsNWidgets(4),
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Board')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Batch')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Photos')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Store')),
      findsOneWidget,
    );
    expect(find.text('More'), findsNothing);
    expect(
      tester.getRect(find.byKey(const Key('shell-bottom-nav-surface'))).bottom,
      852,
    );
    expect(find.text('Line Board'), findsWidgets);

    final boardListRect = tester.getRect(
      find
          .descendant(
            of: find.byType(LineBoardScreen),
            matching: find.byType(ListView),
          )
          .first,
    );
    final navigationSurfaceRect = tester.getRect(
      find.byKey(const Key('shell-bottom-nav-surface')),
    );
    expect(boardListRect.bottom, lessThanOrEqualTo(navigationSurfaceRect.top));

    final navigationSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('shell-bottom-nav-surface')),
    );
    final surfaceDecoration = navigationSurface.decoration as BoxDecoration;
    expect(surfaceDecoration.color, isNotNull);
    expect(surfaceDecoration.color!.opacity, 1);
  });

  testWidgets('credit cost is visible before core save actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('line-board-save-cost-notice')), findsOneWidget);
    expect(find.text('Spend 10 credits before saving'), findsOneWidget);
    expect(find.textContaining('Balance after save:'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Batch'),
      ),
    );
    await tester.pumpAndSettle();

    final batchScroll = find
        .descendant(
          of: find.byType(AppShell),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('batch-detail-save-cost-notice')),
      300,
      scrollable: batchScroll,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('batch-detail-save-cost-notice')),
      findsOneWidget,
    );
    expect(find.text('Spend 10 credits before saving'), findsOneWidget);
    expect(find.textContaining('Balance after save:'), findsOneWidget);
    expect(
      find.byKey(const Key('batch-detail-mark-blocked-button')),
      findsOneWidget,
    );
  });

  testWidgets('primary proof photo gets tall space on core pages', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('primary-proof-hero-line-board'))),
      const Size(361, 426),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Batch'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('primary-proof-hero-batch-detail'))),
      const Size(361, 426),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Photos'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(
        find.byKey(const Key('primary-proof-hero-station-timeline')),
      ),
      const Size(361, 426),
    );
  });

  testWidgets(
      'board batch setup edits visible owner instead of fixed seed copy',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    expect(find.text('Owner Mika'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('line-board-owner-field')),
      'Ari',
    );
    await tester.pumpAndSettle();

    expect(find.text('Owner Ari'), findsOneWidget);
    expect(find.text('Owner Mika'), findsNothing);
  });

  testWidgets('batch tab can mark the active batch blocked', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Batch'),
      ),
    );
    await tester.pumpAndSettle();

    final batchScroll = find
        .descendant(
          of: find.byType(AppShell),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('batch-detail-mark-blocked-button')),
      300,
      scrollable: batchScroll,
    );
    await tester.ensureVisible(
      find.byKey(const Key('batch-detail-mark-blocked-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-detail-mark-blocked-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Saved B-104 as Blocked'), findsWidgets);
  });

  testWidgets('store page does not expose a settings action', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const TeltaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Store'));
    await tester.pumpAndSettle();

    expect(find.text('Store'), findsWidgets);
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.byKey(const Key('pulse-store-product-grid')), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);
    expect(find.textContaining('850221000'), findsNothing);

    final storeScroll = find
        .descendant(
          of: find.byType(PulseStoreScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('store-user-agreement-entry')),
      300,
      scrollable: storeScroll,
    );
    expect(find.byKey(const Key('store-user-agreement-entry')), findsOneWidget);
    expect(find.byKey(const Key('store-privacy-policy-entry')), findsOneWidget);
  });

  testWidgets('settings keeps both policy document entries', (tester) async {
    final controller = PrepBoardController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      PrepBoardScope(
        controller: controller,
        child: MaterialApp(
          routes: {
            SettingsScreen.routeName: (_) => const SettingsScreen(),
          },
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final settingsScroll = find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-user-agreement-entry')),
      300,
      scrollable: settingsScroll,
    );
    expect(
        find.byKey(const Key('settings-user-agreement-entry')), findsOneWidget);
    expect(
        find.byKey(const Key('settings-privacy-policy-entry')), findsOneWidget);
  });

  testWidgets(
    'flow-review-evidence covers state save readback and service clock',
    (tester) async {
      await tester.pumpWidget(const _FlowReviewEvidenceApp());
      await tester.pumpAndSettle();

      expect(find.text('Telta'), findsOneWidget);

      await tester.tap(find.text('State Entry'));
      await tester.pumpAndSettle();

      expect(find.text('State Entry'), findsWidgets);
      expect(
        find.byKey(const Key('state-entry-batch-selector')),
        findsOneWidget,
      );

      final stateEntryScroll = find
          .descendant(
            of: find.byType(StateEntryScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('state-entry-save-button')),
        300,
        scrollable: stateEntryScroll,
      );
      expect(
        find.byKey(const Key('state-entry-save-cost-notice')),
        findsOneWidget,
      );
      expect(find.text('Spend 10 credits before saving'), findsOneWidget);
      expect(find.textContaining('Balance after save:'), findsOneWidget);
      await tester
          .ensureVisible(find.byKey(const Key('state-entry-save-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('state-entry-save-button')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('saved-state-confirmation')),
        300,
        scrollable: stateEntryScroll,
      );
      expect(find.byKey(const Key('saved-state-confirmation')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('saved-state-confirmation')))
            .data,
        contains('Saved B-104 as'),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('state-entry-log-readback')),
        300,
        scrollable: stateEntryScroll,
      );
      expect(find.byKey(const Key('state-entry-log-readback')), findsOneWidget);
      expect(find.textContaining('B-104'), findsWidgets);
      expect(find.textContaining('Cooking'), findsWidgets);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service Clock'));
      await tester.pumpAndSettle();

      expect(find.text('Service Clock'), findsWidgets);
      expect(find.text('Service countdown'), findsOneWidget);

      final serviceClockScroll = find
          .descendant(
            of: find.byType(ServiceClockScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Window close summary'),
        300,
        scrollable: serviceClockScroll,
      );
      expect(find.text('Window close summary'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Readback: service-clock'),
        300,
        scrollable: serviceClockScroll,
      );
      expect(find.textContaining('Readback: service-clock'), findsOneWidget);
    },
  );

  testWidgets('state saves persist station, note, logs, and exceptions', (
    tester,
  ) async {
    final controller = PrepBoardController();
    addTearDown(controller.dispose);

    controller.saveState(
      station: 'Cold bar',
      nextState: 'Blocked',
      note: 'Needs manager check before handoff.',
    );

    expect(controller.selectedBatch.station, 'Cold bar');
    expect(controller.selectedBatch.state, 'Blocked');
    expect(
        controller.selectedBatch.note, 'Needs manager check before handoff.');
    expect(controller.latestSavedState.station, 'Cold bar');
    expect(controller.latestSavedState.note,
        'Needs manager check before handoff.');
    expect(controller.historyForSelectedBatch().first.state, 'Blocked');
    expect(controller.openExceptionForSelectedBatch(), isNotNull);

    controller.resolveBlocked(controller.selectedBatchId);

    expect(controller.selectedBatch.blocked, isFalse);
    expect(controller.openExceptionForSelectedBatch(), isNull);
    expect(controller.lastResolvedException, contains('B-104'));
  });

  test('state saves persist proof image paths and restore local records',
      () async {
    final pickedFile = File(
      '${Directory.systemTemp.path}/prepline-picked-proof.jpg',
    )..writeAsBytesSync([1, 2, 3, 4]);
    final mediaStore = _FakeMediaStore([
      'station_images/proof.jpg',
      'station_images/replacement.jpg',
    ]);
    final first = PrepBoardController(
      mediaStore: mediaStore,
      permissionService: _AlwaysAllowedPermissionService(),
      imagePicker: _FakeImagePicker(XFile(pickedFile.path)),
    );
    addTearDown(first.dispose);
    await first.ready;

    await first.uploadMedia('line-board');
    await first.waitForPendingPersistence();

    expect(first.primaryUserMediaFor('line-board')?.assetPath,
        'station_images/proof.jpg');
    expect(first.primaryUserMediaFor('batch-detail')?.assetPath,
        'station_images/proof.jpg');
    expect(first.saveScopeReadback, contains('proof photo'));

    first.saveState(
      station: 'Hot line',
      nextState: 'Ready',
      note: 'Photo proof linked.',
    );
    await first.waitForPendingPersistence();

    expect(first.latestSavedState.proofImagePath, 'station_images/proof.jpg');
    expect(first.visibleConfirmation, contains('Proof photo attached'));

    await first.uploadMedia('line-board');
    await first.waitForPendingPersistence();

    expect(
        mediaStore.deletedPaths, isNot(contains('station_images/proof.jpg')));
    expect(first.primaryUserMediaFor('line-board')?.assetPath,
        'station_images/replacement.jpg');
    expect(first.latestSavedState.proofImagePath, 'station_images/proof.jpg');

    final restored = PrepBoardController(
      mediaStore: _FakeMediaStore(),
      permissionService: _AlwaysAllowedPermissionService(),
      imagePicker: _FakeImagePicker(null),
    );
    addTearDown(restored.dispose);
    await restored.ready;

    expect(restored.selectedBatch.state, 'Ready');
    expect(restored.selectedBatch.note, 'Photo proof linked.');
    expect(
        restored.latestSavedState.proofImagePath, 'station_images/proof.jpg');
    expect(restored.primaryUserMediaFor('line-board')?.assetPath,
        'station_images/replacement.jpg');
    expect(restored.visibleConfirmation, contains('Restored B-104 Ready'));
  });

  testWidgets('photos proof records are tall and open batch detail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final proofFile = File(
      '${Directory.systemTemp.path}/station_images/proof.jpg',
    );
    proofFile.parent.createSync(recursive: true);
    proofFile.writeAsBytesSync(_transparentPngBytes);
    final snapshot = const PrepRepository().loadLineBoard();
    const proofLog = PrepLog(
      batchId: 'B-118',
      batchName: 'Avocado toast mise',
      station: 'Cold bar',
      state: 'Ready',
      owner: 'Lena',
      note: 'Photo record opened.',
      savedAt: '17:22',
      proofImagePath: 'station_images/proof.jpg',
    );
    final controller = PrepBoardController(
      mediaStore: _FakeMediaStore(),
      stateStore: _FakeStateStore(
        PreplineSavedSession(
          selectedBatchId: 'B-104',
          batches: snapshot.batches,
          stations: snapshot.stations,
          logs: [...seedLogs, proofLog],
          exceptions: seedExceptions,
          media: const [
            MediaRecord(
              id: 'M-proof',
              assetPath: 'station_images/proof.jpg',
              label: 'Uploaded proof photo',
              attachedTo: 'station-timeline',
              storedInDocuments: true,
            ),
          ],
        ),
      ),
    );
    addTearDown(controller.dispose);
    await controller.ready;

    await tester.pumpWidget(
      PrepBoardScope(
        controller: controller,
        child: MaterialApp(
          routes: {
            BatchDetailScreen.routeName: (_) => const BatchDetailScreen(),
          },
          home: const StationTimelineScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final thumbnail = find.byKey(
      const Key('saved-proof-thumbnail-17:22-B-118'),
    );
    expect(thumbnail, findsOneWidget);
    expect(tester.getSize(thumbnail).height, greaterThanOrEqualTo(200));

    await tester.tap(
      find.byKey(const Key('proof-record-card-17:22-B-118')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.selectedBatchId, 'B-118');
    expect(find.byType(BatchDetailScreen), findsOneWidget);
    expect(find.text('Batch Detail'), findsWidgets);
  });

  test('export proof card records Photos album feedback', () async {
    final pickedFile = File(
      '${Directory.systemTemp.path}/prepline-save-to-photos-proof.jpg',
    )..writeAsBytesSync([5, 6, 7, 8]);
    final mediaStore = _FakeMediaStore();
    final controller = PrepBoardController(
      mediaStore: mediaStore,
      permissionService: _AlwaysAllowedPermissionService(),
      imagePicker: _FakeImagePicker(XFile(pickedFile.path)),
    );
    addTearDown(controller.dispose);
    await controller.ready;
    await controller.uploadMedia('batch-detail');
    await controller.waitForPendingPersistence();
    final media = controller.primaryUserMediaFor('batch-detail')!;

    final exported = await controller.exportProofCardToAlbum(media.id);

    expect(exported, isTrue);
    expect(mediaStore.exportedProofCards, hasLength(1));
    expect(
      mediaStore.exportedProofCards.single,
      containsPair('photoRelativePath', 'station_images/proof.jpg'),
    );
    expect(
        mediaStore.exportedProofCards.single, containsPair('batchId', 'B-104'));
    expect(
      mediaStore.exportedProofCards.single,
      containsPair('batchName', 'Roast chicken trays'),
    );
    expect(
        mediaStore.exportedProofCards.single, containsPair('state', 'Cooking'));
    expect(controller.activeAlbumExportMediaId, isNull);
    expect(
      controller.mediaReadback,
      'Exported proof card to Photos album: Telta.',
    );
  });

  testWidgets('asset image records show upload-required placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrepMediaPreview(
            record: MediaRecord(
              id: 'media-test',
              assetPath: heroAsset,
              label: 'Station proof',
              attachedTo: 'line-board',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('Built-in asset images are hidden.'), findsOneWidget);
    expect(find.text('Upload required'), findsOneWidget);
  });
}

class _FlowReviewEvidenceApp extends StatefulWidget {
  const _FlowReviewEvidenceApp();

  @override
  State<_FlowReviewEvidenceApp> createState() => _FlowReviewEvidenceAppState();
}

class _FlowReviewEvidenceAppState extends State<_FlowReviewEvidenceApp> {
  late final PrepBoardController controller;

  @override
  void initState() {
    super.initState();
    controller = PrepBoardController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrepBoardScope(
      controller: controller,
      child: MaterialApp(
        title: 'Telta',
        routes: {
          StateEntryScreen.routeName: (_) => const StateEntryScreen(),
          ServiceClockScreen.routeName: (_) => const ServiceClockScreen(),
        },
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Telta')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      StateEntryScreen.routeName,
                    ),
                    child: const Text('State Entry'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      ServiceClockScreen.routeName,
                    ),
                    child: const Text('Service Clock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlwaysAllowedPermissionService extends PreplinePermissionService {
  @override
  Future<bool> requestPhotoLibraryRead() async => true;

  @override
  Future<bool> requestPhotoLibraryWrite() async => true;
}

class _FakeStateStore extends PreplineStateStore {
  _FakeStateStore(this.session);

  final PreplineSavedSession? session;
  PreplineSavedSession? writtenSession;

  @override
  Future<PreplineSavedSession?> readSession() async => session;

  @override
  Future<void> writeSession({
    required String selectedBatchId,
    required List<PrepBatch> batches,
    required List<StationStatus> stations,
    required List<PrepLog> logs,
    required List<PrepException> exceptions,
    required List<MediaRecord> media,
  }) async {
    writtenSession = PreplineSavedSession(
      selectedBatchId: selectedBatchId,
      batches: batches,
      stations: stations,
      logs: logs,
      exceptions: exceptions,
      media: media,
    );
  }
}

class _FakePurchaseService extends PreplinePurchaseService {
  _FakePurchaseService(this.result)
      : super(
          walletLedger: PulseWalletLedger(),
          purchaseClientFactory: () {
            throw StateError('Fake purchase service must not use native IAP.');
          },
        );

  final Future<PulsePurchaseResult> result;

  @override
  Future<PulsePurchaseResult> buyProduct(PulseStoreProduct product) => result;

  @override
  Future<void> dispose() async {}
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.file);

  final XFile? file;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return file;
  }
}

final _transparentPngBytes = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _FakeMediaStore extends PreplineDocumentMediaStore {
  _FakeMediaStore([List<String>? savedPaths])
      : _savedPaths = Queue.of(savedPaths ?? ['station_images/proof.jpg']);

  final Queue<String> _savedPaths;
  final List<String> deletedPaths = [];
  final List<Map<String, String>> exportedProofCards = [];

  @override
  Future<String> saveBytes({
    required Uint8List bytes,
    required String folder,
    required String extension,
  }) async {
    if (_savedPaths.isEmpty) {
      return 'station_images/proof.jpg';
    }
    return _savedPaths.removeFirst();
  }

  @override
  Future<File> rebuildFile(String relativePath) async {
    return File('${Directory.systemTemp.path}/$relativePath');
  }

  @override
  Future<void> deleteRelativePath(String relativePath) async {
    deletedPaths.add(relativePath);
  }

  @override
  Future<void> exportProofCardToGallery({
    required String photoRelativePath,
    required String batchId,
    required String batchName,
    required String station,
    required String state,
    required String owner,
    required String note,
    required String exportedAt,
  }) async {
    exportedProofCards.add({
      'photoRelativePath': photoRelativePath,
      'batchId': batchId,
      'batchName': batchName,
      'station': station,
      'state': state,
      'owner': owner,
      'note': note,
      'exportedAt': exportedAt,
    });
  }
}

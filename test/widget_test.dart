import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_20260610_124153/data/prep_seed_data.dart';
import 'package:app_20260610_124153/models/prep_models.dart';
import 'package:app_20260610_124153/models/pulse_store_models.dart';
import 'package:app_20260610_124153/screens/app_shell.dart';
import 'package:app_20260610_124153/screens/line_board_screen.dart';
import 'package:app_20260610_124153/screens/service_clock_screen.dart';
import 'package:app_20260610_124153/screens/state_entry_screen.dart';
import 'package:app_20260610_124153/services/prepline_document_media_store.dart';
import 'package:app_20260610_124153/services/prepline_purchase_service.dart';
import 'package:app_20260610_124153/state/prep_board_controller.dart';
import 'package:app_20260610_124153/widgets/media_widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('iOS metadata opts into the full-screen launch storyboard', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>UILaunchStoryboardName</key>'));
    expect(plist, contains('<string>LaunchScreen</string>'));
    expect(plist, contains('<key>CFBundleDisplayName</key>'));
    expect(plist, contains('<string>PrepLine Pulse</string>'));
    expect(plist, contains('<key>NSUserTrackingUsageDescription</key>'));
    expect(plist, contains('<key>NSCameraUsageDescription</key>'));
    expect(plist, contains('<key>NSMicrophoneUsageDescription</key>'));
    expect(plist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(plist, contains('<key>NSPhotoLibraryAddUsageDescription</key>'));
  });

  test('page contract stays within the simplified ten page surface', () {
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

  test('store catalog keeps the 27 verbatim product identifiers', () {
    expect(pulseStoreCatalog, hasLength(27));
    expect(pulseStoreCatalog.first.id, '473900');
    expect(pulseStoreCatalog.last.id, '473926');
    expect(pulseStoreProductIds, containsAll(['473900', '473918', '473926']));
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
      deliveryKey: 'delivery-473900',
      amount: 110,
    );
    await controller.addTestPurchaseDelivery(
      deliveryKey: 'delivery-473900',
      amount: 110,
    );

    expect(controller.pulseCredits, PulseWalletLedger.initialBalance + 110);
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

    await tester.pumpWidget(const PrepLinePulseApp());
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(AppShell)),
      const Rect.fromLTWH(0, 0, 393, 852),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
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

  testWidgets(
    'flow-review-evidence covers state save readback and service clock',
    (tester) async {
      await tester.pumpWidget(const _FlowReviewEvidenceApp());
      await tester.pumpAndSettle();

      expect(find.text('PrepLine Pulse'), findsOneWidget);

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
      await tester.tap(find.byKey(const Key('state-entry-save-button')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('saved-state-confirmation')),
        300,
        scrollable: stateEntryScroll,
      );
      expect(find.byKey(const Key('saved-state-confirmation')), findsOneWidget);
      expect(find.textContaining('Saved B-104 as'), findsOneWidget);

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

  testWidgets('media preview renders image assets as images', (tester) async {
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

    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('Image: assets/images/prepline_hero.png'),
        findsOneWidget);
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
        title: 'PrepLine Pulse',
        routes: {
          StateEntryScreen.routeName: (_) => const StateEntryScreen(),
          ServiceClockScreen.routeName: (_) => const ServiceClockScreen(),
        },
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('PrepLine Pulse')),
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

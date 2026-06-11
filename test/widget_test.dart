import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_20260610_124153/screens/app_shell.dart';
import 'package:app_20260610_124153/screens/service_clock_screen.dart';
import 'package:app_20260610_124153/screens/state_entry_screen.dart';
import 'package:app_20260610_124153/state/prep_board_controller.dart';

void main() {
  test('iOS metadata opts into the full-screen launch storyboard', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>UILaunchStoryboardName</key>'));
    expect(plist, contains('<string>LaunchScreen</string>'));
    expect(plist, contains('<key>CFBundleDisplayName</key>'));
    expect(plist, contains('<string>PrepLine Pulse</string>'));
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
  });

  testWidgets(
    'flow-review-evidence covers state save readback and service clock',
    (tester) async {
      await tester.pumpWidget(const _FlowReviewEvidenceApp());
      await tester.pumpAndSettle();

      expect(find.text('PrepLine Pulse'), findsOneWidget);

      await tester.tap(find.text('State Entry'));
      await tester.pumpAndSettle();

      expect(find.text('State Entry'), findsOneWidget);
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

      expect(find.text('Service Clock'), findsOneWidget);
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

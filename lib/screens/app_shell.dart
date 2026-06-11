import 'package:flutter/material.dart';

import '../state/prep_board_controller.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'batch_detail_screen.dart';
import 'exception_queue_screen.dart';
import 'line_board_screen.dart';
import 'prep_rules_screen.dart';
import 'protocol_screen.dart';
import 'pulse_store_screen.dart';
import 'service_clock_screen.dart';
import 'settings_screen.dart';
import 'state_entry_screen.dart';
import 'station_timeline_screen.dart';

class PrepLinePulseApp extends StatefulWidget {
  const PrepLinePulseApp({super.key});

  @override
  State<PrepLinePulseApp> createState() => _PrepLinePulseAppState();
}

class _PrepLinePulseAppState extends State<PrepLinePulseApp> {
  late final PrepBoardController boardController;

  @override
  void initState() {
    super.initState();
    boardController = PrepBoardController();
  }

  @override
  void dispose() {
    boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrepBoardScope(
      controller: boardController,
      child: MaterialApp(
        title: 'PrepLine Pulse',
        debugShowCheckedModeBanner: false,
        theme: PrepLineTheme.dark(),
        home: const AppShell(),
        routes: {
          LineBoardScreen.routeName: (_) => const AppShell(initialIndex: 0),
          BatchDetailScreen.routeName: (_) => const BatchDetailScreen(),
          StateEntryScreen.routeName: (_) => const StateEntryScreen(),
          ServiceClockScreen.routeName: (_) => const ServiceClockScreen(),
          StationTimelineScreen.routeName: (_) => const StationTimelineScreen(),
          ExceptionQueueScreen.routeName: (_) => const ExceptionQueueScreen(),
          PrepRulesScreen.routeName: (_) => const PrepRulesScreen(),
          PulseStoreScreen.routeName: (_) => const PulseStoreScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          AboutScreen.routeName: (_) => const AboutScreen(),
          ProtocolScreen.routeName: (_) => const ProtocolScreen(),
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index =
      widget.initialIndex >= 0 && widget.initialIndex < _screens.length
          ? widget.initialIndex
          : 0;

  static const _screens = <Widget>[
    LineBoardScreen(),
    BatchDetailScreen(),
    StationTimelineScreen(),
    PulseStoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final body = IndexedStack(index: index, children: _screens);
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: Text('Board'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: Text('Batch'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_library_outlined),
                  label: Text('Photos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_activity_outlined),
                  label: Text('Store'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: background,
      body: body,
      bottomNavigationBar: DecoratedBox(
        key: const Key('shell-bottom-nav-surface'),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(.18),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Board',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Batch',
              ),
              NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                label: 'Photos',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_activity_outlined),
                label: 'Store',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

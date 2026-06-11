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
  late int index = widget.initialIndex;

  static const _screens = <Widget>[
    LineBoardScreen(),
    BatchDetailScreen(),
    StateEntryScreen(),
    ServiceClockScreen(),
    StationTimelineScreen(),
    ExceptionQueueScreen(),
    PrepRulesScreen(),
    PulseStoreScreen(),
    SettingsScreen(),
    AboutScreen(),
  ];

  static const _moreDestinations = <_MoreDestination>[
    _MoreDestination('Station timeline', Icons.timeline_outlined, 4),
    _MoreDestination('Exception queue', Icons.report_problem_outlined, 5),
    _MoreDestination('Prep rules', Icons.rule_outlined, 6),
    _MoreDestination('Store', Icons.local_activity_outlined, 7),
    _MoreDestination('Settings', Icons.tune, 8),
    _MoreDestination('About', Icons.info_outline, 9),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final body = IndexedStack(index: index, children: _screens);
    if (wide) {
      final selectedRailIndex = index > 7 ? 0 : index;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedRailIndex,
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
                  icon: Icon(Icons.edit_note_outlined),
                  label: Text('Entry'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  label: Text('Clock'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.timeline_outlined),
                  label: Text('Timeline'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.report_problem_outlined),
                  label: Text('Exceptions'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.rule_outlined),
                  label: Text('Rules'),
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
            selectedIndex: index > 4 ? 4 : index,
            onDestinationSelected: (value) {
              if (value == 4) {
                _showMoreMenu(context);
                return;
              }
              setState(() => index = value);
            },
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
                icon: Icon(Icons.edit_note_outlined),
                label: 'Entry',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                label: 'Clock',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('PrepLine Pulse')),
              _DrawerLink(
                label: 'Station timeline',
                onTap: () => setState(() => index = 4),
              ),
              _DrawerLink(
                label: 'Exception queue',
                onTap: () => setState(() => index = 5),
              ),
              _DrawerLink(
                label: 'Prep rules',
                onTap: () => setState(() => index = 6),
              ),
              _DrawerLink(
                label: 'Store',
                onTap: () => setState(() => index = 7),
              ),
              _DrawerLink(
                label: 'Settings',
                onTap: () => setState(() => index = 8),
              ),
              _DrawerLink(
                label: 'About',
                onTap: () => setState(() => index = 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('More')),
              for (final destination in _moreDestinations)
                ListTile(
                  leading: Icon(destination.icon),
                  title: Text(destination.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => index = destination.index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MoreDestination {
  const _MoreDestination(this.label, this.icon, this.index);

  final String label;
  final IconData icon;
  final int index;
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

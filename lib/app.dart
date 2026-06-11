import 'package:flutter/material.dart';

import 'data/prep_seed_data.dart';
import 'screens/about_screen.dart';
import 'screens/batch_detail_detail_screen.dart';
import 'screens/batch_detail_screen.dart';
import 'screens/exception_queue_screen.dart';
import 'screens/line_board_detail_screen.dart';
import 'screens/line_board_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/prep_rules_screen.dart';
import 'screens/service_clock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/state_entry_detail_screen.dart';
import 'screens/state_entry_screen.dart';
import 'screens/station_timeline_screen.dart';
import 'state/prep_line_state.dart';
import 'theme/prep_theme.dart';

class PrepLinePulseApp extends StatefulWidget {
  const PrepLinePulseApp({super.key});

  @override
  State<PrepLinePulseApp> createState() => _PrepLinePulseAppState();
}

class _PrepLinePulseAppState extends State<PrepLinePulseApp> {
  late final PrepLineController controller;

  @override
  void initState() {
    super.initState();
    controller = PrepLineController();
  }

  @override
  Widget build(BuildContext context) {
    return PrepLineScope(
      controller: controller,
      child: MaterialApp(
        title: 'PrepLine Pulse',
        debugShowCheckedModeBanner: false,
        theme: PrepTheme.dark(),
        initialRoute: LineBoardScreen.routeName,
        routes: {
          LineBoardScreen.routeName: (_) => const LineBoardScreen(),
          BatchDetailScreen.routeName: (_) => const BatchDetailScreen(),
          StateEntryScreen.routeName: (_) => const StateEntryScreen(),
          ServiceClockScreen.routeName: (_) => const ServiceClockScreen(),
          StationTimelineScreen.routeName: (_) => const StationTimelineScreen(),
          ExceptionQueueScreen.routeName: (_) => const ExceptionQueueScreen(),
          PrepRulesScreen.routeName: (_) => const PrepRulesScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
          AboutScreen.routeName: (_) => const AboutScreen(),
          LineBoardDetailScreen.routeName: (_) => const LineBoardDetailScreen(),
          BatchDetailDetailScreen.routeName: (_) =>
              const BatchDetailDetailScreen(),
          StateEntryDetailScreen.routeName: (_) =>
              const StateEntryDetailScreen(),
        },
        onUnknownRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const LineBoardScreen(),
          settings: RouteSettings(name: pageContracts.first.routeName),
        ),
      ),
    );
  }
}

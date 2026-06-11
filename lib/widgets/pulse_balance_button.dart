import 'package:flutter/material.dart';

import '../screens/pulse_store_screen.dart';
import '../state/prep_board_controller.dart';

class PulseBalanceButton extends StatelessWidget {
  const PulseBalanceButton({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final label = compact
        ? '${controller.pulseCredits}'
        : '${controller.pulseCredits} prep credits';
    return OutlinedButton.icon(
      key: const Key('pulse-balance-entry'),
      onPressed: () => Navigator.pushNamed(context, PulseStoreScreen.routeName),
      icon: const Icon(Icons.local_activity_outlined),
      label: Text(label),
    );
  }
}

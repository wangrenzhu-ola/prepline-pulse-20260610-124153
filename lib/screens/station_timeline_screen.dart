import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart';
import '../widgets/prep_widgets.dart';

// page_id: station-timeline | route_name: /station-timeline | widget_class: StationTimelineScreen | state_key: stationTimelineState
class StationTimelineScreen extends StatelessWidget {
  const StationTimelineScreen({super.key});

  static const routeName = '/station-timeline';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final logs = controller.logs.reversed.toList();

    return OperationalPage(
      pageId: 'station-timeline',
      title: 'Photos',
      mediaTarget: 'station-timeline',
      children: [
        InfoCard(
          title: 'Recent saves',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logs.isEmpty)
                const Text('Save a batch state to start the timeline.'),
              for (final log in logs.take(4)) _TimelineEntry(log: log),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.log});

  final PrepLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(log.savedAt),
                  StatusChip(log.station),
                  StatusChip(log.state),
                  StatusChip('Owner ${log.owner}'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${log.batchId} ${log.batchName}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

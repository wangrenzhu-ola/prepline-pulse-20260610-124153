import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/media_widgets.dart';
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
    final proofLogs = logs.where((log) => log.hasProofImage).toList();

    return OperationalPage(
      pageId: 'station-timeline',
      title: 'Photos',
      mediaTarget: 'station-timeline',
      children: [
        InfoCard(
          title: 'Proof records',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (proofLogs.isEmpty)
                const Text(
                  'Upload a proof photo, then save a batch state to keep it here.',
                ),
              for (final log in proofLogs.take(4)) _TimelineEntry(log: log),
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
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SavedProofThumbnail(log: log),
              const SizedBox(height: 10),
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
              const SizedBox(height: 4),
              Text(log.note),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: uri_does_not_exist, unused_import

import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../state/prep_line_state.dart';
import '../widgets/operational_page.dart';
import '../widgets/prep_widgets.dart';
import '../widgets/status_widgets.dart';

// page_id: station-timeline | route_name: /station-timeline | widget_class: StationTimelineScreen | state_key: stationTimelineState
class StationTimelineScreen extends StatelessWidget {
  const StationTimelineScreen({super.key});

  static const routeName = '/station-timeline';

  @override
  Widget build(BuildContext context) {
    final controller = PrepLineScope.of(context);
    final logs = controller.logs.reversed.toList();
    final latest = logs.isEmpty ? null : logs.first;
    final stations = {
      'All stations',
      ...controller.batches.map((batch) => batch.station),
      ...controller.logs.map((log) => log.station),
    }.toList();
    final states = {
      'All states',
      ...controller.batches.map((batch) => batch.state),
      ...controller.logs.map((log) => log.state),
    }.toList();

    return PrepScaffold(
      contract: pageContracts[4],
      hero: ContractHero(contract: pageContracts[4], assetPath: heroAsset),
      children: [
        const MediaRecordPanel(attachedTo: 'station-timeline', hero: true),
        InfoCard(
          title: 'Date, station, state filters',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const StatusChip('Today'),
                  for (final station in stations) StatusChip(station),
                  for (final state in states) StatusChip(state),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                latest == null
                    ? 'No saved state entries yet.'
                    : 'Showing ${logs.length} saved updates through ${latest.savedAt} for ${latest.station}.',
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'State history preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final log in logs.take(4)) _TimelineEntry(log: log),
            ],
          ),
        ),
        InfoCard(
          title: 'Continuity readback',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (latest != null) ...[
                Text(
                  'Latest saved state: ${latest.batchId} ${latest.batchName} is ${latest.state}.',
                ),
                const SizedBox(height: 6),
                Text(
                  'Station handoff: ${latest.station} at ${latest.savedAt} by ${latest.owner}.',
                ),
                const SizedBox(height: 6),
                Text('Readback note: ${latest.note}'),
              ] else
                const Text(
                  'Timeline continuity will appear after the first saved update.',
                ),
              if (controller.lastConfirmation != null) ...[
                const SizedBox(height: 10),
                Text(controller.lastConfirmation!),
              ],
            ],
          ),
        ),
        InfoCard(
          title: 'Owner badges',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final owner
                  in controller.logs.map((log) => log.owner).toSet())
                StatusChip('$owner owner'),
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
                '${log.batchId} - ${log.batchName}',
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

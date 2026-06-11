import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart';

// page_id source marker: state-entry_detail
// page_id: state-entry_detail | route_name: /state-entry-detail | widget_class: StateEntryDetailScreen | state_key: stateEntryDetailState
class StateEntryDetailScreen extends StatelessWidget {
  const StateEntryDetailScreen({super.key});
  static const routeName = '/state-entry-detail';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final batch = controller.selectedBatch;
    final PrepLog latestLog = controller.latestSavedState;
    final confirmation = controller.visibleConfirmation;

    return OperationalPage(
      pageId: 'state-entry_detail',
      title: 'State Entry Detail',
      children: [
        _DetailCard(
          title: 'Stepper progress',
          child: Text(
            '1 Batch ${batch.id} selected -> 2 ${batch.station} '
            'read back -> 3 ${latestLog.state} log ready',
            key: const Key('state-entry-detail-stepper-progress'),
          ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Saved confirmation',
          child: Text(
            confirmation,
            key: const Key('state-entry-detail-saved-confirmation'),
          ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Saved-state log readback',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batch: ${latestLog.batchId} ${latestLog.batchName}'),
              Text('Station: ${latestLog.station}'),
              Text('State: ${latestLog.state}'),
              Text('Owner: ${latestLog.owner}'),
              Text('Note: ${latestLog.note}'),
              Text('Saved at: ${latestLog.savedAt}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Next action',
          child: Text(
            latestLog.state == 'Blocked'
                ? 'Open exception queue for ${latestLog.batchName}.'
                : 'Return to the line board and continue station review.',
            key: const Key('state-entry-detail-next-action'),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

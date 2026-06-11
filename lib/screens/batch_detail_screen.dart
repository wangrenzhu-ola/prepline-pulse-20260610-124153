import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';
import '../widgets/media_widgets.dart';
import '../widgets/operational_page.dart';
import '../widgets/prep_widgets.dart';
import '../widgets/status_widgets.dart';
import 'batch_detail_detail_screen.dart';
import 'state_entry_screen.dart' show StateEntryScreen;

typedef BatchDetailActionContract = PrepBoardController;

// page_id: batch-detail | route_name: /batch-detail | widget_class: BatchDetailScreen | state_key: batchDetailState
class BatchDetailScreen extends StatelessWidget {
  const BatchDetailScreen({super.key});
  static const routeName = '/batch-detail';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final batch = controller.selectedBatch;
        final history = controller.historyForSelectedBatch();
        final exception = controller.openExceptionForSelectedBatch();
        final media = controller.mediaFor('batch-detail');

        return OperationalPage(
          pageId: 'batch-detail',
          title: pageContracts[1].title,
          children: [
            InfoCard(
              title: 'Batch identity',
              trailing: PrepStatusPill(
                batch.state,
                color: batch.blocked ? PrepTheme.error : PrepTheme.success,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${batch.id} ${batch.name}',
                    key: const Key('batch-detail-identity-readback'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  BatchSummary(batch: batch),
                  const SizedBox(height: 10),
                  Text(
                    'Service window: ${batch.serviceWindow}; ${batch.minutesToWindow} minutes out.',
                  ),
                ],
              ),
            ),
            InfoCard(
              title: 'Station assignment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned station: ${batch.station}',
                    key: const Key('batch-detail-station-readback'),
                  ),
                  Text('Owner ${batch.owner}; backup ${batch.backup}.'),
                  Text('Quantity: ${batch.quantity} portions.'),
                  const SizedBox(height: 8),
                  Text('Station note: ${batch.note}'),
                ],
              ),
            ),
            const MediaRecordPanel(attachedTo: 'batch-detail', hero: false),
            if (media.isNotEmpty) PrepMediaPreview(record: media.first),
            const SizedBox(height: 12),
            InfoCard(
              title: 'State history preview',
              trailing: PrepStatusPill('${media.length} media'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (history.isEmpty)
                    const Text('No saved state history for this batch yet.'),
                  for (final log in history.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${log.savedAt} - ${log.station} - ${log.state} by ${log.owner}: ${log.note}',
                        key: Key(
                          'batch-detail-history-${log.savedAt}-${log.state}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            InfoCard(
              title: 'Edit and resolve controls',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        key: const Key('batch-detail-save-state-button'),
                        onPressed: () {
                          controller.selectBatch(batch.id);
                          controller.saveState();
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save State'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('batch-detail-edit-state-button'),
                        onPressed: () {
                          controller.selectBatch(batch.id);
                          Navigator.pushNamed(
                            context,
                            StateEntryScreen.routeName,
                          );
                        },
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Edit State'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('batch-detail-resolve-blocked-button'),
                        onPressed: exception == null
                            ? null
                            : () {
                                controller.selectBatch(batch.id);
                                controller.resolveBlocked(batch.id);
                              },
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Resolve Blocked'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          BatchDetailDetailScreen.routeName,
                        ),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Audit Detail'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (controller.lastConfirmation != null)
                    Text(
                      controller.lastConfirmation!,
                      key: const Key('batch-detail-save-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                  if (controller.lastResolvedException != null)
                    Text(
                      controller.lastResolvedException!,
                      key: const Key('batch-detail-resolution-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                  if (exception != null)
                    Text(
                      'Open blocker: ${exception.reason} (${exception.owner}).',
                    ),
                  if (exception == null)
                    const Text('No open blocker for the selected batch.'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

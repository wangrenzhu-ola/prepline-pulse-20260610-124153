import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';
import '../widgets/media_widgets.dart';
import '../widgets/operational_page.dart';
import '../widgets/prep_widgets.dart';
import '../widgets/status_widgets.dart';

typedef BatchDetailDetailActionContract = PrepBoardController;

// page_id: batch-detail_detail | route_name: /batch-detail-detail | widget_class: BatchDetailDetailScreen | state_key: batchDetailDetailState
class BatchDetailDetailScreen extends StatelessWidget {
  const BatchDetailDetailScreen({super.key});
  static const routeName = '/batch-detail-detail';

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
          pageId: 'batch-detail_detail',
          title: pageContracts[11].title,
          children: [
            InfoCard(
              title: 'Batch audit readback',
              trailing: PrepStatusPill(
                batch.blocked ? 'blocked' : batch.state,
                color: batch.blocked ? PrepTheme.error : PrepTheme.success,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${batch.id} ${batch.name}',
                    key: const Key('batch-detail-detail-identity-readback'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Station assignment: ${batch.station}'),
                  Text('Owner: ${batch.owner}; backup: ${batch.backup}.'),
                  Text('Quantity: ${batch.quantity} portions.'),
                  Text('Note: ${batch.note}'),
                ],
              ),
            ),
            InfoCard(
              title: 'History ledger',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (history.isEmpty)
                    const Text('No history entries are saved for this batch.'),
                  for (final log in history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LedgerRow(log: log),
                    ),
                ],
              ),
            ),
            InfoCard(
              title: 'Media preview',
              trailing: PrepStatusPill('${media.length} attached'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (media.isEmpty)
                    const Text('No media attached to this batch.'),
                  if (media.isNotEmpty) PrepMediaPreview(record: media.first),
                  if (media.isNotEmpty) const SizedBox(height: 10),
                  for (final item in media.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              item.assetPath,
                              width: 88,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${item.id}: ${item.label}')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            InfoCard(
              title: 'Resolution status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${controller.blockedCount} open exceptions remain.'),
                  if (exception != null)
                    Text(
                      'Selected batch blocker: ${exception.reason}; assigned to ${exception.owner}.',
                    ),
                  if (exception == null)
                    const Text('Selected batch has no open blocker.'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        key: const Key('batch-detail-detail-save-state-button'),
                        onPressed: () {
                          controller.selectBatch(batch.id);
                          controller.saveState();
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Audit State'),
                      ),
                      OutlinedButton.icon(
                        key: const Key(
                          'batch-detail-detail-resolve-blocked-button',
                        ),
                        onPressed: exception == null
                            ? null
                            : () {
                                controller.selectBatch(batch.id);
                                controller.resolveBlocked(batch.id);
                              },
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Resolve Blocked'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (controller.lastConfirmation != null)
                    Text(
                      controller.lastConfirmation!,
                      key: const Key('batch-detail-detail-save-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                  if (controller.lastResolvedException != null)
                    Text(
                      controller.lastResolvedException!,
                      key: const Key('batch-detail-detail-resolution-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.log});

  final PrepLog log;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: PrepTheme.gold.withOpacity(.6),
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${log.savedAt} - ${log.state}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text('${log.station} by ${log.owner}'),
            Text(log.note),
          ],
        ),
      ),
    );
  }
}

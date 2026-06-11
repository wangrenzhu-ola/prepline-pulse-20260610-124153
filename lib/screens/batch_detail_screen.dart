import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../services/prepline_purchase_service.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';
import '../widgets/media_widgets.dart';
import '../widgets/operational_page.dart';
import '../widgets/prep_widgets.dart';
import '../widgets/status_widgets.dart';

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
        final canSpend =
            controller.pulseCredits >= PulseWalletLedger.stateSaveCost;

        return OperationalPage(
          pageId: 'batch-detail',
          title: 'Batch Detail',
          mediaTarget: 'batch-detail',
          children: [
            InfoCard(
              title: 'Selected batch',
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
                ],
              ),
            ),
            InfoCard(
              title: 'Save this batch',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.note,
                    key: const Key('batch-detail-station-readback'),
                  ),
                  const SizedBox(height: 12),
                  PrepCostNotice(
                    key: const Key('batch-detail-save-cost-notice'),
                    cost: PulseWalletLedger.stateSaveCost,
                    balance: controller.pulseCredits,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('batch-detail-save-state-button'),
                      onPressed: canSpend
                          ? () => _saveReady(context, controller, batch.id)
                          : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(controller.primarySaveActionLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('batch-detail-resolve-blocked-button'),
                      onPressed: exception == null
                          ? null
                          : () => _resolveBlock(
                                context,
                                controller,
                                batch.id,
                              ),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Clear block'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.saveScopeReadback,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (controller.lastConfirmation != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      controller.lastConfirmation!,
                      key: const Key('batch-detail-save-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                  ],
                  if (controller.lastResolvedException != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      controller.lastResolvedException!,
                      key: const Key('batch-detail-resolution-readback'),
                      style: const TextStyle(color: PrepTheme.success),
                    ),
                  ],
                ],
              ),
            ),
            InfoCard(
              title: 'Recent history',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (history.isEmpty) const Text('No saved updates yet.'),
                  for (final log in history.take(2)) _HistoryRecord(log: log),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveReady(
    BuildContext context,
    PrepBoardController controller,
    String batchId,
  ) {
    controller.selectBatch(batchId);
    controller.saveState(nextState: 'Ready');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(controller.visibleConfirmation),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _resolveBlock(
    BuildContext context,
    PrepBoardController controller,
    String batchId,
  ) {
    controller.selectBatch(batchId);
    controller.resolveBlocked(batchId);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(controller.lastResolvedException ?? 'Block cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _HistoryRecord extends StatelessWidget {
  const _HistoryRecord({required this.log});

  final PrepLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SavedProofThumbnail(log: log, compact: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.savedAt} ${log.station}: ${log.state}',
                  key: Key('batch-detail-history-${log.savedAt}-${log.state}'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  log.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';
import '../widgets/operational_page.dart';
import '../widgets/pulse_balance_button.dart';
import '../widgets/status_widgets.dart';
import 'batch_detail_screen.dart';

// page_id: line-board | route_name: /line-board | widget_class: LineBoardScreen | state_key: lineBoardState
class LineBoardScreen extends StatelessWidget {
  const LineBoardScreen({super.key});
  static const routeName = '/line-board';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    return OperationalPage(
      pageId: 'line-board',
      title: 'Line Board',
      actions: const [PulseBalanceButton(compact: true)],
      mediaTarget: 'line-board',
      children: [
        ConfirmationBanner(message: controller.visibleConfirmation),
        const SizedBox(height: 12),
        _FocusBatchCard(controller: controller),
        const SizedBox(height: 12),
        _StationStrip(controller: controller),
      ],
    );
  }
}

class _FocusBatchCard extends StatelessWidget {
  const _FocusBatchCard({required this.controller});

  final PrepBoardController controller;

  @override
  Widget build(BuildContext context) {
    final batch = controller.selectedBatch;
    final statusColor = batch.blocked ? PrepTheme.error : PrepTheme.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save current state',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${batch.id} ${batch.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PrepStatusPill(
                  batch.state,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PrepStatusPill(batch.station, icon: Icons.room_outlined),
                PrepStatusPill('Owner ${batch.owner}'),
                PrepStatusPill('${controller.pulseCredits} credits'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: controller.selectedBatchId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Batch'),
              items: [
                for (final batch in controller.batches)
                  DropdownMenuItem(
                    value: batch.id,
                    child: Text(
                      '${batch.id} ${batch.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.selectBatch(value);
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('line-board-primary-save-button'),
                onPressed: () => _saveReady(context, controller),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(controller.primarySaveActionLabel),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      BatchDetailScreen.routeName,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Open batch'),
                  ),
                ),
                if (batch.blocked) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller.resolveBlocked(batch.id),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Clear block'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              controller.saveScopeReadback,
              key: const Key('board-save-scope-readback'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _saveReady(BuildContext context, PrepBoardController controller) {
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
}

class _StationStrip extends StatelessWidget {
  const _StationStrip({required this.controller});

  final PrepBoardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.stations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final station = controller.stations[index];
                  final batch = controller.batches.firstWhere(
                    (item) => item.id == station.activeBatchId,
                  );
                  return _StationTile(
                    station: station,
                    batch: batch,
                    selected: batch.id == controller.selectedBatchId,
                    onTap: () => controller.selectBatch(batch.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({
    required this.station,
    required this.batch,
    required this.selected,
    required this.onTap,
  });

  final StationStatus station;
  final PrepBatch batch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = batch.blocked ? PrepTheme.error : PrepTheme.success;
    return SizedBox(
      width: 178,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                selected ? PrepTheme.gold.withOpacity(.14) : PrepTheme.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PrepTheme.gold.withOpacity(.55)
                  : Colors.white.withOpacity(.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.station,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.radio_button_checked, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                PrepStatusPill(batch.state, color: statusColor),
                const Spacer(),
                Text(
                  batch.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

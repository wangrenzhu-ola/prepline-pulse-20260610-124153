import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';
import '../widgets/media_widgets.dart';
import '../widgets/operational_page.dart';
import '../widgets/pulse_balance_button.dart';
import '../widgets/status_widgets.dart';
import 'batch_detail_screen.dart';
import 'state_entry_screen.dart' as state_entry;

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
      children: [
        _ServiceWindowCard(controller: controller),
        const SizedBox(height: 12),
        ConfirmationBanner(message: controller.visibleConfirmation),
        const SizedBox(height: 12),
        _PrimaryUpdateControl(controller: controller),
        const SizedBox(height: 12),
        _LatestSavedState(log: controller.latestSavedState),
        const SizedBox(height: 12),
        Text(
          'Station status cards',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final station in controller.stations) ...[
          _StationStatusCard(
            station: station,
            batch: controller.batches.firstWhere(
              (batch) => batch.id == station.activeBatchId,
            ),
            selectedBatchId: controller.selectedBatchId,
            onSelect: controller.selectBatch,
            onResolve: controller.resolveBlocked,
          ),
          const SizedBox(height: 10),
        ],
        PrepMediaPreview(record: controller.media),
      ],
    );
  }
}

class _ServiceWindowCard extends StatelessWidget {
  const _ServiceWindowCard({required this.controller});

  final PrepBoardController controller;

  @override
  Widget build(BuildContext context) {
    final window = controller.serviceWindow;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${window.label} service window',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PrepStatusPill(
                  '${controller.blockedBatchCount} blocked',
                  color: controller.blockedBatchCount == 0
                      ? PrepTheme.success
                      : PrepTheme.warning,
                  icon: Icons.block_outlined,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PrepStatusPill(window.timeRange, icon: Icons.schedule),
                PrepStatusPill(
                  '${window.minutesRemaining} min to window',
                  color: PrepTheme.violet,
                  icon: Icons.timelapse,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const PulseBalanceButton(),
            const SizedBox(height: 12),
            Text(window.pressure),
          ],
        ),
      ),
    );
  }
}

class _PrimaryUpdateControl extends StatelessWidget {
  const _PrimaryUpdateControl({required this.controller});

  final PrepBoardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary update control',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: controller.selectedBatchId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Active batch'),
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
                onPressed: () => controller.saveState(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save ready state'),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Uses 10 prep credits.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                state_entry.StateEntryScreen.routeName,
              ),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Open full state entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestSavedState extends StatelessWidget {
  const _LatestSavedState({required this.log});

  final PrepLog log;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest saved batch state',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${log.batchName} is ${log.state} at ${log.station}.'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PrepStatusPill(
                  'Owner ${log.owner}',
                  icon: Icons.badge_outlined,
                ),
                PrepStatusPill(
                  'Saved ${log.savedAt}',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(log.note),
          ],
        ),
      ),
    );
  }
}

class _StationStatusCard extends StatelessWidget {
  const _StationStatusCard({
    required this.station,
    required this.batch,
    required this.selectedBatchId,
    required this.onSelect,
    required this.onResolve,
  });

  final StationStatus station;
  final PrepBatch batch;
  final String selectedBatchId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    final selected = batch.id == selectedBatchId;
    final statusColor = batch.blocked ? PrepTheme.error : PrepTheme.success;
    return Card(
      child: InkWell(
        onTap: () => onSelect(batch.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                    const PrepStatusPill(
                      'Selected',
                      icon: Icons.radio_button_checked,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${batch.id} ${batch.name}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PrepStatusPill(batch.state, color: statusColor),
                  PrepStatusPill(
                    'Owner ${batch.owner}',
                    icon: Icons.person_outline,
                  ),
                  PrepStatusPill('${batch.quantity} portions'),
                ],
              ),
              const SizedBox(height: 10),
              Text(batch.note),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      BatchDetailScreen.routeName,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open batch'),
                  ),
                  if (batch.blocked)
                    OutlinedButton.icon(
                      onPressed: () => onResolve(batch.id),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Resolve block'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

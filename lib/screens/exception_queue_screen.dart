import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart';
import '../widgets/status_widgets.dart';

// page_id source marker: exception-queue
// page_id: exception-queue | route_name: /exception-queue | widget_class: ExceptionQueueScreen | state_key: exceptionQueueState
class ExceptionQueueScreen extends StatelessWidget {
  const ExceptionQueueScreen({super.key});
  static const routeName = '/exception-queue';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final blocked = controller.batches.where((batch) => batch.blocked).toList();
    final late = controller.batches
        .where((batch) => !batch.blocked && batch.minutesToWindow <= 20)
        .toList();
    final unclear = controller.batches
        .where(
          (batch) =>
              !batch.blocked &&
              (batch.state == 'Waiting' ||
                  batch.note.toLowerCase().contains('requested')),
        )
        .toList();

    return OperationalPage(
      pageId: 'exception-queue',
      title: 'Exception Queue',
      children: [
        ConfirmationBanner(message: controller.visibleConfirmation),
        const SizedBox(height: 12),
        _QueueSummary(
          blocked: blocked.length,
          late: late.length,
          unclear: unclear.length,
        ),
        const SizedBox(height: 12),
        _ExceptionSection(
          title: 'Blocked prep batches',
          emptyMessage: 'No blocked prep batches.',
          statusLabel: 'blocked',
          icon: Icons.block_outlined,
          batches: blocked,
          controller: controller,
        ),
        const SizedBox(height: 12),
        _ExceptionSection(
          title: 'Late prep batches',
          emptyMessage: 'No late prep batches.',
          statusLabel: 'late',
          icon: Icons.schedule_outlined,
          batches: late,
          controller: controller,
        ),
        const SizedBox(height: 12),
        _ExceptionSection(
          title: 'Unclear prep batches',
          emptyMessage: 'No unclear prep batches.',
          statusLabel: 'unclear',
          icon: Icons.help_outline,
          batches: unclear,
          controller: controller,
        ),
      ],
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({
    required this.blocked,
    required this.late,
    required this.unclear,
  });

  final int blocked;
  final int late;
  final int unclear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exception queue readback',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PrepStatusPill('$blocked blocked', icon: Icons.block_outlined),
                PrepStatusPill('$late late', icon: Icons.schedule_outlined),
                PrepStatusPill('$unclear unclear', icon: Icons.help_outline),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Resolve controls clear blocked batches and keep late or unclear '
              'items visible for owner follow-up.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExceptionSection extends StatelessWidget {
  const _ExceptionSection({
    required this.title,
    required this.emptyMessage,
    required this.statusLabel,
    required this.icon,
    required this.batches,
    required this.controller,
  });

  final String title;
  final String emptyMessage;
  final String statusLabel;
  final IconData icon;
  final List<PrepBatch> batches;
  final PrepBoardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PrepStatusPill('${batches.length} open'),
              ],
            ),
            const SizedBox(height: 12),
            if (batches.isEmpty)
              Text(emptyMessage)
            else
              for (final batch in batches) ...[
                _ExceptionBatchCard(
                  batch: batch,
                  statusLabel: statusLabel,
                  onSelect: () => controller.selectBatch(batch.id),
                  onResolve: batch.blocked
                      ? () => controller.resolveBlocked(batch.id)
                      : null,
                ),
                if (batch != batches.last) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ExceptionBatchCard extends StatelessWidget {
  const _ExceptionBatchCard({
    required this.batch,
    required this.statusLabel,
    required this.onSelect,
    required this.onResolve,
  });

  final PrepBatch batch;
  final String statusLabel;
  final VoidCallback onSelect;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final blockedReason = batch.blocked
        ? batch.note
        : '${batch.minutesToWindow} min to ${batch.serviceWindow}; ${batch.note}';
    final followUp = batch.blocked
        ? '${batch.owner} clears blocker; ${batch.backup} stands by.'
        : '${batch.owner} confirms state; ${batch.backup} covers handoff.';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
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
                    '${batch.id} ${batch.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PrepStatusPill(statusLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text('Blocked reason: $blockedReason'),
            const SizedBox(height: 6),
            Text('Owner follow-up: $followUp'),
            const SizedBox(height: 6),
            Text(
              'Readback: ${batch.station} / ${batch.state} / '
              '${batch.quantity} portions.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Read back owner'),
                ),
                FilledButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.task_alt),
                  label: Text(
                    onResolve == null ? 'Follow-up pending' : 'Resolve block',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

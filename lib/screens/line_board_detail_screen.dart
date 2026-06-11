import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';
import '../state/prep_line_state.dart';
import '../theme/prep_theme.dart';
import '../widgets/media_widgets.dart';
import '../widgets/prep_widgets.dart';
import '../widgets/status_widgets.dart';
import 'batch_detail_screen.dart';

// page_id source marker: line-board_detail
// page_id: line-board_detail | route_name: /line-board-detail | widget_class: LineBoardDetailScreen | state_key: lineBoardDetailState
class LineBoardDetailScreen extends StatefulWidget {
  const LineBoardDetailScreen({super.key});
  static const routeName = '/line-board-detail';

  @override
  State<LineBoardDetailScreen> createState() => _LineBoardDetailScreenState();
}

class _LineBoardDetailScreenState extends State<LineBoardDetailScreen> {
  String _confirmation =
      'Capture context ready: line-board selection is waiting for batch-detail readback.';

  @override
  Widget build(BuildContext context) {
    final controller = PrepLineScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final batch = controller.selectedBatch;
        final lineMedia = controller.mediaFor('line-board');
        final batchMedia = controller.mediaFor('batch-detail');
        final latestLog = controller.latestLog;

        return PrepScaffold(
          contract: pageContracts[10],
          children: [
            InfoCard(
              title: 'Flow capture context',
              trailing: const StatusChip('line-board -> batch-detail'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Source: line-board selected ${batch.id} ${batch.name}.',
                    key: const Key('line-board-detail-source-readback'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Destination: batch-detail opens the same item for station, owner, media, and saved-state readback.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(batch.station),
                      StatusChip('Owner ${batch.owner}'),
                      StatusChip(batch.serviceWindow),
                      StatusChip('${batch.minutesToWindow} min'),
                    ],
                  ),
                ],
              ),
            ),
            _SelectedBatchCard(batch: batch),
            InfoCard(
              title: 'Capture action',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture ${batch.id} from the board, attach line and batch proof media, then continue into batch detail.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        key: const Key('line-board-detail-capture-button'),
                        onPressed: () {
                          controller.addMedia('line-board');
                          controller.addMedia('batch-detail');
                          setState(() {
                            _confirmation =
                                'Captured ${batch.id} from line-board into batch-detail with ${lineMedia.length + 1} board media and ${batchMedia.length + 1} batch media records.';
                          });
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Capture Item'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          BatchDetailScreen.routeName,
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Batch Detail'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ConfirmationBanner(message: _confirmation),
            const SizedBox(height: 12),
            InfoCard(
              title: 'Media and readback summary',
              trailing: StatusChip(
                '${lineMedia.length + batchMedia.length} media',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Readback: ${batch.id} ${batch.name} is ${batch.state} at ${batch.station}; latest saved log is ${latestLog.batchId} ${latestLog.state} at ${latestLog.savedAt}.',
                    key: const Key('line-board-detail-media-readback'),
                  ),
                  const SizedBox(height: 10),
                  _MediaSummaryRow(
                    label: 'Line board media',
                    media: lineMedia,
                    emptyText: 'No board media captured yet.',
                  ),
                  const SizedBox(height: 10),
                  _MediaSummaryRow(
                    label: 'Batch detail media',
                    media: batchMedia,
                    emptyText: 'No batch detail media captured yet.',
                  ),
                  if (batchMedia.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    PrepMediaPreview(record: batchMedia.first),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedBatchCard extends StatelessWidget {
  const _SelectedBatchCard({required this.batch});

  final PrepBatch batch;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Selected batch card',
      trailing: StatusChip(
        batch.blocked ? 'Blocked' : 'Selected',
        color: batch.blocked ? PrepTheme.error : PrepTheme.success,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${batch.id} ${batch.name}',
            key: const Key('line-board-detail-selected-batch'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          BatchSummary(batch: batch),
          const SizedBox(height: 10),
          Text('Station: ${batch.station}'),
          Text('Owner: ${batch.owner}; backup: ${batch.backup}.'),
          Text('Quantity: ${batch.quantity} portions.'),
          Text('Note: ${batch.note}'),
        ],
      ),
    );
  }
}

class _MediaSummaryRow extends StatelessWidget {
  const _MediaSummaryRow({
    required this.label,
    required this.media,
    required this.emptyText,
  });

  final String label;
  final List<MediaRecord> media;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final latest = media.isEmpty
        ? emptyText
        : '${media.last.id}: ${media.last.label}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip('$label ${media.length}'),
        const SizedBox(width: 10),
        Expanded(child: Text(latest)),
      ],
    );
  }
}

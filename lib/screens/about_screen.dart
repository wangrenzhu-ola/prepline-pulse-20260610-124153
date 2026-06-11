import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../state/prep_board_controller.dart';
import '../widgets/prep_widgets.dart';

// page_id source marker: about
// page_id: about | route_name: /about | widget_class: AboutScreen | state_key: aboutState
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  static const routeName = '/about';

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _exported = false;

  static const _rulesIncluded = [
    'Owner reads back blocker before handoff.',
    'Late-risk prep stays in the exception queue.',
    'Service-window exports include every active station.',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final exceptionCount = controller.blockedCount;
    final activeBatchCount = controller.batches.length;
    final rulesIncluded = _rulesIncluded.length;
    final serviceWindows = controller.batches
        .map((batch) => batch.serviceWindow)
        .toSet()
        .join(' + ');
    final blockedBatchCount =
        controller.batches.where((batch) => batch.blocked).length;
    final readback = _exported
        ? 'Exported/readback confirmed: $activeBatchCount batches, '
            '$exceptionCount exceptions, $rulesIncluded rules, '
            'service window $serviceWindows.'
        : 'Ready to export: preview includes exception count, rules included, '
            'and service window readback.';

    return PrepScaffold(
      contract: pageContracts[9],
      children: [
        Semantics(
          label: 'page_id source marker: about',
          child: const SizedBox.shrink(),
        ),
        InfoCard(
          title: 'Summary export preview',
          trailing: StatusChip(_exported ? 'exported' : 'preview'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PrepLine Pulse export covers $activeBatchCount active batches '
                'with $blockedBatchCount blocked item in exception review.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip('$exceptionCount exceptions'),
                  StatusChip('$rulesIncluded rules included'),
                  StatusChip('service window $serviceWindows'),
                ],
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'Rules included',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rule in _rulesIncluded)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_outlined),
                  title: Text(rule),
                ),
            ],
          ),
        ),
        InfoCard(
          title: 'Export action',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(readback, key: const Key('about-export-readback')),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('about-export-summary-button'),
                onPressed: () {
                  setState(() {
                    _exported = true;
                  });
                },
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Export summary'),
              ),
              if (_exported) ...[
                const SizedBox(height: 10),
                const Text(
                  'Visible exported/readback confirmation: flow-export-summary '
                  'has been generated for the prep lead.',
                ),
              ],
            ],
          ),
        ),
        const InfoCard(
          title: 'Support and legal',
          child: Text(
            'Support: shift lead operations desk. Legal: internal service '
            'readbacks are retained for cafe prep coordination.',
          ),
        ),
      ],
    );
  }
}

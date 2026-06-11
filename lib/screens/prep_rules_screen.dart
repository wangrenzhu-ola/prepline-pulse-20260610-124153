import 'package:flutter/material.dart';

import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart';

// page_id source marker: prep-rules
// page_id: prep-rules | route_name: /prep-rules | widget_class: PrepRulesScreen | state_key: prepRulesState
class PrepRulesScreen extends StatefulWidget {
  const PrepRulesScreen({super.key});
  static const routeName = '/prep-rules';

  @override
  State<PrepRulesScreen> createState() => _PrepRulesScreenState();
}

class _PrepRulesScreenState extends State<PrepRulesScreen> {
  late final TextEditingController _agreementController;
  String _readback = 'No agreement changes read back yet.';
  final Set<String> _activeRules = {
    'Save station state before any handoff.',
    'Owner confirms backup pan before rush window.',
    'Blocked batches stay visible until the owner clears them.',
  };

  static const List<String> _teamAgreements = [
    'Lead owns station default edits before service.',
    'Each owner reads back the next batch and backup level.',
    'Cold and hot stations keep blockers in the shared board.',
  ];

  static const List<String> _ruleList = [
    'Save station state before any handoff.',
    'Owner confirms backup pan before rush window.',
    'Blocked batches stay visible until the owner clears them.',
    'Late prep gets moved to the exception queue.',
  ];

  @override
  void initState() {
    super.initState();
    _agreementController = TextEditingController(text: _teamAgreements.first);
  }

  @override
  void dispose() {
    _agreementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final window = controller.serviceWindow;
    final selectedBatch = controller.selectedBatch;

    return OperationalPage(
      pageId: 'prep-rules',
      title: 'Prep Rules',
      children: [
        _RulesCard(
          title: 'Station defaults',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${window.label} ${window.timeRange} - '
                '${window.minutesRemaining} minutes remaining',
                key: const Key('prep-rules-service-window-default'),
              ),
              const SizedBox(height: 10),
              for (final station in controller.stations) ...[
                _StationDefaultRow(
                  station: station.station,
                  owner: station.owner,
                  backup: station.backup,
                  state: station.state,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RulesCard(
          title: 'Team agreements',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final agreement in _teamAgreements)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(agreement),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('prep-rules-edit-agreement-field'),
                controller: _agreementController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Edit agreement',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('prep-rules-save-agreement-button'),
                    onPressed: () {
                      setState(() {
                        _readback =
                            'Agreement saved for ${selectedBatch.station}: '
                            '${_agreementController.text}';
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save agreement'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('prep-rules-readback-button'),
                    onPressed: () {
                      setState(() {
                        _readback =
                            '${selectedBatch.id} ${selectedBatch.name} / '
                            '${selectedBatch.owner}: ${controller.visibleConfirmation}';
                      });
                    },
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: const Text('Read back'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RulesCard(
          title: 'Rule list',
          child: Column(
            children: [
              for (final rule in _ruleList)
                CheckboxListTile(
                  key: Key('prep-rules-rule-${rule.hashCode}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(rule),
                  subtitle: Text(
                    _activeRules.contains(rule)
                        ? 'Active for this service window'
                        : 'Review before service',
                  ),
                  value: _activeRules.contains(rule),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _activeRules.add(rule);
                      } else {
                        _activeRules.remove(rule);
                      }
                      _readback =
                          '${_activeRules.length} prep rules active for ${window.label}.';
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RulesCard(
          title: 'Agreement readback',
          child: Text(
            _readback,
            key: const Key('prep-rules-agreement-readback'),
          ),
        ),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard({required this.title, required this.child});

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

class _StationDefaultRow extends StatelessWidget {
  const _StationDefaultRow({
    required this.station,
    required this.owner,
    required this.backup,
    required this.state,
  });

  final String station;
  final String owner;
  final String backup;
  final String state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Owner: $owner'),
            Text('Backup default: $backup'),
            Text('Current state: $state'),
          ],
        ),
      ),
    );
  }
}

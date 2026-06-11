import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../services/prepline_purchase_service.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart' as operational;
import '../widgets/pulse_balance_button.dart';
import '../widgets/status_widgets.dart';

// page_id source marker: state-entry
// page_id: state-entry | route_name: /state-entry | widget_class: StateEntryScreen | state_key: stateEntryState
class StateEntryScreen extends StatefulWidget {
  const StateEntryScreen({super.key});
  static const routeName = '/state-entry';

  @override
  State<StateEntryScreen> createState() => _StateEntryScreenState();
}

class _StateEntryScreenState extends State<StateEntryScreen> {
  TextEditingController? _noteController;
  String? _selectedStation;
  String _selectedState = 'Ready for handoff';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = PrepBoardScope.of(context);
    _selectedStation ??= controller.selectedBatch.station;
    _selectedState = controller.selectedBatch.state;
    _noteController ??= TextEditingController(
      text: controller.selectedBatch.note,
    );
  }

  @override
  void dispose() {
    _noteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final selectedBatch = controller.selectedBatch;
    final PrepLog latestSavedState = controller.latestSavedState;
    final noteController = _noteController!;
    final stations = controller.batches
        .map((batch) => batch.station)
        .toSet()
        .toList(growable: false);
    final canSpend = controller.pulseCredits >= PulseWalletLedger.stateSaveCost;

    return operational.OperationalPage(
      pageId: 'state-entry',
      title: 'State Entry',
      children: [
        _EntryCard(
          title: 'Save station update',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('state-entry-batch-selector'),
                value: controller.selectedBatchId,
                decoration: const InputDecoration(labelText: 'Active batch'),
                items: [
                  for (final batch in controller.batches)
                    DropdownMenuItem(
                      value: batch.id,
                      child: Text('${batch.id} - ${batch.name}'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    controller.selectBatch(value);
                    _selectedStation = controller.selectedBatch.station;
                    _selectedState = controller.selectedBatch.state;
                    noteController.text = controller.selectedBatch.note;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('state-entry-station-selector'),
                value: _selectedStation,
                decoration: const InputDecoration(labelText: 'Station'),
                items: [
                  for (final station in stations)
                    DropdownMenuItem(value: station, child: Text(station)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedStation = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Readback: $_selectedStation for ${selectedBatch.id}',
                key: const Key('station-readback'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                key: const Key('state-entry-segmented-controls'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Waiting', label: Text('Waiting')),
                  ButtonSegment(value: 'Cooking', label: Text('Cooking')),
                  ButtonSegment(value: 'Ready', label: Text('Ready')),
                  ButtonSegment(value: 'Blocked', label: Text('Blocked')),
                ],
                selected: {_selectedState},
                onSelectionChanged: (values) {
                  setState(() => _selectedState = values.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('state-entry-note-field'),
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Handoff note',
                ),
              ),
              const SizedBox(height: 12),
              PrepCostNotice(
                key: const Key('state-entry-save-cost-notice'),
                cost: PulseWalletLedger.stateSaveCost,
                balance: controller.pulseCredits,
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: PulseBalanceButton(compact: true),
              ),
              const SizedBox(height: 8),
              Text(
                controller.saveScopeReadback,
                key: const Key('state-entry-save-scope-readback'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('state-entry-save-button'),
                  onPressed: canSpend
                      ? () {
                          setState(() {
                            controller.saveState(
                              station: _selectedStation,
                              nextState: _selectedState,
                              note: noteController.text,
                            );
                          });
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(controller.visibleConfirmation),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        }
                      : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    controller.hasProofPhoto
                        ? 'Save update with photo'
                        : 'Save update',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                controller.visibleConfirmation,
                key: const Key('saved-state-confirmation'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'Latest saved record',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${latestSavedState.savedAt} | '
                '${latestSavedState.batchId} | '
                '${latestSavedState.station} | '
                '${latestSavedState.state} | '
                '${latestSavedState.note} | '
                '${latestSavedState.hasProofImage ? 'Photo linked' : 'No photo'}',
                key: const Key('state-entry-log-readback'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension StateEntrySaveState on PrepBoardController {}

class OperationalPage extends operational.OperationalPage {
  const OperationalPage({
    required super.pageId,
    required super.title,
    required super.children,
    super.actions,
    super.key,
  });
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.title, required this.child});

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

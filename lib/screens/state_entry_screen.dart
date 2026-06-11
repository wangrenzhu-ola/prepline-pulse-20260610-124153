import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart' as operational;
import 'state_entry_detail_screen.dart';

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

    return operational.OperationalPage(
      pageId: 'state-entry',
      title: 'State Entry',
      children: [
        _EntryCard(
          title: 'Batch selector',
          child: DropdownButtonFormField<String>(
            key: const Key('state-entry-batch-selector'),
            initialValue: controller.selectedBatchId,
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
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'Station selector/readback',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('state-entry-station-selector'),
                initialValue: _selectedStation,
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'State segmented controls',
          child: SegmentedButton<String>(
            key: const Key('state-entry-segmented-controls'),
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
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'Note field',
          child: TextField(
            key: const Key('state-entry-note-field'),
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Add station handoff note',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('state-entry-save-button'),
          onPressed: () {
            setState(() {
              controller.saveState(nextState: _selectedState);
            });
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save state'),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'Saved-state confirmation',
          child: Text(
            controller.visibleConfirmation,
            key: const Key('saved-state-confirmation'),
          ),
        ),
        const SizedBox(height: 12),
        _EntryCard(
          title: 'Log readback',
          child: Text(
            '${latestSavedState.savedAt} | '
            '${latestSavedState.batchId} | '
            '${_selectedStation ?? latestSavedState.station} | '
            '${latestSavedState.state} | '
            '${noteController.text.isEmpty ? latestSavedState.note : noteController.text}',
            key: const Key('state-entry-log-readback'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, StateEntryDetailScreen.routeName),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Open saved-state detail'),
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

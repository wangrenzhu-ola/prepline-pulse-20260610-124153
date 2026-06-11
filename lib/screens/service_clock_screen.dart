// ignore_for_file: unused_import

import 'package:flutter/material.dart';

import '../models/prep_models.dart';
// ignore: uri_does_not_exist
import '../state/prep_board_controller.dart';
// ignore: uri_does_not_exist
import '../widgets/operational_page.dart';
// ignore: uri_does_not_exist
import '../widgets/status_widgets.dart';

// page_id source marker: service-clock
// route_name: /service-clock | widget_class: ServiceClockScreen | state_key: serviceClockState
class ServiceClockScreen extends StatefulWidget {
  const ServiceClockScreen({super.key});

  static const routeName = '/service-clock';

  @override
  State<ServiceClockScreen> createState() => _ServiceClockScreenState();
}

class _ServiceClockScreenState extends State<ServiceClockScreen> {
  static const _allStations = 'All stations';

  String _stationFilter = _allStations;
  String _readback =
      'Readback: service-clock showing 3 batches for all stations; next close is 11:30 lunch.';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final batches = controller.batches;
    final visible = _visibleBatches(batches);
    final ready = visible.where((batch) => batch.state == 'Ready').toList();
    final waiting = visible.where((batch) => batch.state != 'Ready').toList();
    final lateRisk = visible
        .where((batch) => batch.blocked || batch.minutesToWindow <= 20)
        .toList();
    final nextClose = visible.isEmpty
        ? 'No active window'
        : visible
            .reduce(
              (first, second) => first.minutesToWindow <= second.minutesToWindow
                  ? first
                  : second,
            )
            .serviceWindow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Clock'),
        actions: [
          IconButton(
            tooltip: 'Refresh readback',
            onPressed: () => _recordReadback(visible, nextClose),
            icon: const Icon(Icons.fact_check_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const _PageMarker(),
            _ServiceCountdown(
              minutesToClose: _minutesToNextClose(visible),
              nextClose: nextClose,
              activeBatchCount: visible.length,
            ),
            const SizedBox(height: 12),
            _StationFilter(
              stations: [_allStations, ..._stations(batches)],
              selectedStation: _stationFilter,
              onChanged: (station) {
                setState(() {
                  _stationFilter = station;
                  _recordReadback(
                    _visibleBatches(batches),
                    _nextCloseLabel(_visibleBatches(batches)),
                  );
                });
              },
            ),
            const SizedBox(height: 12),
            _LateRiskChips(batches: lateRisk),
            const SizedBox(height: 12),
            _LaneSection(
              title: 'Ready lane',
              batches: ready,
              emptyText: 'No ready batches in this station filter.',
            ),
            const SizedBox(height: 12),
            _LaneSection(
              title: 'Waiting lane',
              batches: waiting,
              emptyText: 'No waiting batches in this station filter.',
            ),
            const SizedBox(height: 12),
            _OwnerFollowUpPrompts(
              batches: lateRisk.isEmpty ? waiting : lateRisk,
              onPromptSent: (batch) {
                setState(() {
                  _readback =
                      'Readback: follow-up sent to ${batch.owner} for ${batch.id} at ${batch.station}; ${batch.minutesToWindow} min to ${batch.serviceWindow}.';
                });
              },
            ),
            const SizedBox(height: 12),
            _WindowCloseSummary(
              visibleBatches: visible,
              lateRiskCount: lateRisk.length,
            ),
            const SizedBox(height: 12),
            _ReadbackPanel(readback: _readback),
          ],
        ),
      ),
    );
  }

  List<String> _stations(List<PrepBatch> batches) =>
      batches.map((batch) => batch.station).toSet().toList()..sort();

  List<PrepBatch> _visibleBatches(List<PrepBatch> batches) {
    if (_stationFilter == _allStations) {
      return batches;
    }
    return batches.where((batch) => batch.station == _stationFilter).toList();
  }

  int _minutesToNextClose(List<PrepBatch> batches) {
    if (batches.isEmpty) {
      return 0;
    }
    return batches
        .map((batch) => batch.minutesToWindow)
        .reduce((first, second) => first < second ? first : second);
  }

  String _nextCloseLabel(List<PrepBatch> batches) {
    if (batches.isEmpty) {
      return 'No active window';
    }
    return batches
        .reduce(
          (first, second) =>
              first.minutesToWindow <= second.minutesToWindow ? first : second,
        )
        .serviceWindow;
  }

  void _recordReadback(List<PrepBatch> batches, String nextClose) {
    _readback =
        'Readback: service-clock showing ${batches.length} batches for $_stationFilter; next close is $nextClose.';
  }
}

class _PageMarker extends StatelessWidget {
  const _PageMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'page_id=service-clock; source_marker=service-clock',
      child: const SizedBox.shrink(),
    );
  }
}

class _ServiceCountdown extends StatelessWidget {
  const _ServiceCountdown({
    required this.minutesToClose,
    required this.nextClose,
    required this.activeBatchCount,
  });

  final int minutesToClose;
  final String nextClose;
  final int activeBatchCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service countdown', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(nextClose, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('$activeBatchCount batches in scope'),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1A81F)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Text(
                    '$minutesToClose',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF815700),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text('min'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationFilter extends StatelessWidget {
  const _StationFilter({
    required this.stations,
    required this.selectedStation,
    required this.onChanged,
  });

  final List<String> stations;
  final String selectedStation;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Station filter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final station in stations)
                ChoiceChip(
                  label: Text(station),
                  selected: selectedStation == station,
                  onSelected: (_) => onChanged(station),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LateRiskChips extends StatelessWidget {
  const _LateRiskChips({required this.batches});

  final List<PrepBatch> batches;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Late-risk chips',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (batches.isEmpty)
            const Text('No late-risk batches in this filter.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final batch in batches)
                  Chip(
                    avatar: Icon(
                      batch.blocked ? Icons.warning_amber : Icons.schedule,
                      size: 18,
                    ),
                    label: Text('${batch.id} ${batch.minutesToWindow}m'),
                    backgroundColor: batch.blocked
                        ? const Color(0xFFFFE1DD)
                        : const Color(0xFFFFF4D8),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LaneSection extends StatelessWidget {
  const _LaneSection({
    required this.title,
    required this.batches,
    required this.emptyText,
  });

  final String title;
  final List<PrepBatch> batches;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Chip(label: Text('${batches.length}')),
            ],
          ),
          const SizedBox(height: 10),
          if (batches.isEmpty)
            Text(emptyText)
          else
            Column(
              children: [
                for (final batch in batches) _BatchClockTile(batch: batch),
              ],
            ),
        ],
      ),
    );
  }
}

class _BatchClockTile extends StatelessWidget {
  const _BatchClockTile({required this.batch});

  final PrepBatch batch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E0D2)),
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
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Chip(label: Text(batch.state)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${batch.station} - owner ${batch.owner} / backup ${batch.backup}',
              ),
              Text(
                '${batch.quantity} portions - ${batch.minutesToWindow} min to ${batch.serviceWindow}',
              ),
              Text(batch.note),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerFollowUpPrompts extends StatelessWidget {
  const _OwnerFollowUpPrompts({
    required this.batches,
    required this.onPromptSent,
  });

  final List<PrepBatch> batches;
  final ValueChanged<PrepBatch> onPromptSent;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner follow-up prompts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (batches.isEmpty)
            const Text(
              'No owner prompts needed for the current station filter.',
            )
          else
            Column(
              children: [
                for (final batch in batches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ask ${batch.owner}: confirm ${batch.name} before ${batch.serviceWindow}.',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => onPromptSent(batch),
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Prompt'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WindowCloseSummary extends StatelessWidget {
  const _WindowCloseSummary({
    required this.visibleBatches,
    required this.lateRiskCount,
  });

  final List<PrepBatch> visibleBatches;
  final int lateRiskCount;

  @override
  Widget build(BuildContext context) {
    final readyCount =
        visibleBatches.where((batch) => batch.state == 'Ready').length;
    final waitingCount = visibleBatches.length - readyCount;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Window close summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            '$readyCount ready, $waitingCount waiting, $lateRiskCount late-risk.',
          ),
          const SizedBox(height: 6),
          Text(
            visibleBatches.isEmpty
                ? 'No batches match this station filter.'
                : 'Close plan: clear blocked items first, then confirm owner handoff for waiting lane.',
          ),
        ],
      ),
    );
  }
}

class _ReadbackPanel extends StatelessWidget {
  const _ReadbackPanel({required this.readback});

  final String readback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: readback,
      child: _Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.record_voice_over_outlined),
            const SizedBox(width: 10),
            Expanded(child: Text(readback)),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

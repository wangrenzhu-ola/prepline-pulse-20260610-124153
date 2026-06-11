import 'package:flutter/material.dart';

import '../data/prep_repository.dart';
import '../models/prep_models.dart';

class PrepBoardController extends ChangeNotifier {
  PrepBoardController({PrepRepository repository = const PrepRepository()})
      : _snapshot = repository.loadLineBoard(),
        _batches = List<PrepBatch>.from(repository.loadLineBoard().batches),
        _stations = List<StationStatus>.from(repository.loadLineBoard().stations);

  final LineBoardSnapshot _snapshot;
  final List<PrepBatch> _batches;
  final List<StationStatus> _stations;
  late PrepLog _latestSavedState = _snapshot.latestSavedState;

  String selectedBatchId = 'B-104';
  String visibleConfirmation = 'Ready for first station update.';

  String get pageId => _snapshot.pageId;
  ServiceWindow get serviceWindow => _snapshot.serviceWindow;
  List<StationStatus> get stations => List.unmodifiable(_stations);
  List<PrepBatch> get batches => List.unmodifiable(_batches);
  PrepLog get latestSavedState => _latestSavedState;
  MediaRecord get media => _snapshot.media;
  int get blockedBatchCount => _batches.where((batch) => batch.blocked).length;

  PrepBatch get selectedBatch =>
      _batches.firstWhere((batch) => batch.id == selectedBatchId);

  void selectBatch(String batchId) {
    if (selectedBatchId == batchId) {
      return;
    }
    selectedBatchId = batchId;
    final batch = selectedBatch;
    visibleConfirmation =
        'Selected ${batch.id} at ${batch.station}; owner ${batch.owner}.';
    notifyListeners();
  }

  void saveState({String nextState = 'Ready for handoff'}) {
    final index = _batches.indexWhere((batch) => batch.id == selectedBatchId);
    if (index == -1) {
      return;
    }
    final current = _batches[index];
    final updated = current.copyWith(
      state: nextState,
      blocked: false,
      note: 'Saved from Line Board primary update.',
    );
    _batches[index] = updated;
    final stationIndex =
        _stations.indexWhere((station) => station.activeBatchId == updated.id);
    if (stationIndex != -1) {
      _stations[stationIndex] = _stations[stationIndex].copyWith(
        state: nextState,
        blocked: false,
      );
    }
    _latestSavedState = PrepLog(
      batchId: updated.id,
      batchName: updated.name,
      station: updated.station,
      state: updated.state,
      owner: updated.owner,
      note: updated.note,
      savedAt: _clockLabel(),
    );
    visibleConfirmation =
        'Saved ${updated.id} as ${updated.state} at ${_latestSavedState.savedAt}.';
    notifyListeners();
  }

  void resolveBlocked(String batchId) {
    final index = _batches.indexWhere((batch) => batch.id == batchId);
    if (index == -1) {
      return;
    }
    final current = _batches[index];
    _batches[index] = current.copyWith(
      state: 'Ready',
      blocked: false,
      note: 'Blocker cleared by owner.',
    );
    final stationIndex =
        _stations.indexWhere((station) => station.activeBatchId == batchId);
    if (stationIndex != -1) {
      _stations[stationIndex] = _stations[stationIndex].copyWith(
        state: 'Ready',
        blocked: false,
      );
    }
    selectedBatchId = batchId;
    visibleConfirmation = 'Resolved blocked batch $batchId.';
    notifyListeners();
  }

  String _clockLabel() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class PrepBoardScope extends InheritedNotifier<PrepBoardController> {
  const PrepBoardScope({
    required PrepBoardController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PrepBoardController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PrepBoardScope>();
    assert(scope != null, 'PrepBoardScope missing from widget tree');
    return scope!.notifier!;
  }
}

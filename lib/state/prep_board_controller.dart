import 'package:flutter/material.dart';

import '../data/prep_repository.dart';
import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';

class PrepBoardController extends ChangeNotifier {
  PrepBoardController({PrepRepository repository = const PrepRepository()}) {
    _snapshot = repository.loadLineBoard();
    _batches = List<PrepBatch>.from(_snapshot.batches);
    _stations = List<StationStatus>.from(_snapshot.stations);
    _logs = List<PrepLog>.from(seedLogs);
    _exceptions = List<PrepException>.from(seedExceptions);
    _media = [
      const MediaRecord(
        id: 'M-hero',
        assetPath: heroAsset,
        label: 'Opening station photo',
        attachedTo: 'line-board',
      ),
      const MediaRecord(
        id: 'M-batch',
        assetPath: batchAsset,
        label: 'Batch proof photo',
        attachedTo: 'batch-detail',
      ),
      const MediaRecord(
        id: 'M-timeline',
        assetPath: heroAsset,
        label: 'Timeline handoff photo',
        attachedTo: 'station-timeline',
      ),
    ];
    _latestSavedState = _logs.last;
  }

  late final LineBoardSnapshot _snapshot;
  late final List<PrepBatch> _batches;
  late final List<StationStatus> _stations;
  late final List<PrepLog> _logs;
  late final List<PrepException> _exceptions;
  late final List<MediaRecord> _media;
  late PrepLog _latestSavedState;

  String selectedBatchId = 'B-104';
  String visibleConfirmation = 'Ready for first station update.';
  String? lastConfirmation;
  String? lastResolvedException;

  String get pageId => _snapshot.pageId;
  ServiceWindow get serviceWindow => _snapshot.serviceWindow;
  List<StationStatus> get stations => List.unmodifiable(_stations);
  List<PrepBatch> get batches => List.unmodifiable(_batches);
  List<PrepLog> get logs => List.unmodifiable(_logs);
  List<PrepException> get exceptions => List.unmodifiable(_exceptions);
  List<MediaRecord> get mediaRecords => List.unmodifiable(_media);
  PrepLog get latestSavedState => _latestSavedState;
  PrepLog get latestLog => _latestSavedState;
  MediaRecord get media {
    final lineBoardMedia = mediaFor('line-board');
    return lineBoardMedia.isEmpty ? _snapshot.media : lineBoardMedia.first;
  }

  int get blockedBatchCount => _batches.where((batch) => batch.blocked).length;
  int get blockedCount => _exceptions.where((item) => !item.resolved).length;

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

  void saveState({
    String? station,
    String nextState = 'Ready for handoff',
    String? note,
  }) {
    final index = _batches.indexWhere((batch) => batch.id == selectedBatchId);
    if (index == -1) {
      return;
    }
    final current = _batches[index];
    final savedStation = station ?? current.station;
    final savedNote =
        note?.trim().isNotEmpty ?? false ? note!.trim() : current.note;
    final blocked = nextState == 'Blocked';
    final updated = current.copyWith(
      station: savedStation,
      state: nextState,
      blocked: blocked,
      note: savedNote,
    );
    _batches[index] = updated;
    final stationIndex =
        _stations.indexWhere((station) => station.activeBatchId == updated.id);
    if (stationIndex != -1) {
      _stations[stationIndex] = _stations[stationIndex].copyWith(
        state: nextState,
        blocked: blocked,
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
    _logs.add(_latestSavedState);
    _syncExceptionForSavedState(updated);
    visibleConfirmation =
        'Saved ${updated.id} as ${updated.state} at ${_latestSavedState.savedAt}.';
    lastConfirmation = visibleConfirmation;
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
    _resolveExceptionForBatch(batchId);
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
    _latestSavedState = PrepLog(
      batchId: _batches[index].id,
      batchName: _batches[index].name,
      station: _batches[index].station,
      state: _batches[index].state,
      owner: _batches[index].owner,
      note: _batches[index].note,
      savedAt: _clockLabel(),
    );
    _logs.add(_latestSavedState);
    notifyListeners();
  }

  List<PrepLog> historyForSelectedBatch() {
    return _logs
        .where((log) => log.batchId == selectedBatchId)
        .toList()
        .reversed
        .toList();
  }

  PrepException? openExceptionForSelectedBatch() {
    for (final exception in _exceptions) {
      if (exception.batchId == selectedBatchId && !exception.resolved) {
        return exception;
      }
    }
    return null;
  }

  List<MediaRecord> mediaFor(String attachedTo) =>
      _media.where((media) => media.attachedTo == attachedTo).toList();

  void addMedia(String attachedTo) {
    final isBatch = attachedTo == 'batch-detail';
    _media.add(
      MediaRecord(
        id: 'M-${_media.length + 1}',
        assetPath: isBatch ? batchAsset : heroAsset,
        label: isBatch ? 'Added batch proof photo' : 'Added station media',
        attachedTo: attachedTo,
      ),
    );
    notifyListeners();
  }

  void replaceMedia(String mediaId) {
    final index = _media.indexWhere((media) => media.id == mediaId);
    if (index == -1) {
      return;
    }
    final existing = _media[index];
    _media[index] = MediaRecord(
      id: existing.id,
      assetPath: existing.assetPath == heroAsset ? batchAsset : heroAsset,
      label: '${existing.label} replaced',
      attachedTo: existing.attachedTo,
    );
    notifyListeners();
  }

  void deleteMedia(String mediaId) {
    _media.removeWhere((media) => media.id == mediaId);
    notifyListeners();
  }

  void _syncExceptionForSavedState(PrepBatch batch) {
    final exceptionIndex = _exceptions.indexWhere(
      (exception) => exception.batchId == batch.id && !exception.resolved,
    );
    if (batch.blocked) {
      if (exceptionIndex == -1) {
        _exceptions.add(
          PrepException(
            id: 'EX-${_exceptions.length + 1}',
            batchId: batch.id,
            reason: batch.note,
            owner: batch.owner,
            resolved: false,
          ),
        );
      }
      return;
    }
    _resolveExceptionForBatch(batch.id);
  }

  void _resolveExceptionForBatch(String batchId) {
    final index = _exceptions.indexWhere(
      (exception) => exception.batchId == batchId && !exception.resolved,
    );
    if (index == -1) {
      return;
    }
    _exceptions[index] = _exceptions[index].resolve();
    lastResolvedException = 'Resolved $batchId exception';
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

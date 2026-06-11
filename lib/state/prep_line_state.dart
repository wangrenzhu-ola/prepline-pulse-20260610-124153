import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';

class PrepLineController extends ChangeNotifier {
  final List<PrepBatch> _batches = List<PrepBatch>.from(seedBatches);
  final List<PrepLog> _logs = List<PrepLog>.from(seedLogs);
  final List<PrepException> _exceptions = List<PrepException>.from(seedExceptions);
  final List<MediaRecord> _media = [
    const MediaRecord(id: 'M-hero', assetPath: heroAsset, label: 'Opening station photo', attachedTo: 'line-board'),
    const MediaRecord(id: 'M-batch', assetPath: batchAsset, label: 'Batch proof photo', attachedTo: 'batch-detail'),
    const MediaRecord(id: 'M-timeline', assetPath: heroAsset, label: 'Timeline handoff photo', attachedTo: 'station-timeline'),
  ];

  String selectedBatchId = seedBatches.first.id;
  String selectedStation = seedBatches.first.station;
  String selectedState = 'Ready';
  String draftNote = 'Oven temp checked and ready for handoff.';
  String? lastConfirmation;
  String? lastResolvedException;

  List<PrepBatch> get batches => List.unmodifiable(_batches);
  List<PrepLog> get logs => List.unmodifiable(_logs);
  List<PrepException> get exceptions => List.unmodifiable(_exceptions);
  List<MediaRecord> get media => List.unmodifiable(_media);

  PrepBatch get selectedBatch =>
      _batches.firstWhere((batch) => batch.id == selectedBatchId);

  int get blockedCount => _exceptions.where((item) => !item.resolved).length;
  PrepLog get latestLog => _logs.last;

  void selectBatch(String batchId) {
    selectedBatchId = batchId;
    final batch = selectedBatch;
    selectedStation = batch.station;
    selectedState = batch.state == 'Blocked' ? 'Ready' : batch.state;
    notifyListeners();
  }

  void selectStation(String station) {
    selectedStation = station;
    notifyListeners();
  }

  void selectState(String state) {
    selectedState = state;
    notifyListeners();
  }

  void setDraftNote(String note) {
    draftNote = note;
  }

  void saveCurrentState() {
    final index = _batches.indexWhere((batch) => batch.id == selectedBatchId);
    final current = _batches[index];
    final updated = current.copyWith(
      station: selectedStation,
      state: selectedState,
      note: draftNote,
      blocked: selectedState == 'Blocked',
    );
    _batches[index] = updated;
    final savedAt = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    _logs.add(PrepLog(
      batchId: updated.id,
      batchName: updated.name,
      station: updated.station,
      state: updated.state,
      owner: updated.owner,
      note: draftNote,
      savedAt: savedAt,
    ));
    lastConfirmation = 'Saved ${updated.id} as ${updated.state} at $savedAt';
    notifyListeners();
  }

  void resolveException(String exceptionId) {
    final index = _exceptions.indexWhere((item) => item.id == exceptionId);
    if (index == -1) {
      return;
    }
    _exceptions[index] = _exceptions[index].resolve();
    lastResolvedException = 'Resolved ${_exceptions[index].batchId} exception';
    _logs.add(PrepLog(
      batchId: _exceptions[index].batchId,
      batchName: _batches
          .firstWhere((batch) => batch.id == _exceptions[index].batchId)
          .name,
      station: selectedStation,
      state: 'Resolved',
      owner: _exceptions[index].owner,
      note: _exceptions[index].reason,
      savedAt: 'now',
    ));
    notifyListeners();
  }

  void addMedia(String attachedTo) {
    final isBatch = attachedTo == 'batch-detail';
    _media.add(MediaRecord(
      id: 'M-${_media.length + 1}',
      assetPath: isBatch ? batchAsset : heroAsset,
      label: isBatch ? 'Added batch proof photo' : 'Added station media',
      attachedTo: attachedTo,
    ));
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

  List<MediaRecord> mediaFor(String attachedTo) =>
      _media.where((media) => media.attachedTo == attachedTo).toList();
}

class PrepLineScope extends InheritedNotifier<PrepLineController> {
  const PrepLineScope({
    required PrepLineController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PrepLineController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PrepLineScope>();
    assert(scope != null, 'PrepLineScope missing from widget tree');
    return scope!.notifier!;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../data/prep_repository.dart';
import '../data/prep_seed_data.dart';
import '../models/prep_models.dart';
import '../models/pulse_store_models.dart';
import '../services/prepline_document_media_store.dart';
import '../services/prepline_permission_service.dart';
import '../services/prepline_purchase_service.dart';
import '../services/prepline_state_store.dart';

class PrepBoardController extends ChangeNotifier {
  PrepBoardController({
    PrepRepository repository = const PrepRepository(),
    PreplineDocumentMediaStore? mediaStore,
    PreplinePermissionService? permissionService,
    PreplineStateStore? stateStore,
    PulseWalletLedger? walletLedger,
    PreplinePurchaseService? purchaseService,
    ImagePicker? imagePicker,
  })  : _mediaStore = mediaStore ?? PreplineDocumentMediaStore(),
        _permissionService = permissionService ?? PreplinePermissionService(),
        _stateStore = stateStore ?? PreplineStateStore(),
        _walletLedger = walletLedger ?? PulseWalletLedger(),
        _purchaseService = purchaseService,
        _imagePicker = imagePicker ?? ImagePicker() {
    _snapshot = repository.loadLineBoard();
    _batches = List<PrepBatch>.from(_snapshot.batches);
    _stations = List<StationStatus>.from(_snapshot.stations);
    _logs = List<PrepLog>.from(seedLogs);
    _exceptions = List<PrepException>.from(seedExceptions);
    _media = [];
    _latestSavedState = _logs.last;
    _restoreFuture = _loadSavedSession();
    _pulseCreditsFuture = _loadPulseCredits();
  }

  final PreplineDocumentMediaStore _mediaStore;
  final PreplinePermissionService _permissionService;
  final PreplineStateStore _stateStore;
  final PulseWalletLedger _walletLedger;
  PreplinePurchaseService? _purchaseService;
  final ImagePicker _imagePicker;
  late final LineBoardSnapshot _snapshot;
  late final List<PrepBatch> _batches;
  late final List<StationStatus> _stations;
  late final List<PrepLog> _logs;
  late final List<PrepException> _exceptions;
  late final List<MediaRecord> _media;
  late PrepLog _latestSavedState;
  late final Future<void> _restoreFuture;
  late final Future<void> _pulseCreditsFuture;
  Future<void>? _pendingPersistence;

  String selectedBatchId = 'B-104';
  String visibleConfirmation = 'Ready for first station update.';
  String? lastConfirmation;
  String? lastResolvedException;
  String? mediaReadback;
  String? activeAlbumExportMediaId;
  String? storeReadback;
  String? activePurchaseProductId;
  int pulseCredits = PulseWalletLedger.initialBalance;

  String get pageId => _snapshot.pageId;
  ServiceWindow get serviceWindow => _snapshot.serviceWindow;
  List<StationStatus> get stations => List.unmodifiable(_stations);
  List<PrepBatch> get batches => List.unmodifiable(_batches);
  List<PrepLog> get logs => List.unmodifiable(_logs);
  List<PrepException> get exceptions => List.unmodifiable(_exceptions);
  List<MediaRecord> get mediaRecords => List.unmodifiable(_media);
  PrepLog get latestSavedState => _latestSavedState;
  PrepLog get latestLog => _latestSavedState;
  bool get hasProofPhoto => primaryUserMediaFor('line-board') != null;
  MediaRecord get media {
    final lineBoardMedia = mediaFor('line-board');
    return lineBoardMedia.isEmpty ? _snapshot.media : lineBoardMedia.first;
  }

  int get blockedBatchCount => _batches.where((batch) => batch.blocked).length;
  int get blockedCount => _exceptions.where((item) => !item.resolved).length;
  bool get storeBusy => activePurchaseProductId != null;
  Future<void> get ready => Future.wait([_restoreFuture, _pulseCreditsFuture]);

  String get saveScopeReadback {
    if (hasProofPhoto) {
      return 'Saves batch, station, note, and proof photo to local records.';
    }
    return 'Upload a proof photo first to include it in the saved record.';
  }

  String get primarySaveActionLabel =>
      hasProofPhoto ? 'Save ready with photo' : 'Save ready';

  PrepBatch get selectedBatch =>
      _batches.firstWhere((batch) => batch.id == selectedBatchId);

  static const _proofTargets = <String>[
    'line-board',
    'batch-detail',
    'station-timeline',
  ];

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

  bool saveState({
    String? station,
    String nextState = 'Ready for handoff',
    String? note,
  }) {
    if (pulseCredits < PulseWalletLedger.stateSaveCost) {
      visibleConfirmation =
          'Need ${PulseWalletLedger.stateSaveCost} prep credits to save this update.';
      storeReadback = 'Balance is too low for state save.';
      notifyListeners();
      return false;
    }
    final index = _batches.indexWhere((batch) => batch.id == selectedBatchId);
    if (index == -1) {
      return false;
    }
    pulseCredits -= PulseWalletLedger.stateSaveCost;
    _walletLedger.writeBalance(pulseCredits);
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
      proofImagePath: _currentProofImagePath(),
    );
    _logs.add(_latestSavedState);
    _syncExceptionForSavedState(updated);
    visibleConfirmation =
        'Saved ${updated.id} as ${updated.state} at ${_latestSavedState.savedAt}. ${_latestSavedState.hasProofImage ? 'Proof photo attached.' : 'No proof photo attached.'} ${PulseWalletLedger.stateSaveCost} credits used.';
    lastConfirmation = visibleConfirmation;
    _queueSessionPersistence();
    notifyListeners();
    return true;
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
      proofImagePath: _currentProofImagePath(),
    );
    _logs.add(_latestSavedState);
    _queueSessionPersistence();
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

  MediaRecord? primaryUserMediaFor(String attachedTo) {
    for (final media in mediaFor(attachedTo)) {
      if (media.storedInDocuments) {
        return media;
      }
    }
    return null;
  }

  void addMedia(String attachedTo) {
    mediaReadback = 'Use Upload photo to attach an album image.';
    notifyListeners();
  }

  Future<void> uploadMedia(String attachedTo) async {
    final allowed = await _permissionService.requestPhotoLibraryRead();
    if (!allowed) {
      mediaReadback =
          'Photo access is unavailable. Upload is needed for the large image.';
      notifyListeners();
      return;
    }
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (picked == null) {
      mediaReadback = 'Image upload cancelled.';
      notifyListeners();
      return;
    }
    final extension = path.extension(picked.name).isEmpty
        ? 'jpg'
        : path.extension(picked.name).replaceAll('.', '');
    final relativePath = await _mediaStore.saveBytes(
      bytes: await picked.readAsBytes(),
      folder: 'station_images',
      extension: extension,
    );
    final uploadId = DateTime.now().microsecondsSinceEpoch;
    if (_proofTargets.contains(attachedTo)) {
      final oldPaths = _media
          .where((media) =>
              media.storedInDocuments &&
              _proofTargets.contains(media.attachedTo))
          .map((media) => media.assetPath)
          .toSet();
      _media.removeWhere((media) =>
          media.storedInDocuments && _proofTargets.contains(media.attachedTo));
      for (final target in _proofTargets.reversed) {
        _media.insert(
          0,
          MediaRecord(
            id: 'M-$uploadId-$target',
            assetPath: relativePath,
            label: 'Uploaded proof photo',
            attachedTo: target,
            storedInDocuments: true,
          ),
        );
      }
      final savedProofPaths = _savedProofPaths();
      for (final oldPath in oldPaths) {
        if (oldPath != relativePath && !savedProofPaths.contains(oldPath)) {
          unawaited(_mediaStore.deleteRelativePath(oldPath));
        }
      }
      mediaReadback = 'Photo set on Board, Batch, and Photos.';
    } else {
      _media.insert(
        0,
        MediaRecord(
          id: 'M-$uploadId',
          assetPath: relativePath,
          label: 'Uploaded proof photo',
          attachedTo: attachedTo,
          storedInDocuments: true,
        ),
      );
      mediaReadback = 'Photo uploaded.';
    }
    _queueSessionPersistence();
    notifyListeners();
  }

  Future<bool> exportProofCardToAlbum(String mediaId) async {
    final media = _media.firstWhere((item) => item.id == mediaId);
    if (!media.storedInDocuments) {
      mediaReadback = 'Built-in proof images cannot create proof cards.';
      notifyListeners();
      return false;
    }
    activeAlbumExportMediaId = mediaId;
    mediaReadback = 'Creating proof card for Photos...';
    notifyListeners();
    try {
      final allowed = await _permissionService.requestPhotoLibraryWrite();
      if (!allowed) {
        mediaReadback =
            'Photos export permission is unavailable. The proof record remains in this app.';
        return false;
      }
      final batch = selectedBatch;
      await _mediaStore.exportProofCardToGallery(
        photoRelativePath: media.assetPath,
        batchId: batch.id,
        batchName: batch.name,
        station: batch.station,
        state: batch.state,
        owner: batch.owner,
        note: batch.note,
        exportedAt: _clockLabel(),
      );
      mediaReadback = 'Exported proof card to Photos album: PrepLine Pulse.';
      return true;
    } catch (_) {
      mediaReadback =
          'Could not export proof card. The proof record remains in this app.';
      return false;
    } finally {
      activeAlbumExportMediaId = null;
      notifyListeners();
    }
  }

  void replaceMedia(String mediaId) {
    mediaReadback = 'Use Upload photo to replace the proof image.';
    notifyListeners();
  }

  void deleteMedia(String mediaId) {
    final existing = _media.where((media) => media.id == mediaId).toList();
    final storedPaths = existing
        .where((media) => media.storedInDocuments)
        .map((media) => media.assetPath)
        .toSet();
    final savedProofPaths = _savedProofPaths();
    for (final relativePath in storedPaths) {
      if (!savedProofPaths.contains(relativePath)) {
        unawaited(_mediaStore.deleteRelativePath(relativePath));
      }
    }
    _media.removeWhere((media) =>
        media.id == mediaId ||
        (media.storedInDocuments && storedPaths.contains(media.assetPath)));
    mediaReadback = 'Photo removed.';
    _queueSessionPersistence();
    notifyListeners();
  }

  Future<void> purchasePulseProduct(PulseStoreProduct product) async {
    activePurchaseProductId = product.id;
    storeReadback = 'Preparing ${product.id}.';
    notifyListeners();
    final purchaseService = _purchaseService ??=
        PreplinePurchaseService(walletLedger: _walletLedger);
    final result = await purchaseService.buyProduct(product);
    if (result.balance != null) {
      pulseCredits = result.balance!;
    } else {
      pulseCredits = await _walletLedger.readBalance();
    }
    activePurchaseProductId = null;
    storeReadback = result.message;
    notifyListeners();
  }

  Future<void> addTestPurchaseDelivery({
    required String deliveryKey,
    required int amount,
  }) async {
    pulseCredits = await _walletLedger.addPurchaseOnce(
      deliveryKey: deliveryKey,
      amount: amount,
    );
    notifyListeners();
  }

  Future<String> fullMediaPath(MediaRecord media) async {
    final file = await _mediaStore.rebuildFile(media.assetPath);
    return file.path;
  }

  Future<void> _loadPulseCredits() async {
    pulseCredits = await _walletLedger.readBalance();
    notifyListeners();
  }

  Future<void> waitForPendingPersistence() async {
    await _pendingPersistence;
  }

  Future<void> _loadSavedSession() async {
    final session = await _stateStore.readSession();
    if (session == null) {
      return;
    }
    _batches
      ..clear()
      ..addAll(session.batches);
    _stations
      ..clear()
      ..addAll(session.stations);
    _logs
      ..clear()
      ..addAll(session.logs);
    _exceptions
      ..clear()
      ..addAll(session.exceptions);
    _media
      ..clear()
      ..addAll(session.media);
    selectedBatchId = session.selectedBatchId;
    final restoredLog = session.latestLog;
    if (restoredLog != null) {
      _latestSavedState = restoredLog;
      visibleConfirmation =
          'Restored ${restoredLog.batchId} ${restoredLog.state} from local records.';
      lastConfirmation = visibleConfirmation;
    }
    notifyListeners();
  }

  void _queueSessionPersistence() {
    _pendingPersistence = _stateStore.writeSession(
      selectedBatchId: selectedBatchId,
      batches: List<PrepBatch>.from(_batches),
      stations: List<StationStatus>.from(_stations),
      logs: List<PrepLog>.from(_logs),
      exceptions: List<PrepException>.from(_exceptions),
      media: List<MediaRecord>.from(_media),
    );
    unawaited(_pendingPersistence);
  }

  String? _currentProofImagePath() {
    return primaryUserMediaFor('line-board')?.assetPath;
  }

  Set<String> _savedProofPaths() {
    return _logs
        .map((log) => log.proofImagePath)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    final purchaseService = _purchaseService;
    if (purchaseService != null) {
      unawaited(purchaseService.dispose());
    }
    super.dispose();
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

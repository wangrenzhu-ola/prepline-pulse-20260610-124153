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

class PrepBoardController extends ChangeNotifier {
  PrepBoardController({
    PrepRepository repository = const PrepRepository(),
    PreplineDocumentMediaStore? mediaStore,
    PreplinePermissionService? permissionService,
    PulseWalletLedger? walletLedger,
    PreplinePurchaseService? purchaseService,
    ImagePicker? imagePicker,
  })  : _mediaStore = mediaStore ?? PreplineDocumentMediaStore(),
        _permissionService = permissionService ?? PreplinePermissionService(),
        _walletLedger = walletLedger ?? PulseWalletLedger(),
        _purchaseService = purchaseService,
        _imagePicker = imagePicker ?? ImagePicker() {
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
    _loadPulseCredits();
  }

  final PreplineDocumentMediaStore _mediaStore;
  final PreplinePermissionService _permissionService;
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

  String selectedBatchId = 'B-104';
  String visibleConfirmation = 'Ready for first station update.';
  String? lastConfirmation;
  String? lastResolvedException;
  String? mediaReadback;
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
  MediaRecord get media {
    final lineBoardMedia = mediaFor('line-board');
    return lineBoardMedia.isEmpty ? _snapshot.media : lineBoardMedia.first;
  }

  int get blockedBatchCount => _batches.where((batch) => batch.blocked).length;
  int get blockedCount => _exceptions.where((item) => !item.resolved).length;
  bool get storeBusy => activePurchaseProductId != null;

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
    );
    _logs.add(_latestSavedState);
    _syncExceptionForSavedState(updated);
    visibleConfirmation =
        'Saved ${updated.id} as ${updated.state} at ${_latestSavedState.savedAt}; ${PulseWalletLedger.stateSaveCost} credits used.';
    lastConfirmation = visibleConfirmation;
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

  Future<void> uploadMedia(String attachedTo) async {
    final allowed = await _permissionService.requestPhotoLibraryRead();
    if (!allowed) {
      mediaReadback =
          'Photo access is limited; the large image stays on the built-in proof.';
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
    _media.insert(
      0,
      MediaRecord(
        id: 'M-${DateTime.now().microsecondsSinceEpoch}',
        assetPath: relativePath,
        label: 'Uploaded station proof',
        attachedTo: attachedTo,
        storedInDocuments: true,
      ),
    );
    mediaReadback = 'Uploaded and stored $relativePath.';
    notifyListeners();
  }

  Future<void> saveMediaToAlbum(String mediaId) async {
    final media = _media.firstWhere((item) => item.id == mediaId);
    if (!media.storedInDocuments) {
      mediaReadback = 'Built-in proof images do not need album export.';
      notifyListeners();
      return;
    }
    final allowed = await _permissionService.requestPhotoLibraryWrite();
    if (!allowed) {
      mediaReadback =
          'Album save is unavailable; the image remains safely in this app.';
      notifyListeners();
      return;
    }
    await _mediaStore.saveRelativePathToGallery(media.assetPath);
    mediaReadback = 'Saved ${media.label} to the system photo album.';
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
    final existing = _media.where((media) => media.id == mediaId).toList();
    for (final media in existing) {
      if (media.storedInDocuments) {
        _mediaStore.deleteRelativePath(media.assetPath);
      }
    }
    _media.removeWhere((media) => media.id == mediaId);
    mediaReadback = 'Removed media $mediaId.';
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

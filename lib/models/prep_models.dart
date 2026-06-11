class PageContract {
  const PageContract({
    required this.pageId,
    required this.routeName,
    required this.widgetClass,
    required this.stateKey,
    required this.title,
    required this.purpose,
    required this.mustShow,
    required this.layer,
  });

  final String pageId;
  final String routeName;
  final String widgetClass;
  final String stateKey;
  final String title;
  final String purpose;
  final List<String> mustShow;
  final String layer;
}

class ServiceWindow {
  const ServiceWindow({
    required this.label,
    required this.timeRange,
    required this.minutesRemaining,
    required this.pressure,
  });

  final String label;
  final String timeRange;
  final int minutesRemaining;
  final String pressure;
}

class StationStatus {
  const StationStatus({
    required this.station,
    required this.state,
    required this.owner,
    required this.backup,
    required this.activeBatchId,
    required this.blocked,
  });

  final String station;
  final String state;
  final String owner;
  final String backup;
  final String activeBatchId;
  final bool blocked;

  StationStatus copyWith({
    String? state,
    String? owner,
    String? activeBatchId,
    bool? blocked,
  }) {
    return StationStatus(
      station: station,
      state: state ?? this.state,
      owner: owner ?? this.owner,
      backup: backup,
      activeBatchId: activeBatchId ?? this.activeBatchId,
      blocked: blocked ?? this.blocked,
    );
  }

  factory StationStatus.fromJson(Map<String, Object?> json) {
    return StationStatus(
      station: json['station'] as String,
      state: json['state'] as String,
      owner: json['owner'] as String,
      backup: json['backup'] as String,
      activeBatchId: json['activeBatchId'] as String,
      blocked: json['blocked'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'station': station,
      'state': state,
      'owner': owner,
      'backup': backup,
      'activeBatchId': activeBatchId,
      'blocked': blocked,
    };
  }
}

class LineBoardSnapshot {
  const LineBoardSnapshot({
    required this.pageId,
    required this.serviceWindow,
    required this.stations,
    required this.batches,
    required this.latestSavedState,
    required this.media,
  });

  final String pageId;
  final ServiceWindow serviceWindow;
  final List<StationStatus> stations;
  final List<PrepBatch> batches;
  final PrepLog latestSavedState;
  final MediaRecord media;
}

class PrepBatch {
  const PrepBatch({
    required this.id,
    required this.name,
    required this.station,
    required this.owner,
    required this.backup,
    required this.quantity,
    required this.state,
    required this.serviceWindow,
    required this.minutesToWindow,
    required this.note,
    required this.blocked,
  });

  final String id;
  final String name;
  final String station;
  final String owner;
  final String backup;
  final int quantity;
  final String state;
  final String serviceWindow;
  final int minutesToWindow;
  final String note;
  final bool blocked;

  PrepBatch copyWith({
    String? station,
    String? owner,
    String? state,
    String? note,
    bool? blocked,
  }) {
    return PrepBatch(
      id: id,
      name: name,
      station: station ?? this.station,
      owner: owner ?? this.owner,
      backup: backup,
      quantity: quantity,
      state: state ?? this.state,
      serviceWindow: serviceWindow,
      minutesToWindow: minutesToWindow,
      note: note ?? this.note,
      blocked: blocked ?? this.blocked,
    );
  }

  factory PrepBatch.fromJson(Map<String, Object?> json) {
    return PrepBatch(
      id: json['id'] as String,
      name: json['name'] as String,
      station: json['station'] as String,
      owner: json['owner'] as String,
      backup: json['backup'] as String,
      quantity: json['quantity'] as int,
      state: json['state'] as String,
      serviceWindow: json['serviceWindow'] as String,
      minutesToWindow: json['minutesToWindow'] as int,
      note: json['note'] as String,
      blocked: json['blocked'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'station': station,
      'owner': owner,
      'backup': backup,
      'quantity': quantity,
      'state': state,
      'serviceWindow': serviceWindow,
      'minutesToWindow': minutesToWindow,
      'note': note,
      'blocked': blocked,
    };
  }
}

class PrepLog {
  const PrepLog({
    required this.batchId,
    required this.batchName,
    required this.station,
    required this.state,
    required this.owner,
    required this.note,
    required this.savedAt,
    this.proofImagePath,
  });

  final String batchId;
  final String batchName;
  final String station;
  final String state;
  final String owner;
  final String note;
  final String savedAt;
  final String? proofImagePath;

  bool get hasProofImage => proofImagePath?.isNotEmpty ?? false;

  factory PrepLog.fromJson(Map<String, Object?> json) {
    return PrepLog(
      batchId: json['batchId'] as String,
      batchName: json['batchName'] as String,
      station: json['station'] as String,
      state: json['state'] as String,
      owner: json['owner'] as String,
      note: json['note'] as String,
      savedAt: json['savedAt'] as String,
      proofImagePath: json['proofImagePath'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'batchId': batchId,
      'batchName': batchName,
      'station': station,
      'state': state,
      'owner': owner,
      'note': note,
      'savedAt': savedAt,
      'proofImagePath': proofImagePath,
    };
  }
}

class PrepException {
  const PrepException({
    required this.id,
    required this.batchId,
    required this.reason,
    required this.owner,
    required this.resolved,
  });

  final String id;
  final String batchId;
  final String reason;
  final String owner;
  final bool resolved;

  PrepException resolve() {
    return PrepException(
      id: id,
      batchId: batchId,
      reason: reason,
      owner: owner,
      resolved: true,
    );
  }

  factory PrepException.fromJson(Map<String, Object?> json) {
    return PrepException(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      reason: json['reason'] as String,
      owner: json['owner'] as String,
      resolved: json['resolved'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'reason': reason,
      'owner': owner,
      'resolved': resolved,
    };
  }
}

class MediaRecord {
  const MediaRecord({
    required this.id,
    required this.assetPath,
    required this.label,
    required this.attachedTo,
    this.storedInDocuments = false,
  });

  final String id;
  final String assetPath;
  final String label;
  final String attachedTo;
  final bool storedInDocuments;

  factory MediaRecord.fromJson(Map<String, Object?> json) {
    return MediaRecord(
      id: json['id'] as String,
      assetPath: json['assetPath'] as String,
      label: json['label'] as String,
      attachedTo: json['attachedTo'] as String,
      storedInDocuments: json['storedInDocuments'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'assetPath': assetPath,
      'label': label,
      'attachedTo': attachedTo,
      'storedInDocuments': storedInDocuments,
    };
  }
}

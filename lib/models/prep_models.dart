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
  });

  final String batchId;
  final String batchName;
  final String station;
  final String state;
  final String owner;
  final String note;
  final String savedAt;
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
}

class MediaRecord {
  const MediaRecord({
    required this.id,
    required this.assetPath,
    required this.label,
    required this.attachedTo,
  });

  final String id;
  final String assetPath;
  final String label;
  final String attachedTo;
}

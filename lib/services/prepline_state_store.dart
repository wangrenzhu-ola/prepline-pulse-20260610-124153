import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prep_models.dart';

class PreplineSavedSession {
  const PreplineSavedSession({
    required this.selectedBatchId,
    required this.batches,
    required this.stations,
    required this.logs,
    required this.exceptions,
    required this.media,
  });

  final String selectedBatchId;
  final List<PrepBatch> batches;
  final List<StationStatus> stations;
  final List<PrepLog> logs;
  final List<PrepException> exceptions;
  final List<MediaRecord> media;

  PrepLog? get latestLog => logs.isEmpty ? null : logs.last;
}

class PreplineStateStore {
  static const _sessionKey = 'prepline.saved_session.v1';

  Future<PreplineSavedSession?> readSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return PreplineSavedSession(
      selectedBatchId: decoded['selectedBatchId'] as String,
      batches: _listOfMaps(decoded['batches'])
          .map(PrepBatch.fromJson)
          .toList(growable: false),
      stations: _listOfMaps(decoded['stations'])
          .map(StationStatus.fromJson)
          .toList(growable: false),
      logs: _listOfMaps(decoded['logs'])
          .map(PrepLog.fromJson)
          .toList(growable: false),
      exceptions: _listOfMaps(decoded['exceptions'])
          .map(PrepException.fromJson)
          .toList(growable: false),
      media: decoded['media'] == null
          ? const []
          : _listOfMaps(decoded['media'])
              .map(MediaRecord.fromJson)
              .toList(growable: false),
    );
  }

  Future<void> writeSession({
    required String selectedBatchId,
    required List<PrepBatch> batches,
    required List<StationStatus> stations,
    required List<PrepLog> logs,
    required List<PrepException> exceptions,
    required List<MediaRecord> media,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'selectedBatchId': selectedBatchId,
      'batches': batches.map((batch) => batch.toJson()).toList(),
      'stations': stations.map((station) => station.toJson()).toList(),
      'logs': logs.map((log) => log.toJson()).toList(),
      'exceptions': exceptions.map((exception) => exception.toJson()).toList(),
      'media': media.map((record) => record.toJson()).toList(),
    });
    await preferences.setString(_sessionKey, payload);
  }

  List<Map<String, Object?>> _listOfMaps(Object? value) {
    return (value as List<Object?>)
        .cast<Map<String, Object?>>()
        .toList(growable: false);
  }
}

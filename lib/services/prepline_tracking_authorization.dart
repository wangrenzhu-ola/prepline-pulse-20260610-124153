import 'package:flutter/services.dart';

enum TeltaTrackingStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notSupported;

  static TeltaTrackingStatus fromRawValue(int? rawValue) {
    switch (rawValue) {
      case 0:
        return TeltaTrackingStatus.notDetermined;
      case 1:
        return TeltaTrackingStatus.restricted;
      case 2:
        return TeltaTrackingStatus.denied;
      case 3:
        return TeltaTrackingStatus.authorized;
      default:
        return TeltaTrackingStatus.notSupported;
    }
  }
}

class TeltaTrackingAuthorization {
  const TeltaTrackingAuthorization._();

  static const _channel = MethodChannel(
    'telta/tracking_authorization',
  );

  static Future<TeltaTrackingStatus> status() async {
    final rawValue = await _channel.invokeMethod<int>(
      'trackingAuthorizationStatus',
    );
    return TeltaTrackingStatus.fromRawValue(rawValue);
  }

  static Future<TeltaTrackingStatus> request() async {
    final rawValue = await _channel.invokeMethod<int>(
      'requestTrackingAuthorization',
    );
    return TeltaTrackingStatus.fromRawValue(rawValue);
  }
}

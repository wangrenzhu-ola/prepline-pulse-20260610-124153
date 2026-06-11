import 'package:flutter/services.dart';

enum PrepLinePulseTrackingStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notSupported;

  static PrepLinePulseTrackingStatus fromRawValue(int? rawValue) {
    switch (rawValue) {
      case 0:
        return PrepLinePulseTrackingStatus.notDetermined;
      case 1:
        return PrepLinePulseTrackingStatus.restricted;
      case 2:
        return PrepLinePulseTrackingStatus.denied;
      case 3:
        return PrepLinePulseTrackingStatus.authorized;
      default:
        return PrepLinePulseTrackingStatus.notSupported;
    }
  }
}

class PrepLinePulseTrackingAuthorization {
  const PrepLinePulseTrackingAuthorization._();

  static const _channel = MethodChannel(
    'prep_line_pulse/tracking_authorization',
  );

  static Future<PrepLinePulseTrackingStatus> status() async {
    final rawValue = await _channel.invokeMethod<int>(
      'trackingAuthorizationStatus',
    );
    return PrepLinePulseTrackingStatus.fromRawValue(rawValue);
  }

  static Future<PrepLinePulseTrackingStatus> request() async {
    final rawValue = await _channel.invokeMethod<int>(
      'requestTrackingAuthorization',
    );
    return PrepLinePulseTrackingStatus.fromRawValue(rawValue);
  }
}

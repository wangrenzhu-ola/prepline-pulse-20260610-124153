import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await prepLinePulseResolveTrackingAuthorization();
  PrepLineTheme.ensureLinked();
  runApp(const PrepLinePulseApp());
}

Future<void> prepLinePulseResolveTrackingAuthorization() async {
  if (!Platform.isIOS) {
    return;
  }
  final preferences = await SharedPreferences.getInstance();
  const prepLinePulseAttRequestedKey = 'prepLinePulseAttRequested';
  if (preferences.getBool(prepLinePulseAttRequestedKey) ?? false) {
    return;
  }

  const prepLinePulseAttRetryLimit = 23;
  for (var prepLinePulseAttAttempt = 0;
      prepLinePulseAttAttempt < prepLinePulseAttRetryLimit;
      prepLinePulseAttAttempt += 1) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) {
      await preferences.setBool(prepLinePulseAttRequestedKey, true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final requested =
        await AppTrackingTransparency.requestTrackingAuthorization();
    if (requested != TrackingStatus.notDetermined) {
      await preferences.setBool(prepLinePulseAttRequestedKey, true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

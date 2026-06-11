import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'services/prepline_tracking_authorization.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PrepLineTheme.ensureLinked();
  runApp(const PrepLinePulseApp());
  prepLinePulseScheduleTrackingAuthorization();
}

void prepLinePulseScheduleTrackingAuthorization() {
  if (!Platform.isIOS) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(prepLinePulseResolveTrackingAuthorization());
  });
}

Future<void> prepLinePulseResolveTrackingAuthorization() async {
  if (!Platform.isIOS) {
    return;
  }
  try {
    final preferences = await SharedPreferences.getInstance();
    const prepLinePulseAttRequestedKey = 'prepLinePulseAttRequested';
    if (preferences.getBool(prepLinePulseAttRequestedKey) ?? false) {
      return;
    }

    const prepLinePulseAttRetryLimit = 23;
    for (var prepLinePulseAttAttempt = 0;
        prepLinePulseAttAttempt < prepLinePulseAttRetryLimit;
        prepLinePulseAttAttempt += 1) {
      final status = await prepLinePulseTrackingStatus();
      if (status == null) {
        return;
      }
      if (status != PrepLinePulseTrackingStatus.notDetermined) {
        await preferences.setBool(prepLinePulseAttRequestedKey, true);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final requested = await prepLinePulseRequestTrackingAuthorization();
      if (requested == null) {
        return;
      }
      if (requested != PrepLinePulseTrackingStatus.notDetermined) {
        await preferences.setBool(prepLinePulseAttRequestedKey, true);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  } on Object {
    return;
  }
}

Future<PrepLinePulseTrackingStatus?> prepLinePulseTrackingStatus() async {
  try {
    return await PrepLinePulseTrackingAuthorization.status()
        .timeout(const Duration(milliseconds: 700));
  } on TimeoutException {
    return null;
  } on Object {
    return null;
  }
}

Future<PrepLinePulseTrackingStatus?>
    prepLinePulseRequestTrackingAuthorization() async {
  try {
    return await PrepLinePulseTrackingAuthorization.request()
        .timeout(const Duration(milliseconds: 900));
  } on TimeoutException {
    return null;
  } on Object {
    return null;
  }
}

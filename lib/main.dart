import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/app_shell.dart';
import 'services/prepline_tracking_authorization.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TeltaTheme.ensureLinked();
  runApp(const TeltaApp());
  teltaScheduleTrackingAuthorization();
}

void teltaScheduleTrackingAuthorization() {
  if (!Platform.isIOS) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(teltaResolveTrackingAuthorization());
  });
}

Future<void> teltaResolveTrackingAuthorization() async {
  if (!Platform.isIOS) {
    return;
  }
  try {
    final preferences = await SharedPreferences.getInstance();
    const teltaAttRequestedKey = 'teltaAttRequested';
    if (preferences.getBool(teltaAttRequestedKey) ?? false) {
      return;
    }

    const teltaAttRetryLimit = 23;
    for (var teltaAttAttempt = 0;
        teltaAttAttempt < teltaAttRetryLimit;
        teltaAttAttempt += 1) {
      final status = await teltaTrackingStatus();
      if (status == null) {
        return;
      }
      if (status != TeltaTrackingStatus.notDetermined) {
        await preferences.setBool(teltaAttRequestedKey, true);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final requested = await teltaRequestTrackingAuthorization();
      if (requested == null) {
        return;
      }
      if (requested != TeltaTrackingStatus.notDetermined) {
        await preferences.setBool(teltaAttRequestedKey, true);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  } on Object {
    return;
  }
}

Future<TeltaTrackingStatus?> teltaTrackingStatus() async {
  try {
    return await TeltaTrackingAuthorization.status()
        .timeout(const Duration(milliseconds: 700));
  } on TimeoutException {
    return null;
  } on Object {
    return null;
  }
}

Future<TeltaTrackingStatus?> teltaRequestTrackingAuthorization() async {
  try {
    return await TeltaTrackingAuthorization.request()
        .timeout(const Duration(milliseconds: 900));
  } on TimeoutException {
    return null;
  } on Object {
    return null;
  }
}

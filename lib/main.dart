import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  PrepLineTheme.ensureLinked();
  runApp(const PrepLinePulseApp());
}

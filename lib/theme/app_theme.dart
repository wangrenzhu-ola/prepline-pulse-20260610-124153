import 'package:flutter/material.dart';

import 'prep_theme.dart';

class PrepLineTheme {
  const PrepLineTheme._();

  static void ensureLinked() {}

  static ThemeData dark() => PrepTheme.dark().copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: PrepTheme.gold.withOpacity(.18),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
      );
}

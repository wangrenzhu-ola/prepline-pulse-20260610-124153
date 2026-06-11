import 'package:flutter/material.dart';

class PrepTheme {
  static const background = Color(0xFF101014);
  static const surface = Color(0xFF1B1A22);
  static const elevated = Color(0xFF2D2824);
  static const gold = Color(0xFFD4AF37);
  static const violet = Color(0xFFA78BFA);
  static const success = Color(0xFF25B05F);
  static const warning = Color(0xFFF29E0C);
  static const error = Color(0xFFDC2828);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      surface: surface,
      primary: gold,
      secondary: violet,
      error: error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 30),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: gold.withOpacity(.18)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'colors.dart';

class NaosTheme {
  NaosTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: NaosColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: NaosColors.primary,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: NaosColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
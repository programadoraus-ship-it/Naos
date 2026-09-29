import 'package:flutter/material.dart';
import 'colors.dart';

class NaosTextStyles {
  NaosTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: NaosColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: NaosColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: NaosColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
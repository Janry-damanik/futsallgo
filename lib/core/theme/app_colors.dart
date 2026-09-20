import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F7A8C);
  static const Color primaryDark = Color(0xFF124D5F);
  static const Color accent = Color(0xFF39C0ED);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1B2430);
  static const Color muted = Color(0xFF5F6C7B);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F7A8C), Color(0xFF39C0ED)],
  );
}

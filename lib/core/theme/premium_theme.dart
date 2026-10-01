import 'package:flutter/material.dart';

class PremiumTheme {
  const PremiumTheme._();

  static ThemeData get dark {
    const background = Color(0xFF101619);
    const surface = Color(0xFF172126);
    const elevatedSurface = Color(0xFF243138);
    const foreground = Color(0xFFF2F6F4);
    const mutedForeground = Color(0xFFB6C3BF);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF16C784),
          brightness: Brightness.dark,
          primary: const Color(0xFF31D995),
          onPrimary: const Color(0xFF062116),
          secondary: const Color(0xFF51D2C1),
          tertiary: const Color(0xFFFFD166),
        ).copyWith(
          surface: surface,
          surfaceContainerHighest: elevatedSurface,
          onSurface: foreground,
          onSurfaceVariant: mutedForeground,
          outline: const Color(0xFF64736F),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        hintStyle: const TextStyle(color: mutedForeground),
        labelStyle: const TextStyle(color: mutedForeground),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: const Color(0xFF33434A),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1F7A8C),
        brightness: Brightness.light,
        primary: const Color(0xFF1F7A8C),
        secondary: const Color(0xFF39C0ED),
        tertiary: const Color(0xFF0EA5E9),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

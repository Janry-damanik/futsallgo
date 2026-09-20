import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences harus di override di main.dart');
});

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(ref.watch(sharedPreferencesProvider)),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_readThemeMode(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }

  static ThemeMode _readThemeMode(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

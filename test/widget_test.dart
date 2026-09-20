import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsallgo/app.dart';
import 'package:futsallgo/core/theme/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('splash lalu masuk ke Home dengan 4 navigasi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FutsalGoApp(),
      ),
    );

    expect(find.text('FutsalGo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });

  test('theme mode default = system', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}

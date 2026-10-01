import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:futsallgo/app.dart';
import 'package:futsallgo/core/providers/auth_provider.dart';
import 'package:futsallgo/core/services/api_service.dart';
import 'package:futsallgo/core/theme/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('splash lalu meminta login saat belum ada sesi MySQL', (
    tester,
  ) async {
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

    expect(find.text('Masuk ke FutsalGo'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('daftar harus verifikasi OTP sebelum masuk ke daftar lapangan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/register')) {
        return http.Response(
          jsonEncode({
            'data': {'email': 'dina@example.com'},
          }),
          202,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/auth/otp/verify')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['code'] != '123456') {
          return http.Response(
            jsonEncode({'message': 'Kode salah.'}),
            422,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'data': {
              'token': 'test-token',
              'user': {
                'id': 1,
                'name': 'Dina',
                'email': 'dina@example.com',
                'role': 'customer',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/availability')) {
        final duration = request.url.queryParameters['durationHours'];
        return http.Response(
          jsonEncode({
            'data': duration == '2' ? ['18.00'] : ['18.00', '19.00'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/bookings')) {
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/settings')) {
        return http.Response(
          jsonEncode({
            'data': {
              'venueName': 'Usaha Futsal',
              'address': 'Jalan Lapangan',
              'phone': '081200000000',
              'hourlyPrice': 180000,
              'openTime': '08.00',
              'closeTime': '22.00',
              'courts': ['Lapangan 1'],
              'courtPrices': {'Lapangan 1': 220000},
              'blockedSlots': [],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });
    addTearDown(client.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiServiceProvider.overrideWithValue(
            ApiService(
              baseUrl: 'https://api.test/api/v1',
              tokenReader: () => prefs.getString('api_token'),
              client: client,
            ),
          ),
        ],
        child: const FutsalGoApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Dina');
    await tester.enterText(find.byType(TextField).at(1), 'dina@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi email'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verifikasi dan masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Lapangan tersedia'), findsOneWidget);
    expect(find.text('Lapangan 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Lapangan 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('220.000'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Pesan'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal lapangan'), findsOneWidget);
    await tester.ensureVisible(find.text('2 jam').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 jam').first);
    await tester.pumpAndSettle();
    expect(find.text('18.00 - 20.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Total'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 440.000'), findsWidgets);
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

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futsallgo/core/providers/admin_settings_provider.dart';
import 'package:futsallgo/core/providers/auth_provider.dart';
import 'package:futsallgo/core/services/api_service.dart';
import 'package:futsallgo/core/theme/theme_mode_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads web-uploaded court images from the courts endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/settings')) {
        return http.Response(
          jsonEncode({
            'data': {
              'venueName': 'Arena Test',
              'courts': [],
              'courtImages': {},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/courts')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 4,
                'name': 'Lapangan 5',
                'surface': 'Rumput sintetis',
                'description': 'Foto dari admin web',
                'imageUrl': 'https://api.test/storage/courts/lapangan-5.webp',
                'hourlyPrice': 50000,
                'averageRating': 4.5,
                'reviewCount': 2,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/promos')) {
        return http.Response(
          jsonEncode({'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        apiServiceProvider.overrideWithValue(
          ApiService(baseUrl: 'https://api.test/api/v1', client: client),
        ),
      ],
    );
    addTearDown(() {
      client.close();
      container.dispose();
    });

    await container.read(adminSettingsProvider.notifier).reload();

    final settings = container.read(adminSettingsProvider);
    expect(settings.courts, ['Lapangan 5']);
    expect(
      settings.courtImages['Lapangan 5'],
      'https://api.test/storage/courts/lapangan-5.webp',
    );
    expect(settings.courtRatings['Lapangan 5'], 4.5);
    expect(settings.courtReviewCounts['Lapangan 5'], 2);
  });
}
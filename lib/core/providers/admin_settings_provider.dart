import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/promo_banner.dart';
import '../services/api_service.dart';
import '../theme/theme_mode_controller.dart';
import 'auth_provider.dart';

final adminSettingsProvider =
    StateNotifierProvider<AdminSettingsController, AdminSettings>((ref) {
      return AdminSettingsController(
        ref.watch(sharedPreferencesProvider),
        ref.watch(apiServiceProvider),
      );
    });

class AdminSettings {
  const AdminSettings({
    required this.venueName,
    required this.address,
    required this.phone,
    required this.hourlyPrice,
    required this.openTime,
    required this.closeTime,
    required this.courts,
    required this.courtPrices,
    required this.courtImages,
    required this.blockedSlots,
    this.promos = const [],
    this.facilities = const [],
    this.courtDescriptions = const {},
    this.courtSurfaces = const {},
    this.courtRatings = const {},
    this.courtReviewCounts = const {},
  });

  final String venueName;
  final String address;
  final String phone;
  final int hourlyPrice;
  final String openTime;
  final String closeTime;
  final List<String> courts;
  final Map<String, int> courtPrices;
  final Map<String, String> courtImages;
  final List<String> blockedSlots;
  final List<PromoBanner> promos;
  final List<String> facilities;
  final Map<String, String> courtDescriptions;
  final Map<String, String> courtSurfaces;
  final Map<String, double> courtRatings;
  final Map<String, int> courtReviewCounts;

  static const defaults = AdminSettings(
    venueName: 'Arena Hijau Futsal',
    address: 'Jl. Merdeka No. 12',
    phone: '0812-0000-0000',
    hourlyPrice: 180000,
    openTime: '06.00',
    closeTime: '24.00',
    courts: ['Lapangan 1'],
    courtPrices: {'Lapangan 1': 180000},
    courtImages: {},
    blockedSlots: [],
    facilities: [],
    courtDescriptions: {'Lapangan 1': ''},
    courtSurfaces: {'Lapangan 1': ''},
    courtRatings: {},
    courtReviewCounts: {},
  );

  AdminSettings copyWith({
    String? venueName,
    String? address,
    String? phone,
    int? hourlyPrice,
    String? openTime,
    String? closeTime,
    List<String>? courts,
    Map<String, int>? courtPrices,
    Map<String, String>? courtImages,
    List<String>? blockedSlots,
    List<PromoBanner>? promos,
    List<String>? facilities,
    Map<String, String>? courtDescriptions,
    Map<String, String>? courtSurfaces,
    Map<String, double>? courtRatings,
    Map<String, int>? courtReviewCounts,
  }) {
    return AdminSettings(
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      hourlyPrice: hourlyPrice ?? this.hourlyPrice,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      courts: courts ?? this.courts,
      courtPrices: courtPrices ?? this.courtPrices,
      courtImages: courtImages ?? this.courtImages,
      blockedSlots: blockedSlots ?? this.blockedSlots,
      promos: promos ?? this.promos,
      facilities: facilities ?? this.facilities,
      courtDescriptions: courtDescriptions ?? this.courtDescriptions,
      courtSurfaces: courtSurfaces ?? this.courtSurfaces,
      courtRatings: courtRatings ?? this.courtRatings,
      courtReviewCounts: courtReviewCounts ?? this.courtReviewCounts,
    );
  }

  Map<String, dynamic> toJson() => {
    'venueName': venueName,
    'address': address,
    'phone': phone,
    'hourlyPrice': hourlyPrice,
    'openTime': openTime,
    'closeTime': closeTime,
    'courts': courts,
    'courtPrices': courtPrices,
    'courtImages': courtImages,
    'blockedSlots': blockedSlots,
    'facilities': facilities,
    'courtDescriptions': courtDescriptions,
    'courtSurfaces': courtSurfaces,
    'courtRatings': {
      for (final name in courtRatings.keys)
        name: {
          'average': courtRatings[name],
          'count': courtReviewCounts[name] ?? 0,
        },
    },
    'promos': promos
        .map(
          (promo) => {
            'id': promo.id,
            ...promo.toPayload(),
            'imageUrl': promo.imageUrl,
          },
        )
        .toList(),
  };

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    final rawCourtImages = json['courtImages'] as Map<dynamic, dynamic>?;
    final rawCourtDescriptions =
        json['courtDescriptions'] as Map<dynamic, dynamic>?;
    final rawCourtSurfaces = json['courtSurfaces'] as Map<dynamic, dynamic>?;
    final rawCourtRatings = json['courtRatings'] as Map<dynamic, dynamic>?;
    final courtRatings = <String, double>{};
    final courtReviewCounts = <String, int>{};
    rawCourtRatings?.forEach((name, value) {
      if (value is Map) {
        final key = name.toString();
        courtRatings[key] =
            double.tryParse(value['average']?.toString() ?? '') ?? 0;
        courtReviewCounts[key] =
            int.tryParse(value['count']?.toString() ?? '') ?? 0;
      }
    });
    return AdminSettings(
      venueName: json['venueName']?.toString() ?? defaults.venueName,
      address: json['address']?.toString() ?? defaults.address,
      phone: json['phone']?.toString() ?? defaults.phone,
      hourlyPrice:
          int.tryParse(json['hourlyPrice'].toString()) ?? defaults.hourlyPrice,
      openTime: json['openTime']?.toString() ?? defaults.openTime,
      closeTime: json['closeTime']?.toString() ?? defaults.closeTime,
      courts:
          (json['courts'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          defaults.courts,
      courtPrices:
          (json['courtPrices'] as Map<dynamic, dynamic>?)?.map(
            (name, price) => MapEntry(
              name.toString(),
              int.tryParse(price.toString()) ?? defaults.hourlyPrice,
            ),
          ) ??
          defaults.courtPrices,
      courtImages: rawCourtImages == null
          ? defaults.courtImages
          : {
              for (final entry in rawCourtImages.entries)
                if (entry.value != null)
                  entry.key.toString(): entry.value.toString(),
            },
      blockedSlots:
          (json['blockedSlots'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          defaults.blockedSlots,
      promos:
          (json['promos'] as List<dynamic>?)
              ?.map(
                (promo) => PromoBanner.fromJson(
                  Map<String, dynamic>.from(promo as Map),
                ),
              )
              .toList() ??
          defaults.promos,
      facilities:
          (json['facilities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          defaults.facilities,
      courtDescriptions:
          rawCourtDescriptions?.map(
            (name, value) => MapEntry(name.toString(), value?.toString() ?? ''),
          ) ??
          defaults.courtDescriptions,
      courtSurfaces:
          rawCourtSurfaces?.map(
            (name, value) => MapEntry(name.toString(), value?.toString() ?? ''),
          ) ??
          defaults.courtSurfaces,
      courtRatings: courtRatings,
      courtReviewCounts: courtReviewCounts,
    );
  }
}

class AdminSettingsController extends StateNotifier<AdminSettings> {
  AdminSettingsController(this._prefs, this._api)
    : super(AdminSettings.defaults) {
    _load();
  }

  final SharedPreferences _prefs;
  final ApiService _api;
  static const _key = 'admin_settings';

  Future<void> reload() => _load();

  Future<void> update(AdminSettings next) async {
    await _api.put('/settings', {
      'name': next.venueName,
      'address': next.address,
      'phone': next.phone,
      'hourly_price': next.hourlyPrice,
      'open_time': next.openTime.replaceAll('.', ':'),
      'close_time': next.closeTime == '24.00'
          ? '00:00'
          : next.closeTime.replaceAll('.', ':'),
    });
    state = next;
    await _persist();
  }

  Future<void> addCourt(
    String name, {
    String description = '',
    String surface = '',
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || state.courts.contains(cleanName)) return;
    final price = state.hourlyPrice;
    await _api.post('/courts', {
      'name': cleanName,
      'price_per_hour': price,
      'description': description.trim(),
      'surface': surface.trim(),
    });
    state = state.copyWith(
      courts: [...state.courts, cleanName],
      courtPrices: {...state.courtPrices, cleanName: price},
      courtDescriptions: {
        ...state.courtDescriptions,
        cleanName: description.trim(),
      },
      courtSurfaces: {...state.courtSurfaces, cleanName: surface.trim()},
    );
    await _persist();
  }

  Future<void> updateCourtDetails(
    String name, {
    required String description,
    required String surface,
  }) async {
    await _api.patch('/courts/${Uri.encodeComponent(name)}', {
      'description': description.trim(),
      'surface': surface.trim(),
    });
    state = state.copyWith(
      courtDescriptions: {...state.courtDescriptions, name: description.trim()},
      courtSurfaces: {...state.courtSurfaces, name: surface.trim()},
    );
    await _persist();
  }

  Future<void> updateFacilities(List<String> facilities) async {
    final cleanFacilities = facilities
        .map((facility) => facility.trim())
        .where((facility) => facility.isNotEmpty)
        .toSet()
        .toList();
    await _api.put('/facilities', {'facilities': cleanFacilities});
    state = state.copyWith(facilities: cleanFacilities);
    await _persist();
  }

  Future<void> removeCourt(String name) async {
    if (state.courts.length <= 1) return;
    await _api.delete('/courts/${Uri.encodeComponent(name)}');
    final prices = {...state.courtPrices}..remove(name);
    final descriptions = {...state.courtDescriptions}..remove(name);
    final surfaces = {...state.courtSurfaces}..remove(name);
    final ratings = {...state.courtRatings}..remove(name);
    final reviewCounts = {...state.courtReviewCounts}..remove(name);
    state = state.copyWith(
      courts: state.courts.where((court) => court != name).toList(),
      courtPrices: prices,
      courtDescriptions: descriptions,
      courtSurfaces: surfaces,
      courtRatings: ratings,
      courtReviewCounts: reviewCounts,
    );
    await _persist();
  }

  Future<void> updateCourtPrice(String name, int price) async {
    await _api.patch('/courts/${Uri.encodeComponent(name)}', {
      'price_per_hour': price,
    });
    state = state.copyWith(courtPrices: {...state.courtPrices, name: price});
    await _persist();
  }

  Future<void> createPromo(PromoBanner promo) async {
    final response = await _api.post('/promos', promo.toPayload());
    final created = PromoBanner.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    state = state.copyWith(promos: [...state.promos, created]);
    await _persist();
  }

  Future<void> updatePromo(PromoBanner promo) async {
    final response = await _api.put('/promos/${promo.id}', promo.toPayload());
    final updated = PromoBanner.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    state = state.copyWith(
      promos: state.promos
          .map((item) => item.id == updated.id ? updated : item)
          .toList(),
    );
    await _persist();
  }

  Future<void> removePromo(int id) async {
    await _api.delete('/promos/$id');
    state = state.copyWith(
      promos: state.promos.where((item) => item.id != id).toList(),
    );
    await _persist();
  }

  Future<void> uploadPromoImage(
    int id, {
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.uploadFile(
      '/promos/$id/image',
      fieldName: 'image',
      bytes: bytes,
      filename: filename,
    );
    final updated = PromoBanner.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    state = state.copyWith(
      promos: state.promos
          .map((item) => item.id == updated.id ? updated : item)
          .toList(),
    );
    await _persist();
  }

  Future<void> uploadCourtImage(
    String name, {
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _api.uploadFile(
      '/courts/${Uri.encodeComponent(name)}/image',
      fieldName: 'image',
      bytes: bytes,
      filename: filename,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final imageUrl = data['imageUrl']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const FormatException('URL gambar tidak diterima dari server.');
    }
    state = state.copyWith(courtImages: {...state.courtImages, name: imageUrl});
    await _persist();
  }

  Future<void> toggleBlockedSlot(String slot) async {
    final blocked = [...state.blockedSlots];
    if (blocked.contains(slot)) {
      await _api.delete('/slots/${Uri.encodeComponent(slot)}');
      blocked.remove(slot);
    } else {
      await _api.post('/slots', {'slot': slot.replaceAll('.', ':')});
      blocked.add(slot);
    }
    state = state.copyWith(blockedSlots: blocked);
    await _persist();
  }

  Future<void> _load() async {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = AdminSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } on FormatException {
        state = AdminSettings.defaults;
      }
    }

    try {
      final response = await _api.get('/settings');
      final settings = AdminSettings.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
      final promoResponse = await _api.get('/promos');
      final promos = (promoResponse['data'] as List<dynamic>)
          .map(
            (promo) =>
                PromoBanner.fromJson(Map<String, dynamic>.from(promo as Map)),
          )
          .toList();
      state = settings.copyWith(promos: promos);
      await _persist();
    } on Exception {
      return;
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

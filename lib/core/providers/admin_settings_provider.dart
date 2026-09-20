import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_mode_controller.dart';

final adminSettingsProvider =
    StateNotifierProvider<AdminSettingsController, AdminSettings>((ref) {
      return AdminSettingsController(ref.watch(sharedPreferencesProvider));
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
    required this.blockedSlots,
  });

  final String venueName;
  final String address;
  final String phone;
  final int hourlyPrice;
  final String openTime;
  final String closeTime;
  final List<String> courts;
  final List<String> blockedSlots;

  static const defaults = AdminSettings(
    venueName: 'Arena Hijau Futsal',
    address: 'Jl. Merdeka No. 12',
    phone: '0812-0000-0000',
    hourlyPrice: 180000,
    openTime: '08.00',
    closeTime: '22.00',
    courts: ['Lapangan 1'],
    blockedSlots: [],
  );

  AdminSettings copyWith({
    String? venueName,
    String? address,
    String? phone,
    int? hourlyPrice,
    String? openTime,
    String? closeTime,
    List<String>? courts,
    List<String>? blockedSlots,
  }) {
    return AdminSettings(
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      hourlyPrice: hourlyPrice ?? this.hourlyPrice,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      courts: courts ?? this.courts,
      blockedSlots: blockedSlots ?? this.blockedSlots,
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
    'blockedSlots': blockedSlots,
  };

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
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
      blockedSlots:
          (json['blockedSlots'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          defaults.blockedSlots,
    );
  }
}

class AdminSettingsController extends StateNotifier<AdminSettings> {
  AdminSettingsController(this._prefs) : super(AdminSettings.defaults) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'admin_settings';

  Future<void> update(AdminSettings next) async {
    state = next;
    await _persist();
  }

  Future<void> addCourt(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || state.courts.contains(cleanName)) return;
    await update(state.copyWith(courts: [...state.courts, cleanName]));
  }

  Future<void> removeCourt(String name) async {
    if (state.courts.length <= 1) return;
    await update(
      state.copyWith(
        courts: state.courts.where((court) => court != name).toList(),
      ),
    );
  }

  Future<void> toggleBlockedSlot(String slot) async {
    final blocked = [...state.blockedSlots];
    if (blocked.contains(slot)) {
      blocked.remove(slot);
    } else {
      blocked.add(slot);
    }
    await update(state.copyWith(blockedSlots: blocked));
  }

  Future<void> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      state = AdminSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on FormatException {
      state = AdminSettings.defaults;
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

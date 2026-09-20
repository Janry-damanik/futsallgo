import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_summary.dart';
import '../theme/theme_mode_controller.dart';

final bookingProvider =
    StateNotifierProvider<BookingController, List<BookingSummary>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return BookingController(prefs);
    });

class BookingController extends StateNotifier<List<BookingSummary>> {
  BookingController(this._prefs) : super([]) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'bookings';

  Future<void> addBooking(BookingSummary booking) async {
    final items = [...state, booking];
    state = items;
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateStatus(int index, String status) async {
    if (index < 0 || index >= state.length) return;
    final items = [...state];
    final booking = items[index];
    items[index] = BookingSummary(
      fieldName: booking.fieldName,
      fieldLocation: booking.fieldLocation,
      date: booking.date,
      time: booking.time,
      price: booking.price,
      total: booking.total,
      status: status,
    );
    state = items;
    await _persist(items);
  }

  Future<void> removeBooking(int index) async {
    if (index < 0 || index >= state.length) return;
    final items = [...state]..removeAt(index);
    state = items;
    await _persist(items);
  }

  Future<void> _persist(List<BookingSummary> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded
        .map(
          (item) =>
              BookingSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}

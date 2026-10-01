import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_summary.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final bookingProvider =
    StateNotifierProvider<BookingController, List<BookingSummary>>((ref) {
      return BookingController(ref.watch(apiServiceProvider));
    });

class BookingController extends StateNotifier<List<BookingSummary>> {
  BookingController(this._api) : super([]) {
    _load();
  }

  final ApiService _api;

  Future<void> refresh() => _load();

  Future<void> updateStatus(int index, String status) async {
    if (index < 0 || index >= state.length) return;
    final booking = state[index];
    if (booking.id == null) return;
    final response = await _api.patch('/bookings/${booking.id}', {
      'status': status,
    });
    final items = [...state];
    items[index] = BookingSummary.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    state = items;
  }

  Future<void> removeBooking(int index) async {
    if (index < 0 || index >= state.length) return;
    final booking = state[index];
    if (booking.id == null) return;
    await _api.delete('/bookings/${booking.id}');
    final items = [...state]..removeAt(index);
    state = items;
  }

  Future<void> _load() async {
    try {
      final response = await _api.get('/bookings');
      final items = (response['data'] as List<dynamic>)
          .map(
            (item) =>
                BookingSummary.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      state = items;
    } on Exception {
      state = [];
    }
  }
}

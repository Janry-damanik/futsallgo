import 'api_service.dart';

class MidtransService {
  MidtransService(this._api);

  final ApiService _api;

  Future<QrisPayment> createQrisPayment({
    required int bookingId,
  }) async {
    final response = await _api.post('/bookings/$bookingId/qris', {});
    final payload = Map<String, dynamic>.from(response['data'] as Map);
    final qrString = payload['qrString']?.toString();
    final qrCodeBase64 = payload['qrCodeBase64']?.toString();
    if ((qrString == null || qrString.isEmpty) &&
        (qrCodeBase64 == null || qrCodeBase64.isEmpty)) {
      throw const MidtransException('Gambar QR pembayaran tidak diterima.');
    }

    return QrisPayment(
      orderId: payload['orderId']?.toString() ?? '',
      amount: int.tryParse(payload['amount']?.toString() ?? '') ?? 0,
      qrString: qrString,
      qrCodeBase64: qrCodeBase64,
      expiresAt: payload['expiresAt']?.toString(),
    );
  }

  Future<String> getPaymentStatus({required int bookingId}) async {
    final response = await _api.get('/bookings/$bookingId/payment-status');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return data['status']?.toString() ?? '';
  }

  static String createOrderId() {
    return 'FGO-${DateTime.now().millisecondsSinceEpoch}';
  }
}

class QrisPayment {
  const QrisPayment({
    required this.orderId,
    required this.amount,
    this.qrString,
    this.qrCodeBase64,
    this.expiresAt,
  });

  final String orderId;
  final int amount;
  final String? qrString;
  final String? qrCodeBase64;
  final String? expiresAt;
}

class MidtransException implements Exception {
  const MidtransException(this.message);

  final String message;

  @override
  String toString() => message;
}

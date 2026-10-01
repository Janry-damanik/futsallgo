import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/booking_summary.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/services/midtrans_service.dart';
import '../history/receipt_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({
    super.key,
    required this.booking,
    this.resumeExistingBooking = false,
  });

  final BookingSummary booking;
  final bool resumeExistingBooking;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late final MidtransService _midtransService;
  bool _processing = false;
  int? _bookingId;
  int? _bookingAmount;
  QrisPayment? _qrisPayment;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _midtransService = MidtransService(ref.read(apiServiceProvider));
    _startPayment();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ringkasan reservasi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Row(label: 'Lapangan', value: booking.fieldName),
                  _Row(label: 'Lokasi', value: booking.fieldLocation),
                  _Row(label: 'Tanggal', value: booking.date),
                  _Row(label: 'Jam', value: booking.time),
                  _Row(label: 'Harga per jam', value: booking.price),
                  _Row(label: 'Durasi', value: '${booking.durationHours} jam'),
                  const Divider(),
                  _Row(
                    label: 'Total',
                    value: _bookingAmount == null
                        ? booking.total
                        : _formatRupiah(_bookingAmount!),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Metode pembayaran',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payment_rounded),
              title: Text('QRIS'),
              subtitle: Text('Bayar dengan memindai kode QR berikut.'),
            ),
          ),
          if (_qrisPayment case final payment?) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: payment.qrString != null
                    ? QrImageView(
                        data: payment.qrString!,
                        size: 240,
                        backgroundColor: Colors.white,
                      )
                    : payment.qrCodeBase64 != null
                    ? Image.memory(
                        base64Decode(payment.qrCodeBase64!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text('QR pembayaran tidak dapat ditampilkan.'),
                        ),
                      )
                    : const Center(
                        child: Text('QR pembayaran tidak dapat ditampilkan.'),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Total pembayaran',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Center(
              child: Text(
                _formatRupiah(payment.amount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (payment.expiresAt case final expiresAt?)
              Center(child: Text('Berlaku sampai $expiresAt')),
          ],
          const SizedBox(height: 24),
          if (_processing && _qrisPayment == null)
            const Center(child: CircularProgressIndicator())
          else if (_qrisPayment != null)
            OutlinedButton.icon(
              onPressed: _processing ? null : _checkPaymentStatus,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cek status pembayaran'),
            ),
          if (_qrisPayment == null && !_processing)
            FilledButton(
              onPressed: _startPayment,
              child: Text(_orderId == null ? 'Buat QRIS' : 'Coba lagi'),
            ),
          if (_qrisPayment != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti saja'),
            ),
          if (_qrisPayment == null && _processing)
            const Center(child: Text('Menyiapkan pembayaran QRIS...')),
        ],
      ),
    );
  }

  Future<void> _startPayment() async {
    if (_processing || _qrisPayment != null) return;
    setState(() => _processing = true);
    try {
      if (widget.resumeExistingBooking) {
        final bookingId = widget.booking.id;
        if (bookingId == null) {
          throw const MidtransException('ID booking tidak ditemukan.');
        }
        _bookingId = bookingId;
        final status = await _midtransService.getPaymentStatus(
          bookingId: bookingId,
        );
        await ref.read(bookingProvider.notifier).refresh();
        if (status != 'Menunggu pembayaran') {
          final updatedBooking = _bookingFromProvider(bookingId);
          if (updatedBooking.isPaid && mounted) {
            await _openReceipt(updatedBooking);
            return;
          }
          throw MidtransException('Status booking saat ini: $status.');
        }
      } else {
        final orderId = _orderId ??= MidtransService.createOrderId();
        final bookingData = await _registerBooking(orderId);
        _bookingId = int.tryParse(bookingData['id']?.toString() ?? '');
        _bookingAmount = int.tryParse(bookingData['amount']?.toString() ?? '');
        await ref.read(bookingProvider.notifier).refresh();
      }
      final bookingId = _bookingId;
      if (bookingId == null) {
        throw const MidtransException('ID booking tidak diterima dari server.');
      }
      final payment = await _midtransService.createQrisPayment(
        bookingId: bookingId,
      );
      if (!mounted) return;
      setState(() {
        _qrisPayment = payment;
        _bookingAmount = payment.amount;
        _processing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _checkPaymentStatus() async {
    final bookingId = _bookingId;
    if (bookingId == null) return;
    setState(() => _processing = true);
    try {
      final status = await _midtransService.getPaymentStatus(
        bookingId: bookingId,
      );
      await ref.read(bookingProvider.notifier).refresh();
      if (!mounted) return;
      setState(() => _processing = false);
      if (_bookingFromProvider(bookingId).isPaid) {
        await _openReceipt(_bookingFromProvider(bookingId));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status pembayaran: $status.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  BookingSummary _bookingFromProvider(int id) {
    return ref
        .read(bookingProvider)
        .firstWhere(
          (booking) => booking.id == id,
          orElse: () => widget.booking,
        );
  }

  Future<void> _openReceipt(BookingSummary booking) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ReceiptPage(booking: booking)),
    );
  }

  Future<Map<String, dynamic>> _registerBooking(String orderId) async {
    final booking = widget.booking;
    final response = await ref.read(apiServiceProvider).post('/bookings', {
      'fieldName': booking.fieldName,
      'fieldLocation': booking.fieldLocation,
      'courtName': booking.courtName,
      'date': booking.date,
      'time': booking.time,
      'durationHours': booking.durationHours,
      'paymentOrderId': orderId,
    });
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  String _formatRupiah(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

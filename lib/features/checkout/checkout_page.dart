import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/booking_summary.dart';
import '../../core/providers/booking_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key, required this.booking});
  final BookingSummary booking;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _paymentMethod = 'QRIS';
  bool _processing = false;

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
                  _Row(label: 'Venue', value: booking.fieldName),
                  _Row(label: 'Lokasi', value: booking.fieldLocation),
                  _Row(label: 'Tanggal', value: booking.date),
                  _Row(label: 'Jam', value: booking.time),
                  _Row(label: 'Harga', value: booking.price),
                  const Divider(),
                  _Row(label: 'Total', value: booking.total, bold: true),
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
          _PaymentOption(
            icon: Icons.qr_code_2_rounded,
            title: 'QRIS',
            selected: _paymentMethod == 'QRIS',
            onTap: () => setState(() => _paymentMethod = 'QRIS'),
          ),
          _PaymentOption(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Dompet digital',
            selected: _paymentMethod == 'Dompet digital',
            onTap: () => setState(() => _paymentMethod = 'Dompet digital'),
          ),
          if (_paymentMethod == 'QRIS')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Scan QRIS untuk membayar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data:
                          'FUTSALGO|ARENA-HIJAU|${booking.total}|${booking.date}|${booking.time}',
                      size: 210,
                    ),
                    Text(
                      'Total ${booking.total}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Setelah transfer, tekan tombol konfirmasi.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _processing ? null : _confirmPayment,
            child: _processing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Konfirmasi pembayaran $_paymentMethod'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _processing = true);
    final booking = widget.booking;
    await ref
        .read(bookingProvider.notifier)
        .addBooking(
          BookingSummary(
            fieldName: booking.fieldName,
            fieldLocation: booking.fieldLocation,
            date: booking.date,
            time: booking.time,
            price: booking.price,
            total: booking.total,
            status: 'Lunas via $_paymentMethod',
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran berhasil disimpan')),
    );
    Navigator.of(context).pop();
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? theme.colorScheme.primary : null,
      ),
    );
  }
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

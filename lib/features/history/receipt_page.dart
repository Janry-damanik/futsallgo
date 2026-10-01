import 'package:flutter/material.dart';

import '../../core/models/booking_summary.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.booking});

  final BookingSummary booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Struk pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: Color(0xFF16835D),
          ),
          const SizedBox(height: 12),
          Text(
            'Pembayaran berhasil',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.code == null
                ? 'Bukti pembayaran tersimpan.'
                : 'Kode ${booking.code}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ReceiptRow(label: 'Lapangan', value: booking.fieldName),
                  _ReceiptRow(label: 'Lokasi', value: booking.fieldLocation),
                  _ReceiptRow(label: 'Tanggal', value: booking.date),
                  _ReceiptRow(label: 'Waktu', value: booking.time),
                  _ReceiptRow(
                    label: 'Durasi',
                    value: '${booking.durationHours} jam',
                  ),
                  const Divider(height: 24),
                  _ReceiptRow(
                    label: 'Total dibayar',
                    value: booking.total,
                    bold: true,
                  ),
                  _ReceiptRow(
                    label: 'Status',
                    value: booking.status,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Kembali ke tiket'),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : null),
          ),
        ),
      ],
    ),
  );
}

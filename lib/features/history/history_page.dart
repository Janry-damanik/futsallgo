import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/booking_summary.dart';
import '../../core/providers/booking_provider.dart';
import '../checkout/checkout_page.dart';
import 'receipt_page.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: bookings.isEmpty
          ? const Center(child: Text('Belum ada booking.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BookingItem(
                item: bookings[index],
                onTap: () => _openBooking(context, bookings[index]),
              ),
            ),
    );
  }

  void _openBooking(BuildContext context, BookingSummary booking) {
    if (booking.isPaymentPending && booking.id != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              CheckoutPage(booking: booking, resumeExistingBooking: true),
        ),
      );
      return;
    }
    if (booking.isPaid) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ReceiptPage(booking: booking)),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detail booking'),
        content: Text('Status booking ini: ${booking.status}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _BookingItem extends StatelessWidget {
  const _BookingItem({required this.item, required this.onTap});

  final BookingSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fieldName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.date),
                    const SizedBox(height: 4),
                    Text(item.time),
                    const SizedBox(height: 8),
                    Text(
                      item.isPaymentPending
                          ? 'Ketuk untuk lanjut bayar'
                          : item.isPaid
                          ? 'Ketuk untuk lihat struk'
                          : 'Ketuk untuk lihat status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

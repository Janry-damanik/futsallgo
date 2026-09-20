import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/booking_summary.dart';
import '../../core/providers/admin_settings_provider.dart';
import '../checkout/checkout_page.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  final _dates = [
    'Senin, 12 Agustus',
    'Selasa, 13 Agustus',
    'Rabu, 14 Agustus',
    'Jumat, 16 Agustus',
  ];
  String _selectedDate = 'Senin, 12 Agustus';
  String _selectedSlot = '18.00';
  String _selectedCourt = 'Lapangan 1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(adminSettingsProvider);
    final courts = settings.courts;
    final selectedCourt = courts.contains(_selectedCourt)
        ? _selectedCourt
        : courts.first;
    final slots = _slotsBetween(
      settings.openTime,
      settings.closeTime,
    ).where((slot) => !settings.blockedSlots.contains(slot)).toList();
    final selectedSlot = slots.contains(_selectedSlot)
        ? _selectedSlot
        : slots.first;
    final time = '$selectedSlot - ${_nextHour(selectedSlot)}';
    final price = _rupiah(settings.hourlyPrice);

    return Scaffold(
      appBar: AppBar(title: Text('Booking ${settings.venueName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer_rounded,
                  size: 50,
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.venueName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(settings.address),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih lapangan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCourt,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.sports_soccer_rounded),
              border: OutlineInputBorder(),
            ),
            items: courts
                .map(
                  (court) => DropdownMenuItem(value: court, child: Text(court)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedCourt = value ?? selectedCourt),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih tanggal',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dates
                .map(
                  (date) => ChoiceChip(
                    label: Text(date),
                    selected: date == _selectedDate,
                    onSelected: (_) => setState(() => _selectedDate = date),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih jam',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (slots.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Semua slot sedang ditutup admin.'),
              ),
            ),
          if (slots.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: slots
                  .map(
                    (slot) => ChoiceChip(
                      label: Text(slot),
                      selected: slot == selectedSlot,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Lapangan', value: selectedCourt),
                  _DetailRow(label: 'Tanggal', value: _selectedDate),
                  _DetailRow(label: 'Jam', value: time),
                  _DetailRow(label: 'Harga', value: price),
                  _DetailRow(label: 'Total', value: price),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: slots.isEmpty
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutPage(
                        booking: BookingSummary(
                          fieldName: '${settings.venueName} - $selectedCourt',
                          fieldLocation: settings.address,
                          date: _selectedDate,
                          time: time,
                          price: price,
                          total: price,
                          status: 'Menunggu pembayaran',
                        ),
                      ),
                    ),
                  ),
            child: const Text('Lanjut ke pembayaran'),
          ),
        ],
      ),
    );
  }

  String _nextHour(String slot) {
    final hour = int.tryParse(slot.split('.').first) ?? 18;
    return '${(hour + 1).toString().padLeft(2, '0')}.00';
  }

  List<String> _slotsBetween(String open, String close) {
    final start = int.tryParse(open.split('.').first) ?? 8;
    final end = int.tryParse(close.split('.').first) ?? 22;
    return [
      for (var hour = start; hour < end; hour++)
        '${hour.toString().padLeft(2, '0')}.00',
    ];
  }

  String _rupiah(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

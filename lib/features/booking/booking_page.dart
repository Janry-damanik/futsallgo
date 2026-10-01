import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/booking_summary.dart';
import '../../core/providers/admin_settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../checkout/checkout_page.dart';
import 'court_details_page.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key, this.initialCourtName});

  final String? initialCourtName;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  static const _durations = [1, 2, 3, 4];

  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  String _selectedCourt = 'Lapangan 1';
  String _selectedSlot = '18.00';
  int _selectedDuration = 1;
  List<String> _availableStartTimes = [];
  Timer? _availabilityRefreshTimer;
  bool _loadingAvailability = true;
  String? _availabilityError;
  int _availabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    _dates = List.generate(7, (index) => firstDate.add(Duration(days: index)));
    _selectedDate = firstDate;
    _selectedCourt = widget.initialCourtName ?? _selectedCourt;
    _availabilityRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadAvailability());
    });
  }

  @override
  void dispose() {
    _availabilityRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(adminSettingsProvider);
    final courts = settings.courts;
    if (courts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Jadwal lapangan')),
        body: RefreshIndicator(
          onRefresh: () => ref.read(adminSettingsProvider.notifier).reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 280,
                child: Center(child: Text('Belum ada lapangan yang tersedia.')),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCourt = courts.contains(_selectedCourt)
        ? _selectedCourt
        : courts.first;
    final hourlyPrice =
        settings.courtPrices[selectedCourt] ?? settings.hourlyPrice;
    final slots = _availableStartTimes
        .where((time) => _startsInFuture(_selectedDate, time))
        .toList();
    final selectedSlot =
        _loadingAvailability || _availabilityError != null || slots.isEmpty
        ? null
        : slots.contains(_selectedSlot)
        ? _selectedSlot
        : slots.first;
    final total = hourlyPrice * _selectedDuration;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal lapangan')),
      body: RefreshIndicator(
        onRefresh: _refreshBooking,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _CourtImagePlaceholder(
              courtName: selectedCourt,
              imageUrl: settings.courtImages[selectedCourt],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => CourtDetailsPage(
                        courtName: selectedCourt,
                        description:
                            settings.courtDescriptions[selectedCourt] ?? '',
                        surface: settings.courtSurfaces[selectedCourt] ?? '',
                        imageUrl: settings.courtImages[selectedCourt],
                      ),
                    ),
                  );
                  if (mounted) {
                    await ref.read(adminSettingsProvider.notifier).reload();
                  }
                },
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Deskripsi & ulasan lapangan'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCourt.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Futsal  ·  ${_rupiah(hourlyPrice)} / jam',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCourt,
                    decoration: const InputDecoration(
                      labelText: 'Lapangan',
                      prefixIcon: Icon(Icons.sports_soccer_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: courts
                        .map(
                          (court) => DropdownMenuItem(
                            value: court,
                            child: Text(court),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCourt = value);
                      unawaited(_loadAvailability(courtName: value));
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Jadwal',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _monthYear(_selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final date = _dates[index];
                        return _DateOption(
                          date: date,
                          selected: _sameDate(date, _selectedDate),
                          onTap: () {
                            setState(() => _selectedDate = date);
                            unawaited(_loadAvailability(date: date));
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Durasi bermain',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _durations
                        .map(
                          (duration) => ChoiceChip(
                            label: Text('$duration jam'),
                            selected: duration == _selectedDuration,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: duration == _selectedDuration
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedDuration = duration);
                              unawaited(
                                _loadAvailability(durationHours: duration),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih jam mulai',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _loadingAvailability
                            ? 'Memuat...'
                            : '${slots.length} tersedia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingAvailability)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_availabilityError != null)
                    Center(
                      child: Column(
                        children: [
                          Text('Gagal memuat jam: $_availabilityError'),
                          TextButton(
                            onPressed: () => unawaited(_loadAvailability()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (slots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: Text(
                          'Tidak ada jam yang cocok untuk durasi ini.',
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 9,
                            crossAxisSpacing: 9,
                            mainAxisExtent: 46,
                          ),
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final selected = slot == selectedSlot;
                        return OutlinedButton(
                          onPressed: () => setState(() => _selectedSlot = slot),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            foregroundColor: selected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(slot),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(label: 'Lapangan', value: selectedCourt),
                          _DetailRow(
                            label: 'Tanggal',
                            value: _fullDate(_selectedDate),
                          ),
                          _DetailRow(
                            label: 'Waktu',
                            value: selectedSlot == null
                                ? '-'
                                : _timeRange(selectedSlot, _selectedDuration),
                          ),
                          _DetailRow(
                            label: 'Tarif per jam',
                            value: _rupiah(hourlyPrice),
                          ),
                          _DetailRow(
                            label: 'Durasi',
                            value: '$_selectedDuration jam',
                          ),
                          const Divider(height: 20),
                          _DetailRow(
                            label: 'Total',
                            value: _rupiah(total),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _rupiah(total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: selectedSlot == null
                    ? null
                    : () => _continueToCheckout(
                        settings.address,
                        selectedCourt,
                        selectedSlot,
                        hourlyPrice,
                        total,
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(150, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lanjut bayar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAvailability({
    String? courtName,
    DateTime? date,
    int? durationHours,
  }) async {
    final settings = ref.read(adminSettingsProvider);
    var selectedCourt = courtName ?? _selectedCourt;
    if (settings.courts.isEmpty) return;
    if (!settings.courts.contains(selectedCourt)) {
      selectedCourt = settings.courts.first;
    }
    final selectedDate = date ?? _selectedDate;
    final duration = durationHours ?? _selectedDuration;
    final requestId = ++_availabilityRequestId;

    if (mounted) {
      setState(() {
        _loadingAvailability = true;
        _availabilityError = null;
        _availableStartTimes = [];
      });
    }

    final query = Uri(
      queryParameters: {
        'courtName': selectedCourt,
        'date': _fullDate(selectedDate),
        'durationHours': '$duration',
      },
    ).query;

    try {
      final response = await ref
          .read(apiServiceProvider)
          .get('/availability?$query');
      final times = (response['data'] as List<dynamic>)
          .map((time) => time.toString())
          .toList();
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _availableStartTimes = times;
        _loadingAvailability = false;
        _selectedSlot = times.contains(_selectedSlot)
            ? _selectedSlot
            : (times.isEmpty ? '' : times.first);
      });
    } on Exception catch (error) {
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _availableStartTimes = [];
        _loadingAvailability = false;
        _availabilityError = error.toString();
      });
    }
  }

  Future<void> _refreshBooking() async {
    await ref.read(adminSettingsProvider.notifier).reload();
    await _loadAvailability();
  }

  void _continueToCheckout(
    String address,
    String court,
    String start,
    int hourlyPrice,
    int total,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutPage(
          booking: BookingSummary(
            fieldName: court,
            fieldLocation: address,
            date: _fullDate(_selectedDate),
            time: _timeRange(start, _selectedDuration),
            price: _rupiah(hourlyPrice),
            total: _rupiah(total),
            status: 'Menunggu pembayaran',
            courtName: court,
            durationHours: _selectedDuration,
          ),
        ),
      ),
    );
  }

  String _timeRange(String start, int duration) {
    final startMinutes = _clockToMinutes(start);
    return '$start - ${_formatClock(startMinutes + duration * 60)}';
  }

  int _clockToMinutes(String value) {
    final parts = value.replaceAll(':', '.').split('.');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return hour * 60 + minute;
  }

  bool _startsInFuture(DateTime date, String time) {
    final now = DateTime.now();
    final startMinutes = _clockToMinutes(time);
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );
    return startTime.isAfter(now);
  }

  String _formatClock(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';
  }

  String _fullDate(DateTime date) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _monthYear(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _rupiah(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
}

class _CourtImagePlaceholder extends StatelessWidget {
  const _CourtImagePlaceholder({required this.courtName, this.imageUrl});

  final String courtName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176651), Color(0xFF192E50)],
        ),
      ),
      child: Stack(
        children: [
          if (imageUrl case final url?)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                maxWidthDiskCache: 1600,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFF101619),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00D47A),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFF176651),
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 96,
                    color: Colors.white54,
                  ),
                ),
              ),
            )
          else
            Positioned(
              right: 14,
              bottom: -20,
              child: Icon(
                Icons.sports_soccer_rounded,
                size: 190,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          if (imageUrl != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD341),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FUTSAL',
                style: TextStyle(
                  color: Color(0xFF192E50),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Text(
              courtName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateOption extends StatelessWidget {
  const _DateOption({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return SizedBox(
      width: 68,
      child: Material(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdays[date.weekday - 1],
                style: TextStyle(color: foreground, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day} ${months[date.month - 1]}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

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
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/field_model.dart';
import '../../core/providers/admin_settings_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/router/routes.dart';
import '../booking/booking_page.dart';
import '../history/history_page.dart';
import 'sports_news_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        onOpenBooking: () => _selectTab(1),
        onOpenTickets: () => _selectTab(2),
      ),
      const BookingPage(),
      const HistoryPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Tiket',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({required this.onOpenBooking, required this.onOpenTickets});

  final VoidCallback onOpenBooking;
  final VoidCallback onOpenTickets;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _promoController = PageController();
  int _promoIndex = 0;
  int _newsRefreshKey = 0;
  bool _sortByPrice = false;

  @override
  void dispose() {
    _searchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(adminSettingsProvider);
    final promoCount = settings.promos.isEmpty ? 2 : settings.promos.length;
    final activePromoIndex = _promoIndex < promoCount
        ? _promoIndex
        : promoCount - 1;
    final fields = settings.courts.map(
      (court) => FieldModel(
        id: court,
        name: court,
        price: _rupiah(settings.courtPrices[court] ?? settings.hourlyPrice),
        category: 'Futsal',
        color: const Color(0xFF1F7A8C),
        imageUrl: settings.courtImages[court],
        averageRating: settings.courtRatings[court] ?? 0,
        reviewCount: settings.courtReviewCounts[court] ?? 0,
      ),
    );
    final filteredFields = fields.where((field) {
      final query = _searchController.text.toLowerCase().trim();
      if (query.isEmpty) {
        return true;
      }
      return field.name.toLowerCase().contains(query) ||
          field.category.toLowerCase().contains(query);
    }).toList();
    if (_sortByPrice) {
      filteredFields.sort((first, second) {
        final firstPrice =
            settings.courtPrices[first.id] ?? settings.hourlyPrice;
        final secondPrice =
            settings.courtPrices[second.id] ?? settings.hourlyPrice;
        return firstPrice.compareTo(secondPrice);
      });
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari lapangan',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  tooltip: 'Bantuan',
                  onPressed: () => _showSupport(context, settings.phone),
                  icon: const Icon(Icons.headset_mic_outlined),
                ),
                IconButton(
                  tooltip: 'Profil',
                  onPressed: () => context.push(AppRoutes.profile),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Tiket saya',
                  onPressed: widget.onOpenTickets,
                  icon: const Icon(Icons.confirmation_number_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(adminSettingsProvider.notifier).reload(),
                  ref.read(bookingProvider.notifier).refresh(),
                ]);
                if (mounted) setState(() => _newsRefreshKey++);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  SizedBox(
                    height: 178,
                    child: PageView.builder(
                      controller: _promoController,
                      onPageChanged: (index) =>
                          setState(() => _promoIndex = index),
                      itemCount: promoCount,
                      itemBuilder: (context, index) {
                        if (settings.promos.isNotEmpty) {
                          final promo = settings.promos[index];
                          return _PromoSlide(
                            eyebrow: promo.eyebrow,
                            title: promo.title,
                            subtitle: promo.subtitle,
                            buttonLabel: promo.buttonLabel,
                            imageUrl: promo.imageUrl,
                            icon: Icons.sports_soccer_rounded,
                            onPressed: widget.onOpenBooking,
                          );
                        }
                        return _PromoSlide(
                          title: index == 0
                              ? 'Waktunya masuk lapangan'
                              : 'Satu tim, satu tujuan',
                          subtitle: index == 0
                              ? 'Pilih sesi berikutnya bersama timmu.'
                              : 'Siapkan jadwal mainmu hari ini.',
                          icon: index == 0
                              ? Icons.sports_soccer_rounded
                              : Icons.stadium_rounded,
                          onPressed: widget.onOpenBooking,
                          alternate: index.isOdd,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      promoCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: activePromoIndex == index ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: activePromoIndex == index
                              ? const Color(0xFF192E50)
                              : const Color(0xFFD5DAE2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Fasilitas venue',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (settings.facilities.isEmpty)
                    Text(
                      'Informasi fasilitas belum tersedia.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: settings.facilities
                          .map((facility) => _FacilityChip(name: facility))
                          .toList(),
                    ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lapangan tersedia',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${filteredFields.length} pilihan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<bool>(
                        tooltip: 'Urutkan lapangan',
                        initialValue: _sortByPrice,
                        onSelected: (value) =>
                            setState(() => _sortByPrice = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: false,
                            child: Text('Rekomendasi'),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Text('Harga terendah'),
                          ),
                        ],
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 19),
                            const SizedBox(width: 5),
                            Text(_sortByPrice ? 'Termurah' : 'Urutkan'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filteredFields.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 42),
                      child: Text(
                        'Lapangan tidak ditemukan',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  else
                    SizedBox(
                      height: 292,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredFields.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => _FieldCard(
                          field: filteredFields[index],
                          index: index,
                          onPressed: () => context.push(
                            AppRoutes.booking,
                            extra: filteredFields[index].id,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  SportsNewsSection(key: ValueKey(_newsRefreshKey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rupiah(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} / jam';

  void _showSupport(BuildContext context, String phone) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bantuan'),
        content: Text('Hubungi pengelola di $phone.'),
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

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({
    this.eyebrow = 'FUTSALGO  /  LAPANGAN',
    required this.title,
    required this.subtitle,
    this.buttonLabel = 'Pesan lapangan',
    required this.icon,
    required this.onPressed,
    this.alternate = false,
    this.imageUrl,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;
  final bool alternate;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = alternate
        ? const Color(0xFF125C4E)
        : const Color(0xFF192E50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                background,
                alternate ? const Color(0xFF27826D) : const Color(0xFF31547A),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl case final url? when url.isNotEmpty)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(color: background),
                ),
              if (imageUrl != null && imageUrl!.isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFFFD341),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          SizedBox(
                            height: 34,
                            child: FilledButton(
                              onPressed: onPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD341),
                                foregroundColor: const Color(0xFF192E50),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              child: Text(buttonLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (imageUrl == null || imageUrl!.isEmpty) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 96,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.stadium_rounded,
                              size: 94,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            Icon(
                              icon,
                              size: 62,
                              color: const Color(0xFFFFD341),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.index,
    required this.onPressed,
  });

  final FieldModel field;
  final int index;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final imageColors = index.isEven
        ? const [Color(0xFF176651), Color(0xFF2D9673)]
        : const [Color(0xFF243B5E), Color(0xFF517A8B)];

    return SizedBox(
      width: 204,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: imageColors,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (field.imageUrl case final imageUrl?
                            when imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Align(
                                alignment: Alignment.bottomRight,
                                child: Icon(
                                  Icons.sports_soccer_rounded,
                                  size: 142,
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: -8,
                            bottom: -15,
                            child: Icon(
                              Icons.sports_soccer_rounded,
                              size: 142,
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD341),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FUTSAL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF192E50),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      field.price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF176651),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFE3A800),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            field.reviewCount == 0
                                ? 'Belum ada ulasan'
                                : '${field.averageRating.toStringAsFixed(1)} · ${field.reviewCount} ulasan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton(
                        onPressed: onPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF192E50),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Pesan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final normalized = name.toLowerCase();
    final icon = normalized.contains('mandi') || normalized.contains('toilet')
        ? Icons.wc_rounded
        : normalized.contains('kantin') || normalized.contains('makan')
        ? Icons.restaurant_rounded
        : normalized.contains('parkir')
        ? Icons.local_parking_rounded
        : normalized.contains('musala') || normalized.contains('mushola')
        ? Icons.mosque_rounded
        : normalized.contains('wifi')
        ? Icons.wifi_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF176651)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/booking_summary.dart';
import '../../core/models/promo_banner.dart';
import '../../core/providers/admin_settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../../core/router/routes.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    if (user?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Kembali ke Home'),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Admin'),
          actions: [
            IconButton(
              tooltip: 'Keluar',
              onPressed: () async {
                await ref.read(authUserProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Ringkasan'),
              Tab(icon: Icon(Icons.sports_soccer_rounded), text: 'Lapangan'),
              Tab(icon: Icon(Icons.campaign_rounded), text: 'Banner'),
              Tab(icon: Icon(Icons.schedule_rounded), text: 'Jadwal'),
              Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Booking'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _CourtsTab(),
            _PromosTab(),
            _ScheduleTab(),
            _BookingsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adminSettingsProvider);
    final bookings = ref.watch(bookingProvider);
    final paid = bookings
        .where((item) => item.status.startsWith('Lunas'))
        .length;
    final pending = bookings
        .where((item) => item.status.contains('Menunggu'))
        .length;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Kontrol operasional',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola lapangan, tarif per jam, booking, dan jadwal operasional.',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Booking',
                value: '${bookings.length}',
                icon: Icons.calendar_month_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Menunggu',
                value: '$pending',
                icon: Icons.pending_actions_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Lunas',
                value: '$paid',
                icon: Icons.verified_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: const Text('Informasi usaha'),
            subtitle: Text(
              '${settings.venueName}\n${settings.address}\n${settings.phone}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Edit informasi usaha',
              onPressed: () => _editVenue(context, ref, settings),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payments_rounded),
            title: const Text('Tarif dasar per jam'),
            subtitle: Text(_rupiah(settings.hourlyPrice)),
            trailing: IconButton(
              tooltip: 'Edit tarif dasar',
              onPressed: () => _editPrice(context, ref, settings),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sports_soccer_rounded),
            title: const Text('Lapangan aktif'),
            subtitle: Text(
              '${settings.courts.length} lapangan: ${settings.courts.join(', ')}',
            ),
          ),
        ),
      ],
    );
  }
}

class _CourtsTab extends ConsumerWidget {
  const _CourtsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adminSettingsProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'Daftar lapangan',
          action: IconButton(
            tooltip: 'Tambah lapangan',
            onPressed: () => _addCourt(context, ref),
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ),
        const SizedBox(height: 8),
        ...settings.courts.map(
          (court) => Card(
            child: ListTile(
              leading: _courtImageThumbnail(settings.courtImages[court]),
              title: Text(court),
              subtitle: Text(
                'Aktif · ${_rupiah(settings.courtPrices[court] ?? settings.hourlyPrice)}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Unggah foto lapangan',
                    onPressed: () => _uploadCourtImage(context, ref, court),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  IconButton(
                    tooltip: 'Atur harga per jam',
                    onPressed: () => _editCourtPrice(
                      context,
                      ref,
                      court,
                      settings.courtPrices[court] ?? settings.hourlyPrice,
                    ),
                    icon: const Icon(Icons.payments_outlined),
                  ),
                  IconButton(
                    tooltip: 'Hapus lapangan',
                    onPressed: settings.courts.length == 1
                        ? null
                        : () => ref
                              .read(adminSettingsProvider.notifier)
                              .removeCourt(court),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Atur tarif per jam untuk setiap lapangan. Harga ini tampil langsung di beranda pelanggan.',
            ),
          ),
        ),
      ],
    );
  }
}

Widget _courtImageThumbnail(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return const Icon(Icons.sports_soccer_rounded);
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      imageUrl,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.sports_soccer_rounded),
    ),
  );
}

class _PromosTab extends ConsumerWidget {
  const _PromosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(adminSettingsProvider).promos;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'Banner beranda',
          action: IconButton(
            tooltip: 'Tambah banner',
            onPressed: () => _editPromo(context, ref),
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ),
        const SizedBox(height: 8),
        if (promos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Belum ada banner.'),
          ),
        ...promos.map(
          (promo) => Card(
            child: ListTile(
              leading: _promoThumbnail(promo.imageUrl),
              title: Text(
                promo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${promo.eyebrow} · ${promo.subtitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Edit tulisan banner',
                    onPressed: () => _editPromo(context, ref, promo),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Pasang foto banner',
                    onPressed: () => _uploadPromoImage(context, ref, promo),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  IconButton(
                    tooltip: 'Hapus banner',
                    onPressed: () => _deletePromo(context, ref, promo),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _promoThumbnail(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return const SizedBox(
      width: 64,
      height: 52,
      child: Icon(Icons.campaign_rounded),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      imageUrl,
      width: 64,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(
        width: 64,
        height: 52,
        child: Icon(Icons.campaign_rounded),
      ),
    ),
  );
}

Future<void> _editPromo(
  BuildContext context,
  WidgetRef ref, [
  PromoBanner? promo,
]) async {
  final eyebrow = TextEditingController(
    text: promo?.eyebrow ?? 'FUTSALGO / LAPANGAN',
  );
  final title = TextEditingController(text: promo?.title ?? '');
  final subtitle = TextEditingController(text: promo?.subtitle ?? '');
  final buttonLabel = TextEditingController(
    text: promo?.buttonLabel ?? 'Pesan lapangan',
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(promo == null ? 'Tambah banner' : 'Edit banner'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eyebrow,
                decoration: const InputDecoration(labelText: 'Tulisan kecil'),
              ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: subtitle,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              TextField(
                controller: buttonLabel,
                decoration: const InputDecoration(labelText: 'Tulisan tombol'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    if (eyebrow.text.trim().isEmpty ||
        title.text.trim().isEmpty ||
        buttonLabel.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulisan kecil, judul, dan tombol wajib diisi.'),
        ),
      );
    } else {
      final value = PromoBanner(
        id: promo?.id ?? 0,
        eyebrow: eyebrow.text.trim(),
        title: title.text.trim(),
        subtitle: subtitle.text.trim(),
        buttonLabel: buttonLabel.text.trim(),
        imageUrl: promo?.imageUrl,
      );
      try {
        if (promo == null) {
          await ref.read(adminSettingsProvider.notifier).createPromo(value);
        } else {
          await ref.read(adminSettingsProvider.notifier).updatePromo(value);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner berhasil disimpan.')),
          );
        }
      } catch (error) {
        _showPromoError(context, error);
      }
    }
  }
  eyebrow.dispose();
  title.dispose();
  subtitle.dispose();
  buttonLabel.dispose();
}

Future<void> _uploadPromoImage(
  BuildContext context,
  WidgetRef ref,
  PromoBanner promo,
) async {
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null) return;
    await ref
        .read(adminSettingsProvider.notifier)
        .uploadPromoImage(
          promo.id,
          bytes: await image.readAsBytes(),
          filename: image.name,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto banner berhasil diperbarui.')),
      );
    }
  } catch (error) {
    _showPromoError(context, error);
  }
}

Future<void> _deletePromo(
  BuildContext context,
  WidgetRef ref,
  PromoBanner promo,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus banner?'),
      content: Text('Banner "${promo.title}" akan dihapus.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(adminSettingsProvider.notifier).removePromo(promo.id);
  } catch (error) {
    _showPromoError(context, error);
  }
}

void _showPromoError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adminSettingsProvider);
    final slots = _slotsBetween(settings.openTime, settings.closeTime);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'Jam operasional',
          action: IconButton(
            tooltip: 'Edit jam',
            onPressed: () => _editSchedule(context, ref, settings),
            icon: const Icon(Icons.edit_calendar_rounded),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.access_time_rounded),
            title: Text('${settings.openTime} - ${settings.closeTime}'),
            subtitle: const Text('Jam buka dan tutup'),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: 'Kontrol slot', action: const SizedBox.shrink()),
        const Text('Ketuk slot untuk memblokir atau membuka jadwal booking.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final blocked = settings.blockedSlots.contains(slot);
            return FilterChip(
              label: Text(slot),
              selected: blocked,
              selectedColor: Colors.red.shade100,
              avatar: Icon(
                blocked
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              onSelected: (_) => ref
                  .read(adminSettingsProvider.notifier)
                  .toggleBlockedSlot(slot),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          title: 'Semua booking pelanggan',
          action: Text('${bookings.length} data'),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada booking pelanggan.'),
            ),
          ),
        ...bookings.asMap().entries.map(
          (entry) => _BookingAdminCard(index: entry.key, booking: entry.value),
        ),
      ],
    );
  }
}

class _BookingAdminCard extends ConsumerWidget {
  const _BookingAdminCard({required this.index, required this.booking});
  final int index;
  final BookingSummary booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.fieldName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (status) => ref
                      .read(bookingProvider.notifier)
                      .updateStatus(index, status),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'Menunggu pembayaran',
                      child: Text('Menunggu pembayaran'),
                    ),
                    PopupMenuItem(
                      value: 'Dikonfirmasi',
                      child: Text('Dikonfirmasi'),
                    ),
                    PopupMenuItem(value: 'Selesai', child: Text('Selesai')),
                    PopupMenuItem(
                      value: 'Dibatalkan',
                      child: Text('Dibatalkan'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${booking.date} - ${booking.time}'),
            Text(booking.total),
            Row(
              children: [
                Chip(label: Text(booking.status)),
                const Spacer(),
                IconButton(
                  tooltip: 'Hapus booking',
                  onPressed: () =>
                      ref.read(bookingProvider.notifier).removeBooking(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      action,
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

Future<void> _addCourt(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tambah lapangan'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nama lapangan',
          hintText: 'Contoh: Lapangan 2',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Tambah'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(adminSettingsProvider.notifier).addCourt(controller.text);
  }
  controller.dispose();
}

Future<void> _uploadCourtImage(
  BuildContext context,
  WidgetRef ref,
  String court,
) async {
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) return;

    await ref
        .read(adminSettingsProvider.notifier)
        .uploadCourtImage(
          court,
          bytes: await image.readAsBytes(),
          filename: image.name,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto $court berhasil diperbarui.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<void> _editCourtPrice(
  BuildContext context,
  WidgetRef ref,
  String court,
  int currentPrice,
) async {
  final controller = TextEditingController(text: currentPrice.toString());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Tarif $court'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Harga per jam',
          prefixText: 'Rp ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  final price = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
  if (confirmed == true && price != null && price > 0) {
    await ref
        .read(adminSettingsProvider.notifier)
        .updateCourtPrice(court, price);
  }
  controller.dispose();
}

Future<void> _editVenue(
  BuildContext context,
  WidgetRef ref,
  AdminSettings settings,
) async {
  final name = TextEditingController(text: settings.venueName);
  final address = TextEditingController(text: settings.address);
  final phone = TextEditingController(text: settings.phone);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Informasi usaha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nama usaha'),
          ),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Alamat'),
          ),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref
        .read(adminSettingsProvider.notifier)
        .update(
          settings.copyWith(
            venueName: name.text,
            address: address.text,
            phone: phone.text,
          ),
        );
  }
  name.dispose();
  address.dispose();
  phone.dispose();
}

Future<void> _editPrice(
  BuildContext context,
  WidgetRef ref,
  AdminSettings settings,
) async {
  final price = TextEditingController(text: settings.hourlyPrice.toString());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Atur harga per jam'),
      content: TextField(
        controller: price,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Harga',
          prefixText: 'Rp ',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  final value = int.tryParse(price.text.replaceAll(RegExp(r'[^0-9]'), ''));
  if (confirmed == true && value != null && value > 0) {
    await ref
        .read(adminSettingsProvider.notifier)
        .update(settings.copyWith(hourlyPrice: value));
  }
  price.dispose();
}

Future<void> _editSchedule(
  BuildContext context,
  WidgetRef ref,
  AdminSettings settings,
) async {
  final open = TextEditingController(text: settings.openTime);
  final close = TextEditingController(text: settings.closeTime);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Jam operasional'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: open,
              decoration: const InputDecoration(
                labelText: 'Buka',
                hintText: '08.00',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: close,
              decoration: const InputDecoration(
                labelText: 'Tutup',
                hintText: '22.00',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref
        .read(adminSettingsProvider.notifier)
        .update(settings.copyWith(openTime: open.text, closeTime: close.text));
  }
  open.dispose();
  close.dispose();
}

List<String> _slotsBetween(String open, String close) {
  final start = int.tryParse(open.split('.').first) ?? 8;
  final end = close == '24.00'
      ? 24
      : int.tryParse(close.split('.').first) ?? 22;
  return [
    for (var hour = start; hour < end; hour++)
      '${hour.toString().padLeft(2, '0')}.00',
  ];
}

String _rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} / jam';

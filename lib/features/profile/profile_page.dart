import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/router/routes.dart';
import '../../core/theme/theme_mode_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).valueOrNull;
    final name = user?.name ?? '-';
    final email = user?.email ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileTile(
            title: 'Edit profil',
            icon: Icons.edit_rounded,
            onTap: () => _showEditProfile(context, ref, name),
          ),
          _ProfileTile(
            title: 'Metode pembayaran',
            icon: Icons.payment_rounded,
            onTap: () => _showPaymentMethods(context),
          ),
          _ProfileTile(
            title: 'Pengaturan',
            icon: Icons.settings_rounded,
            onTap: () => _showSettings(context, ref),
          ),
          _ProfileTile(
            title: 'Bantuan',
            icon: Icons.help_outline_rounded,
            onTap: () => _showHelp(context),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authUserProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await ref.read(authUserProvider.notifier).updateProfile(name);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui')),
                  );
                }
              } on Exception catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.qr_code_2_rounded),
              title: Text('QRIS'),
              subtitle: Text('Aktif untuk pembayaran booking'),
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet_rounded),
              title: Text('Dompet digital'),
              subtitle: Text('Pilih saat checkout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Tema aplikasi'),
              subtitle: Text('Pilih tampilan yang nyaman'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: ref.read(themeModeProvider),
              title: const Text('Mengikuti sistem'),
              onChanged: (value) {
                if (value != null)
                  ref.read(themeModeProvider.notifier).setMode(value);
                Navigator.pop(sheetContext);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: ref.read(themeModeProvider),
              title: const Text('Terang'),
              onChanged: (value) {
                if (value != null)
                  ref.read(themeModeProvider.notifier).setMode(value);
                Navigator.pop(sheetContext);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: ref.read(themeModeProvider),
              title: const Text('Gelap'),
              onChanged: (value) {
                if (value != null)
                  ref.read(themeModeProvider.notifier).setMode(value);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Bantuan'),
        content: Text(
          'Pilih lapangan dan jadwal, bayar melalui QRIS, lalu cek status booking di menu Riwayat. Hubungi pengelola jika butuh bantuan.',
        ),
        actions: [CloseButton()],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/router/routes.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty ||
        password.isEmpty ||
        (_isRegister && _nameController.text.trim().isEmpty)) {
      _showMessage('Lengkapi semua kolom terlebih dahulu.');
      return;
    }
    if (_isRegister && password.length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await ref
            .read(authUserProvider.notifier)
            .signUp(_nameController.text, email, password);
        if (mounted) {
          _showMessage(
            'Email verifikasi sudah dikirim. Cek inbox kamu, lalu masuk kembali.',
          );
          setState(() => _isRegister = false);
        }
      } else {
        await ref.read(authUserProvider.notifier).signIn(email, password);
        if (mounted) {
          final user = ref.read(authUserProvider).valueOrNull;
          context.go(user?.isAdmin == true ? AppRoutes.admin : AppRoutes.home);
        }
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Isi email dan password untuk mengirim ulang verifikasi.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authUserProvider.notifier)
          .resendVerificationEmail(email, password);
      if (mounted) _showMessage('Email verifikasi dikirim ulang.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.sports_soccer_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isRegister ? 'Buat akun FutsalGo' : 'Masuk ke FutsalGo',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegister
                      ? 'Verifikasi email untuk mengamankan akunmu.'
                      : 'Gunakan akun yang sudah terverifikasi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_isRegister) ...[
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isRegister
                                ? 'Daftar dan kirim verifikasi'
                                : 'Masuk',
                          ),
                  ),
                ),
                if (!_isRegister)
                  TextButton(
                    onPressed: _loading ? null : _resendVerification,
                    child: const Text('Kirim ulang verifikasi email'),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegister ? 'Sudah punya akun?' : 'Belum punya akun?',
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _isRegister = !_isRegister),
                      child: Text(_isRegister ? 'Masuk' : 'Daftar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

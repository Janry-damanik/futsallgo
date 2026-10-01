import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/admin_settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/booking_provider.dart';
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
  bool _verificationPending = false;
  bool _loading = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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
    if (_isRegister && password.length < 8) {
      _showMessage('Password minimal 8 karakter.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await ref
            .read(authUserProvider.notifier)
            .signUp(_nameController.text, email, password);
        if (mounted) {
          setState(() => _verificationPending = true);
          _showMessage('Kode OTP verifikasi dikirim ke $email.');
        }
        return;
      } else {
        await ref.read(authUserProvider.notifier).signIn(email, password);
      }
      await Future.wait([
        ref.read(bookingProvider.notifier).refresh(),
        ref.read(adminSettingsProvider.notifier).reload(),
      ]);
      if (mounted) {
        final user = ref.read(authUserProvider).valueOrNull;
        context.go(user?.isAdmin == true ? AppRoutes.admin : AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString();
        if (!_isRegister && message.contains('Email belum diverifikasi')) {
          setState(() => _verificationPending = true);
          _showMessage('Masukkan kode OTP yang dikirim ke email sebelum masuk.');
        } else {
          _showMessage(message);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerificationOtp() async {
    setState(() => _loading = true);
    try {
      final response = await ref
          .read(authUserProvider.notifier)
          .resendVerificationOtp(_emailController.text.trim());
      if (mounted) {
        if (response['status'] == 'not_required') {
          _returnToLogin();
          _showMessage('OTP tidak diperlukan. Silakan masuk dengan akun Anda.');
        } else {
          _showMessage('Kode OTP dikirim ulang ke email.');
        }
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final code = _otpController.text.trim();

    if (email.isEmpty || code.length != 6) {
      _showMessage('Masukkan 6 digit kode OTP yang valid.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authUserProvider.notifier).verifyEmail(email, code);
      if (mounted) {
        setState(() => _verificationPending = false);
        _showMessage('Email berhasil diverifikasi. Silakan masuk.');
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _returnToLogin() {
    setState(() {
      _verificationPending = false;
      _isRegister = false;
      _otpController.clear();
      _passwordController.clear();
    });
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
                  _verificationPending
                      ? 'Verifikasi email'
                      : _isRegister
                      ? 'Buat akun FutsalGo'
                      : 'Masuk ke FutsalGo',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _verificationPending
                      ? 'Masukkan kode OTP yang dikirim ke email untuk mengaktifkan akun.'
                      : _isRegister
                      ? 'Verifikasi email untuk mengaktifkan akun.'
                      : 'Masuk dengan akun FutsalGo kamu.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_isRegister && !_verificationPending) ...[
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
                  enabled: !_verificationPending,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                if (_verificationPending)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              size: 34,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _emailController.text.trim(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kode OTP berlaku selama 10 menit.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Kode OTP 6 digit',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                    ],
                  )
                else
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
                    onPressed: _loading
                        ? null
                        : _verificationPending
                            ? _verifyOtp
                            : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _verificationPending ? 'Verifikasi OTP' : _isRegister ? 'Daftar' : 'Masuk',
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_verificationPending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _loading ? null : _resendVerificationOtp,
                        child: const Text('Kirim ulang OTP'),
                      ),
                      TextButton(
                        onPressed: _loading ? null : _returnToLogin,
                        child: const Text('Kembali'),
                      ),
                    ],
                  )
                else
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

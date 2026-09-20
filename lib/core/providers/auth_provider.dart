import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../theme/theme_mode_controller.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final firebaseAuthProvider = Provider<FirebaseAuth?>(
  (ref) => Firebase.apps.isEmpty ? null : FirebaseAuth.instance,
);

final authUserProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      return AuthController(
        ref.watch(firebaseAuthProvider),
        ref.watch(sharedPreferencesProvider),
      );
    });

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._auth, this._prefs) : super(const AsyncValue.data(null)) {
    _loadCurrentUser();
  }

  final FirebaseAuth? _auth;
  final SharedPreferences _prefs;
  static const _userKey = 'auth_user';
  static const adminEmails = <String>{'admin@futsalgo.com'};
  static const adminUids = <String>{'4zu9Qc4UwhdA3X5vYZeFByN6kcD3'};

  static Future<bool> isAdminUser(User user) async {
    final token = await user.getIdTokenResult();
    return token.claims?['admin'] == true ||
        adminEmails.contains((user.email ?? '').toLowerCase()) ||
        adminUids.contains(user.uid);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _requireAuth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      await user?.reload();
      final currentUser = _requireAuth().currentUser;
      if (currentUser == null) {
        throw const AuthFlowException('Akun tidak ditemukan.');
      }
      if (!currentUser.emailVerified) {
        await _requireAuth().signOut();
        throw const AuthFlowException(
          'Email belum terverifikasi. Cek inbox dan klik tautan verifikasi.',
        );
      }
      await _saveUser(currentUser);
    } on FirebaseAuthException catch (error, stackTrace) {
      final message = switch (error.code) {
        'invalid-credential' ||
        'wrong-password' => 'Email atau password salah.',
        'user-not-found' => 'Akun dengan email tersebut belum terdaftar.',
        'invalid-email' => 'Format email tidak valid.',
        'user-disabled' => 'Akun ini dinonaktifkan.',
        _ => error.message ?? 'Login gagal.',
      };
      state = AsyncValue.error(AuthFlowException(message), stackTrace);
      throw AuthFlowException(message);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _requireAuth().createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFlowException('Pendaftaran gagal.');
      }
      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();
      await _requireAuth().signOut();
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (error, stackTrace) {
      final message = switch (error.code) {
        'email-already-in-use' => 'Email sudah digunakan.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Password minimal 6 karakter.',
        _ => error.message ?? 'Pendaftaran gagal.',
      };
      state = AsyncValue.error(AuthFlowException(message), stackTrace);
      throw AuthFlowException(message);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resendVerificationEmail(String email, String password) async {
    final credential = await _requireAuth().signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();
    await _requireAuth().signOut();
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    await _prefs.remove(_userKey);
    state = const AsyncValue.data(null);
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = _auth?.currentUser;
    if (currentUser == null || !currentUser.emailVerified) return;
    await _saveUser(currentUser);
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw const AuthFlowException(
        'Firebase belum dikonfigurasi. Jalankan flutterfire configure terlebih dahulu.',
      );
    }
    return auth;
  }

  Future<void> _saveUser(User user) async {
    final isAdmin = await isAdminUser(user);
    final authUser = AuthUser(
      id: user.uid,
      name: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : 'Pengguna FutsalGo',
      email: user.email ?? '',
      role: isAdmin ? 'admin' : 'pelanggan',
    );
    await _prefs.setString(_userKey, authUser.email);
    state = AsyncValue.data(authUser);
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);
  final String message;

  @override
  String toString() => message;
}

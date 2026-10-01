import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../theme/theme_mode_controller.dart';

const _apiTokenKey = 'api_token';

final apiServiceProvider = Provider<ApiService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiService(tokenReader: () => prefs.getString(_apiTokenKey));
});

final authUserProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      return AuthController(
        ref.watch(apiServiceProvider),
        ref.watch(sharedPreferencesProvider),
      );
    });

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._api, this._prefs) : super(const AsyncValue.loading()) {
    _restoreFuture = _restoreSession();
  }

  final ApiService _api;
  final SharedPreferences _prefs;
  late final Future<void> _restoreFuture;

  Future<AuthUser?> waitForSession() async {
    await _restoreFuture;
    return state.valueOrNull;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _acceptSession(
        await _api.post('/auth/login', {'email': email, 'password': password}),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _api.post('/auth/register', {
        'name': name.trim(),
        'email': email,
        'password': password,
      });
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendVerificationOtp(String email) async {
    return _api.post('/auth/otp/resend', {'email': email});
  }

  Future<void> verifyEmail(String email, String code) async {
    await _api.post('/auth/verify-email', {'email': email, 'code': code});
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout', {});
    } on Exception {
      // Clear the local session even when the server cannot be reached.
    } finally {
      await _clearSession();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> updateProfile(String name) async {
    final response = await _api.patch('/auth/profile', {'name': name.trim()});
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    state = AsyncValue.data(user);
  }

  Future<void> _restoreSession() async {
    final token = _prefs.getString(_apiTokenKey);
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final response = await _api.get('/auth/me');
      state = AsyncValue.data(
        AuthUser.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
      );
    } on ApiException catch (error, stackTrace) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearSession();
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _acceptSession(Map<String, dynamic> response) async {
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const AuthFlowException('Token login tidak diterima dari server.');
    }
    await _prefs.setString(_apiTokenKey, token);
    state = AsyncValue.data(
      AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<void> _clearSession() async {
    await _prefs.remove(_apiTokenKey);
    await _prefs.remove('admin_settings');
  }
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);
  final String message;

  @override
  String toString() => message;
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';

// ── Domain models ─────────────────────────────────────────────────────────────

class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id:    json['id'] as int,
    name:  json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role:  json['role'] as String? ?? 'app_user',
  );

  bool get isAdmin => role != 'app_user';
}

class AuthState {
  final AppUser? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({AppUser? user, bool? isLoggedIn, bool? isLoading, String? error}) =>
    AuthState(
      user:      user      ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading  ?? this.isLoading,
      error:     error,
    );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final hasTokens = await TokenStorage.hasTokens();
    if (!hasTokens) return const AuthState();

    // Try to restore session
    try {
      final response = await ApiClient.dio.get('/auth/me');
      final user     = AppUser.fromJson(response.data['user'] as Map<String, dynamic>);
      return AuthState(user: user, isLoggedIn: true);
    } catch (_) {
      await TokenStorage.clear();
      return const AuthState();
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final tokens = response.data['tokens'] as Map<String, dynamic>;
      final user   = AppUser.fromJson(response.data['user'] as Map<String, dynamic>);

      await TokenStorage.saveTokens(
        access:  tokens['access_token'] as String,
        refresh: tokens['refresh_token'] as String,
      );

      state = AsyncValue.data(AuthState(user: user, isLoggedIn: true));
      return null; // no error
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String? ?? 'Login failed';
      state = AsyncValue.data(const AuthState());
      return msg;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await ApiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final tokens = response.data['tokens'] as Map<String, dynamic>;
      final user   = AppUser.fromJson(response.data['user'] as Map<String, dynamic>);

      await TokenStorage.saveTokens(
        access:  tokens['access_token'] as String,
        refresh: tokens['refresh_token'] as String,
      );

      state = AsyncValue.data(AuthState(user: user, isLoggedIn: true));
      return null;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] as String? ?? 'Registration failed';
      state = AsyncValue.data(const AuthState());
      return msg;
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await TokenStorage.getRefreshToken();
      if (refresh != null) {
        await ApiClient.dio.post('/auth/logout', data: {'refresh_token': refresh});
      }
    } catch (_) {}

    await TokenStorage.clear();
    state = const AsyncValue.data(AuthState());
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await ApiClient.dio.post('/auth/forgot-password', data: {'email': email});
      return null;
    } on DioException catch (e) {
      return (e.response?.data as Map?)?['error'] as String? ?? 'Request failed';
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience alias — most screens just watch this.
final authStateProvider = authNotifierProvider;

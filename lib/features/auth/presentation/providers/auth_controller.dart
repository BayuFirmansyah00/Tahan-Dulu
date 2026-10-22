import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/datasources/remote/api_config.dart';
import '../../../../data/datasources/remote/remote_auth_repository.dart';
import '../../../../data/datasources/remote/token_storage.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Provider repository auth.
///
/// Default (termasuk seluruh test): mock lokal yang offline.
/// Aktifkan backend via `--dart-define=USE_REMOTE_AUTH=true`
/// (opsional `API_BASE_URL`, default emulator 10.0.2.2:8000/api).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ApiConfig.useRemoteAuth) return MockAuthRepository();
  final tokens = TokenStorage();
  return RemoteAuthRepository(
    client: ApiClient(baseUrl: ApiConfig.baseUrl),
    tokens: tokens,
  );
});

enum AuthStatus { initial, loading, authenticated, error }

/// State autentikasi: idle / loading / sukses / gagal + pesan error.
class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.errorMessage,
    this.loginMethod,
  });

  const AuthState.initial() : this._(status: AuthStatus.initial);

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  /// Metode login sesi: 'email' atau 'google'. Null bila belum masuk.
  final String? loginMethod;

  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => [status, user, errorMessage, loginMethod];
}

/// Controller auth: dipanggil UI, meneruskan ke [AuthRepository].
/// Berhasil -> status authenticated (UI bernavigasi ke /onboarding).
class AuthController extends Notifier<AuthState> {
  bool _saving = false;

  @override
  AuthState build() => const AuthState.initial();

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState._(status: AuthStatus.loading);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithEmail(email: email, password: password);
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'email',
      );
      return true;
    } catch (e) {
      state = AuthState._(
        status: AuthStatus.error,
        errorMessage: e is ApiException
            ? e.message
            : AppStrings.authLoginFailed,
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState._(status: AuthStatus.loading);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'email',
      );
      return true;
    } catch (e) {
      state = AuthState._(
        status: AuthStatus.error,
        errorMessage: _registerMessage(e),
      );
      return false;
    }
  }

  /// Pesan gagal register yang spesifik bila server memberi rincian.
  static String _registerMessage(Object e) {
    if (e is ApiException) {
      if (e.hasFieldError('email')) return AppStrings.authEmailTaken;
      if (e.hasFieldError('password')) {
        return AppStrings.authPasswordShort;
      }
      return e.message;
    }
    return AppStrings.authRegisterFailed;
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthState._(status: AuthStatus.loading);
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'google',
      );
      return true;
    } catch (e) {
      state = const AuthState._(
        status: AuthStatus.error,
        errorMessage: AppStrings.authGoogleFailed,
      );
      return false;
    }
  }

  /// Perbarui nama + bio sesi. Email tidak diubah. Guard ganda bawaan.
  Future<bool> updateProfile({required String name, String? bio}) async {
    if (_saving || name.trim().isEmpty) return false;
    _saving = true;
    try {
      final updated = await ref
          .read(authRepositoryProvider)
          .updateProfile(name: name, bio: bio);
      state = AuthState._(
        status: state.status,
        user: updated,
        loginMethod: state.loginMethod,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Keluar sesi. Data keuangan tidak dihapus (milik repository lain).
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Logout lokal tetap dilanjutkan walau repo gagal.
    }
    state = const AuthState.initial();
  }

  /// Pulihkan sesi dari token tersimpan (mode remote saja).
  /// Mengembalikan true bila sesi valid (GET /me berhasil).
  /// Mode mock selalu false agar alur dan test tidak berubah.
  Future<bool> restore() async {
    final repo = ref.read(authRepositoryProvider);
    if (repo is! RemoteAuthRepository) return false;
    try {
      final user = await repo.currentUser();
      if (user == null) return false;
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'email',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

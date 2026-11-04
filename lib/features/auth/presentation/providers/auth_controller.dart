import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/datasources/remote/api_config.dart';
import '../../../../data/datasources/remote/remote_auth_repository.dart';
import '../../../../data/datasources/remote/token_storage.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../onboarding/presentation/providers/expenses_controller.dart';
import '../../../onboarding/presentation/providers/goal_controller.dart';
import '../../../onboarding/presentation/providers/instruments_controller.dart';
import '../../../onboarding/presentation/providers/onboarding_status_provider.dart';
import '../../../onboarding/presentation/providers/salary_controller.dart';
import '../../../goals/presentation/providers/goals_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Provider repository auth.
///
/// Default sekarang REMOTE (Laravel Sanctum). Aktifkan mock lokal via
/// `--dart-define=USE_REMOTE_AUTH=false`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ApiConfig.useRemoteAuth) return MockAuthRepository();
  final tokens = TokenStorage();
  return RemoteAuthRepository(
    client: ApiClient(
      baseUrl: ApiConfig.baseUrl,
    ),
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
    this.fieldErrors,
  });

  const AuthState.initial() : this._(status: AuthStatus.initial);

  const AuthState.authenticated(UserModel user, {String? loginMethod})
      : this._(
          status: AuthStatus.authenticated,
          user: user,
          loginMethod: loginMethod ?? 'email',
        );

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  /// Metode login sesi: 'email' atau 'google'. Null bila belum masuk.
  final String? loginMethod;

  /// Rincian error validasi per field dari backend (status 422).
  /// Kunci: nama field (mis. 'email', 'password'), nilai: daftar pesan.
  final Map<String, List<String>>? fieldErrors;

  bool get isLoading => status == AuthStatus.loading;

  /// true bila ada error validasi pada field tertentu.
  bool hasFieldError(String field) =>
      fieldErrors?[field]?.isNotEmpty ?? false;

  @override
  List<Object?> get props =>
      [status, user, errorMessage, loginMethod, fieldErrors];
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
      _resetUserData();
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'email',
      );
      return true;
    } catch (e) {
      final fieldErrors = e is ApiException ? e.fieldErrors : null;
      state = AuthState._(
        status: AuthStatus.error,
        errorMessage: e is ApiException
            ? e.message
            : AppStrings.authLoginFailed,
        fieldErrors: fieldErrors,
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
      _resetUserData();
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'email',
      );
      return true;
    } catch (e) {
      final fieldErrors = e is ApiException ? e.fieldErrors : null;
      state = AuthState._(
        status: AuthStatus.error,
        errorMessage: _registerMessage(e),
        fieldErrors: fieldErrors,
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
      _resetUserData();
      state = AuthState._(
        status: AuthStatus.authenticated,
        user: user,
        loginMethod: 'google',
      );
      return true;
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : (e is UnsupportedError
              ? (e.message ?? AppStrings.authGoogleFailed)
              : AppStrings.authGoogleFailed);
      state = AuthState._(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Perbarui nama + bio sesi. Email tidak diubah.
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

  /// Perbarui monthly_income + salary_day + is_onboarded secara permanen di backend.
  Future<bool> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  }) async {
    if (_saving) return false;
    _saving = true;
    try {
      final updated = await ref
          .read(authRepositoryProvider)
          .updateFinancialInfo(
            monthlyIncome: monthlyIncome,
            salaryDay: salaryDay,
            isOnboarded: isOnboarded,
          );
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

  /// Membersihkan seluruh data sesi pengguna sebelumnya dari memory, cache repository,
  /// dan provider Riverpod agar tidak terjadi kebocoran data antar-akun.
  void _resetUserData() {
    // 1. Reset state input onboarding
    ref.read(salaryControllerProvider.notifier).reset();
    ref.read(instrumentsControllerProvider.notifier).reset();
    ref.read(expensesControllerProvider.notifier).reset();
    ref.read(goalControllerProvider.notifier).reset();
    ref.read(goalsControllerProvider.notifier).reset();

    // 2. Clear cache onboarding repository
    try {
      ref.read(onboardingRepositoryProvider).clear();
    } catch (_) {}

    // 3. Clear cache purchase decision / Tahan Dulu
    try {
      ref.read(purchaseDecisionRepositoryProvider).clear();
    } catch (_) {}

    // 4. Invalidate semua data providers yang mengikat data user
    ref.invalidate(onboardingRepositoryProvider);
    ref.invalidate(userProvider);
    ref.invalidate(summaryProvider);
    ref.invalidate(profileUserProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(goalsListProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetRepositoryProvider);
    ref.invalidate(dashboardRepositoryProvider);
    ref.invalidate(accountRepositoryProvider);
    ref.invalidate(transactionRepositoryProvider);
    ref.invalidate(goalRepositoryProvider);
    ref.invalidate(purchaseDecisionRepositoryProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(considerationsProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(onboardingStatusProvider);
    ref.invalidate(monthlyReportProvider);
    ref.invalidate(financialPlanProvider);
    ref.invalidate(onboardingPopupShownNotifierProvider);
  }

  /// Keluar sesi dan bersihkan seluruh data pengguna agar akun baru tidak mewarisi data lama.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Logout lokal tetap dilanjutkan walau repo gagal.
    }

    _resetUserData();

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
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await repo.logout();
      }
      return false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

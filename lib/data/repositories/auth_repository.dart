import '../datasources/mock/mock_data.dart';
import '../models/user_model.dart';

// ---------------------------------------------------------------------------
// Auth repository. UI hanya bergantung pada interface ini.
// Mock di bawah nanti diganti Laravel API tanpa mengubah UI.
// ---------------------------------------------------------------------------

abstract class AuthRepository {
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  /// Perbarui profil sesi (nama + bio). Email tidak dapat diubah.
  /// Mock: tersimpan in-memory selama sesi, hilang saat aplikasi dimulai
  /// ulang. Tidak menyentuh data keuangan.
  Future<UserModel> updateProfile({
    required String name,
    String? bio,
  });

  /// Perbarui informasi keuangan pengguna (monthly_income + salary_day + is_onboarded)
  /// secara permanen di backend.
  Future<UserModel> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  });

  /// Keluar sesi. Mock: hanya mereset status sesi, data keuangan tetap ada.
  Future<void> logout();
}

/// Mock authentication — simulasi login/register tanpa backend.
class MockAuthRepository implements AuthRepository {
  UserModel _current = MockData.user;

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) {
    _current = MockData.user;
    return mockDelay(_current, 600);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) {
    _current = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      isOnboarded: false,
    );
    return mockDelay(_current, 600);
  }

  @override
  Future<UserModel> signInWithGoogle() {
    _current = MockData.user;
    return mockDelay(_current, 600);
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    String? bio,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Nama wajib diisi.');
    _current = _current.copyWith(
      name: trimmed,
      bio: () => bio?.trim().isEmpty ?? true ? null : bio!.trim(),
    );
    return mockDelay(_current);
  }

  @override
  Future<UserModel> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  }) {
    _current = _current.copyWith(
      monthlyIncome: () => monthlyIncome ?? _current.monthlyIncome,
      salaryDay: () => salaryDay ?? _current.salaryDay,
      isOnboarded: isOnboarded ?? _current.isOnboarded,
    );
    return mockDelay(_current);
  }

  @override
  Future<void> logout() {
    _current = MockData.user;
    return mockDelay(null);
  }
}

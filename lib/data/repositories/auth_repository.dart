import '../datasources/mock/mock_data.dart';
import '../models/user_model.dart';

class PasswordResetRequestInfo {
  const PasswordResetRequestInfo({
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  final int expiresInSeconds;
  final int resendAfterSeconds;
}

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

  Future<PasswordResetRequestInfo> requestPasswordReset({
    required String email,
  });

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<void> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });

  /// Perbarui profil sesi (nama + bio). Email tidak dapat diubah.
  /// Mock: tersimpan in-memory selama sesi, hilang saat aplikasi dimulai
  /// ulang. Tidak menyentuh data keuangan.
  Future<UserModel> updateProfile({required String name, String? bio});

  /// Unggah file gambar avatar pengguna ke backend.
  Future<UserModel> uploadAvatar(String filePath);

  /// Hapus foto profil pengguna di backend (menjadi null).
  Future<UserModel> deleteAvatar();

  /// Perbarui informasi keuangan pengguna (monthly_income + salary_day + is_onboarded)
  /// secara permanen di backend.
  Future<UserModel> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  });

  /// Keluar sesi. Mock: hanya mereset status sesi, data keuangan tetap ada.
  Future<void> logout();

  /// Hapus akun secara permanen.
  /// Akun email/password: verifikasi kata sandi.
  /// Akun Google-only: verifikasi autentikasi ulang via Google ID Token.
  Future<void> deleteAccount({String? password, String? googleIdToken});

  /// Ubah kata sandi pengguna terautentikasi (khusus akun email/password).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });

  /// Ambil Google ID Token segar untuk verifikasi tindakan sensitif (mis. hapus akun).
  Future<String?> getGoogleReauthIdToken();
}

/// Mock authentication — simulasi login/register tanpa backend.
class MockAuthRepository implements AuthRepository {
  UserModel _current = MockData.user;

  @override
  Future<void> deleteAccount({String? password, String? googleIdToken}) async {
    _current = MockData.user;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (newPassword.length < 8) {
      throw ArgumentError('Kata sandi baru minimal 8 karakter.');
    }
    if (newPassword != newPasswordConfirmation) {
      throw ArgumentError('Konfirmasi kata sandi tidak cocok.');
    }
  }

  @override
  Future<String?> getGoogleReauthIdToken() async => 'mock-google-id-token';

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
  Future<PasswordResetRequestInfo> requestPasswordReset({
    required String email,
  }) {
    throw UnsupportedError('Reset password membutuhkan backend Laravel.');
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) {
    throw UnsupportedError('Verifikasi OTP membutuhkan backend Laravel.');
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) {
    throw UnsupportedError('Reset password membutuhkan backend Laravel.');
  }

  @override
  Future<UserModel> updateProfile({required String name, String? bio}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Nama wajib diisi.');
    _current = _current.copyWith(
      name: trimmed,
      bio: () => bio?.trim().isEmpty ?? true ? null : bio!.trim(),
    );
    return mockDelay(_current);
  }

  @override
  Future<UserModel> uploadAvatar(String filePath) {
    _current = _current.copyWith(
      avatarUrl: () => filePath,
    );
    return mockDelay(_current);
  }

  @override
  Future<UserModel> deleteAvatar() {
    _current = _current.copyWith(
      avatarUrl: () => null,
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

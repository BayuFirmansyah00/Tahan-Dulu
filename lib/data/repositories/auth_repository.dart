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
    _current = UserModel(id: 'user-1', name: name, email: email);
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
  Future<void> logout() {
    _current = MockData.user;
    return mockDelay(null);
  }
}

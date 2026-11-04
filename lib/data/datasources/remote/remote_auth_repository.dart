import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Implementasi [AuthRepository] memakai API Laravel (Sanctum).
///
/// Dipakai saat [ApiConfig.useRemoteAuth] bernilai true.
/// Mendukung Login/Register Email & Password serta Google Sign-In.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required ApiClient client,
    required TokenStore tokens,
    GoogleSignIn? googleSignIn,
  }) {
    _client = client;
    _tokens = tokens;
    _googleSignIn = googleSignIn ??
        GoogleSignIn(
          serverClientId: googleServerClientId,
          scopes: const ['email', 'profile', 'openid'],
        );
  }

  static const String googleServerClientId =
      '83228556023-0usoeq5cnbrt569krubclavfcn0r3qfd.apps.googleusercontent.com';

  late final ApiClient _client;
  late final TokenStore _tokens;
  late final GoogleSignIn _googleSignIn;

  static UserModel _toUser(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: json['email'] as String?,
      monthlyIncome: json['monthly_income'] != null
          ? (json['monthly_income'] is int
              ? json['monthly_income'] as int
              : int.tryParse('${json['monthly_income']}'))
          : null,
      salaryDay: json['salary_day'] != null
          ? (json['salary_day'] is int
              ? json['salary_day'] as int
              : int.tryParse('${json['salary_day']}'))
          : null,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _data(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons login tidak lengkap.');
    }
    return data;
  }

  Future<UserModel> _finish(Map<String, dynamic> body) async {
    final data = _data(body);
    final token = data['access_token'];
    if (token is! String || token.isEmpty) {
      throw ApiException('Token tidak diterima dari server.');
    }
    await _tokens.saveToken(token);
    return _toUser(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final body = await _client.post('/login', {
      'email': email.trim(),
      'password': password,
    });
    return _finish(body);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await _client.post('/register', {
      'name': name.trim(),
      'email': email.trim(),
      // Backend mewajibkan konfirmasi password (aturan confirmed).
      'password': password,
      'password_confirmation': password,
    });
    return _finish(body);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw ApiException('Proses masuk dengan Google dibatalkan.');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Gagal mendapatkan ID Token dari Google.');
    }

    final body = await _client.post('/auth/google', {
      'id_token': idToken,
    });
    return _finish(body);
  }

  @override
  Future<UserModel> updateProfile({required String name, String? bio}) {
    throw UnsupportedError('Ubah nama/bio belum tersedia di backend.');
  }

  @override
  Future<UserModel> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  }) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Token tidak tersedia. Silakan login ulang.',
          statusCode: 401);
    }
    final payload = <String, dynamic>{};
    if (monthlyIncome != null) payload['monthly_income'] = monthlyIncome;
    if (salaryDay != null) payload['salary_day'] = salaryDay;
    if (isOnboarded != null) payload['is_onboarded'] = isOnboarded;
    final body = await _client.put('/user', payload, token: token);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons update tidak lengkap.');
    }
    return _toUser(data);
  }

  /// Ambil profil sesi berjalan. Mengembalikan null bila tanpa token.
  Future<UserModel?> currentUser() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final body = await _client.get('/me', token: token);
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      return _toUser(data);
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _tokens.clearToken();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort sign out akun Google dari perangkat lokal
    }
    final token = await _tokens.readToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _client.post('/logout', {}, token: token);
      } on ApiException {
        // Token server tetap dihapus lokal di bawah (best-effort).
      }
    }
    await _tokens.clearToken();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    _googleSignIn =
        googleSignIn ??
        GoogleSignIn(
          serverClientId: googleServerClientId,
          scopes: const ['email', 'profile', 'openid'],
        );
  }

  static const String googleServerClientId =
      '265153911016-mjbv7q01pino3q27n2t22v3q99vec9df.apps.googleusercontent.com';

  late final ApiClient _client;
  late final TokenStore _tokens;
  late final GoogleSignIn _googleSignIn;

  static UserModel _toUser(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
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

  static String? _googleApiStatusCode(String? message) {
    if (message == null) return null;
    return RegExp(r'ApiException:\s*(-?\d+)').firstMatch(message)?.group(1);
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
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (kDebugMode) {
          debugPrint('[GoogleAuth] exception_code=sign_in_canceled');
        }
        throw ApiException('Proses masuk dengan Google dibatalkan.');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final hasIdToken = idToken != null && idToken.isNotEmpty;
      if (kDebugMode) {
        debugPrint('[GoogleAuth] id_token_present=$hasIdToken');
      }
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Gagal mendapatkan ID Token dari Google.');
      }

      late final Map<String, dynamic> body;
      try {
        body = await _client.post('/auth/google', {'id_token': idToken});
      } on ApiException catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[GoogleAuth] laravel_http_status=${e.statusCode ?? 'unavailable'}',
          );
        }
        rethrow;
      }

      return _finish(body);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        final nativeStatus = _googleApiStatusCode(e.message) ?? 'unavailable';
        debugPrint(
          '[GoogleAuth] exception_code=${e.code} native_status=$nativeStatus',
        );
      }

      if (e.code == GoogleSignIn.kSignInCanceledError) {
        throw ApiException('Proses masuk dengan Google dibatalkan.');
      }
      if (e.code == GoogleSignIn.kNetworkError) {
        throw ApiException('Tidak dapat terhubung ke layanan Google.');
      }

      throw ApiException('Google Sign-In gagal (kode: ${e.code}).');
    }
  }

  @override
  Future<PasswordResetRequestInfo> requestPasswordReset({
    required String email,
  }) async {
    final body = await _client.post('/auth/forgot-password', {
      'email': email.trim(),
    });
    final data = _data(body);
    return PasswordResetRequestInfo(
      expiresInSeconds: data['expires_in'] is int
          ? data['expires_in'] as int
          : int.tryParse('${data['expires_in']}') ?? 300,
      resendAfterSeconds: data['resend_after'] is int
          ? data['resend_after'] as int
          : int.tryParse('${data['resend_after']}') ?? 60,
    );
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final body = await _client.post('/auth/verify-reset-otp', {
      'email': email.trim(),
      'otp': otp,
    });
    final resetToken = _data(body)['reset_token'];
    if (resetToken is! String || resetToken.isEmpty) {
      throw ApiException('Sesi reset tidak diterima dari server.');
    }
    return resetToken;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post('/auth/reset-password', {
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  @override
  Future<UserModel> updateProfile({required String name, String? bio}) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    final payload = <String, dynamic>{
      'name': name.trim(),
      'bio': bio?.trim(),
    };
    final body = await _client.put('/user', payload, token: token);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons update profil tidak lengkap.');
    }
    return _toUser(data);
  }

  @override
  Future<UserModel> uploadAvatar(String filePath) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    final body = await _client.postMultipart(
      '/user/avatar',
      fileField: 'avatar',
      filePath: filePath,
      token: token,
    );
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons unggah foto profil tidak valid.');
    }
    return _toUser(data);
  }

  @override
  Future<UserModel> deleteAvatar() async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    final body = await _client.delete('/user/avatar', token: token);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respons hapus foto profil tidak valid.');
    }
    return _toUser(data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    await _client.put('/user/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    }, token: token);
  }

  @override
  Future<String?> getGoogleReauthIdToken() async {
    try {
      // Pastikan sesi Google SDK di-clear sebelum prompt agar memaksa interaksi autentikasi ulang yang segar
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateFinancialInfo({
    int? monthlyIncome,
    int? salaryDay,
    bool? isOnboarded,
  }) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
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
    try {
      final token = await _tokens.readToken();
      if (token != null && token.isNotEmpty) {
        await _client.post('/logout', {}, token: token);
      }
    } catch (_) {
      // Logout lokal tetap dilanjutkan walau request pencabutan gagal.
    } finally {
      await _tokens.clearToken();
    }
  }

  @override
  Future<void> deleteAccount({String? password, String? googleIdToken}) async {
    final token = await _tokens.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Token tidak tersedia. Silakan login ulang.',
        statusCode: 401,
      );
    }
    final payload = <String, dynamic>{};
    if (password != null && password.isNotEmpty) {
      payload['password'] = password;
    }
    if (googleIdToken != null && googleIdToken.isNotEmpty) {
      payload['google_id_token'] = googleIdToken;
    }
    await _client.post('/delete-account', payload, token: token);
    await _tokens.clearToken();
  }
}

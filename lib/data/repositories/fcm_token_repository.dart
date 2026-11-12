import '../datasources/remote/api_client.dart';
import '../datasources/remote/token_storage.dart';

/// Kontrak registrasi & penghapusan device token FCM ke backend Laravel.
abstract class FcmTokenRepository {
  Future<void> registerToken(
    String token, {
    String platform = 'android',
    String? deviceName,
  });

  Future<void> unregisterToken(String token);
}

class MockFcmTokenRepository implements FcmTokenRepository {
  @override
  Future<void> registerToken(
    String token, {
    String platform = 'android',
    String? deviceName,
  }) async {}

  @override
  Future<void> unregisterToken(String token) async {}
}

class RemoteFcmTokenRepository implements FcmTokenRepository {
  RemoteFcmTokenRepository({
    required this.client,
    required this.tokens,
  });

  final ApiClient client;
  final TokenStore tokens;

  @override
  Future<void> registerToken(
    String token, {
    String platform = 'android',
    String? deviceName,
  }) async {
    if (token.trim().isEmpty) return;
    final authToken = await tokens.readToken();
    if (authToken == null || authToken.isEmpty) return;

    await client.post(
      '/fcm-tokens',
      {
        'token': token,
        'platform': platform,
        if (deviceName != null && deviceName.isNotEmpty)
          'device_name': deviceName,
      },
      token: authToken,
    );
  }

  @override
  Future<void> unregisterToken(String token) async {
    if (token.trim().isEmpty) return;
    final authToken = await tokens.readToken();
    if (authToken == null || authToken.isEmpty) return;

    await client.delete(
      '/fcm-tokens',
      payload: {'token': token},
      token: authToken,
    );
  }
}


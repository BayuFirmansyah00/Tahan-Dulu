import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';

class MockGoogleSignInAccount implements GoogleSignInAccount {
  MockGoogleSignInAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.idToken,
  });

  @override
  final String id;
  @override
  final String email;
  @override
  final String? displayName;
  final String idToken;

  @override
  String? get photoUrl => null;

  @override
  String? get serverAuthCode => null;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      MockGoogleSignInAuthentication(idToken: idToken);

  @override
  Future<Map<String, String>> get authHeaders async => {};

  @override
  Future<void> clearAuthCache() async {}
}

class MockGoogleSignInAuthentication implements GoogleSignInAuthentication {
  MockGoogleSignInAuthentication({required this.idToken});

  @override
  final String? idToken;

  @override
  String? get accessToken => 'mock_access_token';

  @override
  String? get serverAuthCode => null;
}

class FakeGoogleSignIn implements GoogleSignIn {
  FakeGoogleSignIn({this.mockAccount, this.shouldThrow = false});

  final GoogleSignInAccount? mockAccount;
  final bool shouldThrow;
  bool signedOut = false;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (shouldThrow) throw Exception('Google Sign In failed');
    return mockAccount;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signedOut = true;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RemoteAuthRepository - Google Sign In', () {
    test('berhasil masuk Google, simpan Sanctum token, dan kembalikan UserModel', () async {
      final tokenStore = MemoryTokenStore();

      final mockAccount = MockGoogleSignInAccount(
        id: 'google-sub-777',
        email: 'budi.google@gmail.com',
        displayName: 'Budi Google',
        idToken: 'mock_jwt_id_token_123',
      );
      final fakeGoogle = FakeGoogleSignIn(mockAccount: mockAccount);

      final client = ApiClient(
        baseUrl: 'http://localhost/api',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/auth/google');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['id_token'], 'mock_jwt_id_token_123');

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Login Google berhasil',
              'data': {
                'user': {
                  'id': 101,
                  'name': 'Budi Google',
                  'email': 'budi.google@gmail.com',
                  'is_onboarded': true,
                },
                'access_token': '10|sanctum_token_abc',
                'token_type': 'Bearer',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final repo = RemoteAuthRepository(
        client: client,
        tokens: tokenStore,
        googleSignIn: fakeGoogle,
      );

      final user = await repo.signInWithGoogle();

      expect(user.id, '101');
      expect(user.name, 'Budi Google');
      expect(user.email, 'budi.google@gmail.com');
      expect(user.isOnboarded, isTrue);

      // Verifikasi token Sanctum tersimpan
      final savedToken = await tokenStore.readToken();
      expect(savedToken, '10|sanctum_token_abc');
    });

    test('melempar ApiException bila user membatalkan dialog Google', () async {
      final tokenStore = MemoryTokenStore();
      final fakeGoogle = FakeGoogleSignIn(mockAccount: null); // User cancelled

      final client = ApiClient(
        baseUrl: 'http://localhost/api',
        httpClient: MockClient((request) async => http.Response('{}', 200)),
      );

      final repo = RemoteAuthRepository(
        client: client,
        tokens: tokenStore,
        googleSignIn: fakeGoogle,
      );

      expect(
        () => repo.signInWithGoogle(),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('dibatalkan'),
        )),
      );
    });

    test('melempar ApiException jika backend merespons 409 conflict', () async {
      final tokenStore = MemoryTokenStore();

      final mockAccount = MockGoogleSignInAccount(
        id: 'google-sub-conflict',
        email: 'conflict@example.com',
        displayName: 'Conflict User',
        idToken: 'mock_jwt_token',
      );
      final fakeGoogle = FakeGoogleSignIn(mockAccount: mockAccount);

      final client = ApiClient(
        baseUrl: 'http://localhost/api',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'code': 'ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL',
              'message':
                  'Email ini sudah terdaftar dengan metode email/password. Silakan masuk menggunakan kata sandi Anda terlebih dahulu.',
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final repo = RemoteAuthRepository(
        client: client,
        tokens: tokenStore,
        googleSignIn: fakeGoogle,
      );

      expect(
        () => repo.signInWithGoogle(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having(
              (e) => e.message,
              'message',
              contains('sudah terdaftar dengan metode email/password'),
            )),
      );
    });

    test('logout membersihkan Google Sign In dan token secure storage', () async {
      final tokenStore = MemoryTokenStore();
      await tokenStore.saveToken('existing_token');

      final fakeGoogle = FakeGoogleSignIn();

      final client = ApiClient(
        baseUrl: 'http://localhost/api',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/logout');
          return http.Response(
            jsonEncode({'success': true, 'message': 'Logged out'}),
            200,
          );
        }),
      );

      final repo = RemoteAuthRepository(
        client: client,
        tokens: tokenStore,
        googleSignIn: fakeGoogle,
      );

      await repo.logout();

      expect(fakeGoogle.signedOut, isTrue);
      expect(await tokenStore.readToken(), isNull);
    });
  });
}


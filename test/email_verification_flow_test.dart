import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/email_verification_screen.dart';

class _MemoryTokenStore implements TokenStore {
  String? _token = 'test-token';
  @override
  Future<void> clearToken() async => _token = null;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
}

class _FakeAuthRepository extends MockAuthRepository {
  bool verified = false;
  int resendCount = 0;
  Exception? resendError;

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return UserModel(
      id: '10',
      name: 'Budi Verifikasi',
      email: email,
      isEmailVerified: verified,
      emailVerifiedAt: verified ? DateTime(2026, 11, 25) : null,
      isOnboarded: true,
    );
  }

  @override
  Future<void> resendVerificationEmail() async {
    if (resendError != null) throw resendError!;
    resendCount += 1;
  }

  @override
  Future<UserModel> refreshVerificationStatus() async {
    return UserModel(
      id: '10',
      name: 'Budi Verifikasi',
      email: 'budi@example.com',
      isEmailVerified: verified,
      emailVerifiedAt: verified ? DateTime(2026, 11, 25) : null,
      isOnboarded: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registration Email Verification - Repository', () {
    test('register parses unverified user (email_verified_at null) correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/register');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Registrasi berhasil',
            'data': {
              'user': {
                'id': 42,
                'name': 'User Baru',
                'email': 'baru@example.com',
                'email_verified_at': null,
                'is_onboarded': false,
              },
              'access_token': 'sanctum-token-123',
              'token_type': 'Bearer',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = RemoteAuthRepository(
        client: ApiClient(baseUrl: 'https://api.test/api', httpClient: mockClient),
        tokens: _MemoryTokenStore(),
      );

      final user = await repo.register(
        name: 'User Baru',
        email: 'baru@example.com',
        password: 'Password123!',
      );

      expect(user.id, '42');
      expect(user.isEmailVerified, isFalse);
      expect(user.emailVerifiedAt, isNull);
    });

    test('resendVerificationEmail calls POST /email/verification-notification', () async {
      var called = false;
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/email/verification-notification');
        called = true;
        return http.Response(
          jsonEncode({'success': true, 'message': 'Tautan verifikasi baru telah dikirim.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = RemoteAuthRepository(
        client: ApiClient(baseUrl: 'https://api.test/api', httpClient: mockClient),
        tokens: _MemoryTokenStore(),
      );

      await repo.resendVerificationEmail();
      expect(called, isTrue);
    });

    test('refreshVerificationStatus updates verified state from /email/verification-status and /me', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/email/verification-status') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'email_verified': true,
                'email_verified_at': '2026-11-25T10:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 42,
                'name': 'User Baru',
                'email': 'baru@example.com',
                'email_verified_at': '2026-11-25T10:00:00Z',
                'is_onboarded': false,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final repo = RemoteAuthRepository(
        client: ApiClient(baseUrl: 'https://api.test/api', httpClient: mockClient),
        tokens: _MemoryTokenStore(),
      );

      final user = await repo.refreshVerificationStatus();
      expect(user.isEmailVerified, isTrue);
      expect(user.emailVerifiedAt, isNotNull);
    });
  });

  group('Registration Email Verification - Screen & Controller', () {
    testWidgets('EmailVerificationScreen displays email, resends with cooldown, and shows feedback when unverified', (tester) async {
      final fakeRepo = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).loginWithEmail(
            email: 'budi@example.com',
            password: 'Password123!',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('budi@example.com'), findsOneWidget);
      expect(find.text('Saya Sudah Verifikasi'), findsOneWidget);
      expect(find.text('Kirim Ulang Email Verifikasi'), findsOneWidget);

      // Klik Saya Sudah Verifikasi saat masih unverified
      await tester.tap(find.text('Saya Sudah Verifikasi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email belum terverifikasi'), findsOneWidget);

      // Tunggu snackbar hilang agar tidak menutupi tombol di bawah
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Klik Kirim Ulang Email Verifikasi -> cooldown aktif
      await tester.tap(find.text('Kirim Ulang Email Verifikasi'));
      await tester.pumpAndSettle();
      expect(fakeRepo.resendCount, 1);
      expect(find.textContaining('Kirim Ulang dalam'), findsOneWidget);
    });

    testWidgets('EmailVerificationScreen handles 429 rate-limit error gracefully', (tester) async {
      final fakeRepo = _FakeAuthRepository()
        ..resendError = ApiException('Terlalu banyak permintaan.', statusCode: 429);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).loginWithEmail(
            email: 'budi@example.com',
            password: 'Password123!',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmailVerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Ulang Email Verifikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Terlalu banyak permintaan.'), findsOneWidget);
      expect(find.textContaining('Kirim Ulang dalam'), findsOneWidget);
    });
  });
}

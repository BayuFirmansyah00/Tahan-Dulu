import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/delete_account_otp_screen.dart';

class _MemoryTokenStore implements TokenStore {
  String? _token = 'sanctum-delete-token';
  @override
  Future<void> clearToken() async => _token = null;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
}

class _FakeDeleteOtpAuthRepository extends MockAuthRepository {
  Exception? requestError;
  Exception? verifyError;
  String? lastVerifiedOtp;
  String? lastDeletionToken;
  String? lastPassword;
  bool deleteCalled = false;

  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return UserModel(
      id: 'user-del-1',
      name: 'Budi Hapus',
      email: email,
      isOnboarded: true,
    );
  }

  @override
  Future<PasswordResetRequestInfo> requestDeleteAccountOtp() async {
    if (requestError != null) throw requestError!;
    return const PasswordResetRequestInfo(
      expiresInSeconds: 300,
      resendAfterSeconds: 60,
    );
  }

  @override
  Future<String> verifyDeleteAccountOtp({required String otp}) async {
    lastVerifiedOtp = otp;
    if (verifyError != null) throw verifyError!;
    return 'a' * 64;
  }

  @override
  Future<void> deleteAccount({
    String? password,
    String? googleIdToken,
    String? deletionToken,
    String? otp,
  }) async {
    deleteCalled = true;
    lastPassword = password;
    lastDeletionToken = deletionToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_prefs_theme_user-del-1': 'dark',
      'app_prefs_theme_other-user': 'light',
    });
  });

  group('Account Deletion OTP - RemoteAuthRepository', () {
    test('requestDeleteAccountOtp, verifyDeleteAccountOtp, and deleteAccount follow API contract', () async {
      final calls = <String>[];
      final tokens = _MemoryTokenStore();
      final mockClient = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/delete-account/request-otp') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'expires_in': 300, 'resend_after': 60},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/delete-account/verify-otp') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['otp'], '654321');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'deletion_token': 'b' * 64, 'expires_in': 300},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/delete-account') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['password'], 'Secret123!');
          expect(body['deletion_token'], 'b' * 64);
          return http.Response(
            jsonEncode({'success': true, 'message': 'Akun kamu telah berhasil dihapus.'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final repo = RemoteAuthRepository(
        client: ApiClient(baseUrl: 'https://api.test/api', httpClient: mockClient),
        tokens: tokens,
      );

      final info = await repo.requestDeleteAccountOtp();
      expect(info.expiresInSeconds, 300);
      expect(info.resendAfterSeconds, 60);

      final deletionToken = await repo.verifyDeleteAccountOtp(otp: '654321');
      expect(deletionToken, 'b' * 64);

      await repo.deleteAccount(password: 'Secret123!', deletionToken: deletionToken);
      expect(await tokens.readToken(), isNull);
      expect(calls, [
        'POST /api/delete-account/request-otp',
        'POST /api/delete-account/verify-otp',
        'POST /api/delete-account',
      ]);
    });
  });

  group('Account Deletion OTP - DeleteAccountOtpScreen', () {
    testWidgets('validates 6-digit input, handles invalid OTP, and requires final confirmation before deleting & navigating to login', (tester) async {
      final fakeRepo = _FakeDeleteOtpAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).loginWithEmail(
            email: 'budi.hapus@example.com',
            password: 'Secret123!',
          );

      final router = GoRouter(
        initialLocation: '/otp',
        routes: [
          GoRoute(
            path: '/otp',
            builder: (_, _) => const DeleteAccountOtpScreen(password: 'Secret123!'),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (_, _) => const Scaffold(body: Text('LOGIN_SCREEN_DEST')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('budi.hapus@example.com'), findsOneWidget);
      expect(find.textContaining('Kirim Ulang dalam'), findsOneWidget);

      // 1. Submit tanpa 6 digit -> pesan validasi lokal
      await tester.ensureVisible(find.text('Verifikasi & Lanjutkan'));
      await tester.tap(find.text('Verifikasi & Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Masukkan 6 digit kode OTP'), findsOneWidget);

      // 2. Masukkan 6 digit salah -> error dari backend tampil
      fakeRepo.verifyError = ApiException('Kode OTP yang Anda masukkan salah.', statusCode: 422);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('delete_otp_box_$i')), '$i');
      }
      await tester.ensureVisible(find.text('Verifikasi & Lanjutkan'));
      await tester.tap(find.text('Verifikasi & Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Kode OTP yang Anda masukkan salah.'), findsOneWidget);
      expect(fakeRepo.deleteCalled, isFalse);

      // 3. OTP benar -> muncul konfirmasi akhir eksplisit -> hapus akun & navigasi ke Login
      fakeRepo.verifyError = null;
      await tester.ensureVisible(find.text('Verifikasi & Lanjutkan'));
      await tester.tap(find.text('Verifikasi & Lanjutkan'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Akhir Penghapusan Akun'), findsOneWidget);
      expect(fakeRepo.deleteCalled, isFalse);

      await tester.tap(find.text('Ya, Hapus Akun Permanen'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deleteCalled, isTrue);
      expect(fakeRepo.lastPassword, 'Secret123!');
      expect(fakeRepo.lastDeletionToken, 'a' * 64);
      expect(container.read(authControllerProvider).status, AuthStatus.initial);
      expect(find.text('LOGIN_SCREEN_DEST'), findsOneWidget);

      // Pastikan preferensi user-del-1 terhapus, tetapi other-user tetap utuh
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString('app_prefs_theme_user-del-1'), isNull);
      expect(sp.getString('app_prefs_theme_other-user'), 'light');
    });
  });
}

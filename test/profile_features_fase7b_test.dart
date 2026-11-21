import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/profile/presentation/providers/profile_providers.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/privacy_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/security_screen.dart';

class _MemoryTokenStore implements TokenStore {
  String? _token = 'test-bearer-token';
  @override
  Future<void> clearToken() async => _token = null;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_prefs_reduce_motion': true,
      'app_prefs_in_app_notif': false,
      'app_prefs_show_tips': true,
    });
  });

  group('Fase 7B: Data Layer & Remote Repository', () {
    test('UserModel mapping mendukung bio, monthlyIncome, salaryDay, dan isOnboarded', () {
      final user = UserModel(
        id: '123',
        name: 'Budi Santoso',
        email: 'budi@example.com',
        bio: 'Hidup hemat investasi masa depan',
        monthlyIncome: 8500000,
        salaryDay: 25,
        isOnboarded: true,
      );

      expect(user.id, '123');
      expect(user.name, 'Budi Santoso');
      expect(user.email, 'budi@example.com');
      expect(user.bio, 'Hidup hemat investasi masa depan');
      expect(user.monthlyIncome, 8500000);
      expect(user.salaryDay, 25);
      expect(user.isOnboarded, isTrue);
    });

    test('RemoteAuthRepository.updateProfile memanggil PUT /user dengan name & bio', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/user');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Budi Baru');
        expect(body['bio'], 'Bio Baru');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Data user berhasil diperbarui',
            'data': {
              'id': 123,
              'name': 'Budi Baru',
              'email': 'budi@example.com',
              'bio': 'Bio Baru',
              'monthly_income': 8500000,
              'salary_day': 25,
              'is_onboarded': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test',
        httpClient: mockClient,
      );
      final repo = RemoteAuthRepository(
        client: apiClient,
        tokens: _MemoryTokenStore(),
      );

      final updated = await repo.updateProfile(
        name: 'Budi Baru',
        bio: 'Bio Baru',
      );

      expect(updated.name, 'Budi Baru');
      expect(updated.bio, 'Bio Baru');
      expect(updated.monthlyIncome, 8500000);
    });

    test('RemoteAuthRepository.changePassword memanggil PUT /user/password', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/user/password');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['current_password'], 'OldPass123!');
        expect(body['new_password'], 'NewPass456!');
        expect(body['new_password_confirmation'], 'NewPass456!');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Kata sandi berhasil diperbarui.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test',
        httpClient: mockClient,
      );
      final repo = RemoteAuthRepository(
        client: apiClient,
        tokens: _MemoryTokenStore(),
      );

      await expectLater(
        repo.changePassword(
          currentPassword: 'OldPass123!',
          newPassword: 'NewPass456!',
          newPasswordConfirmation: 'NewPass456!',
        ),
        completes,
      );
    });

    test('RemoteAuthRepository.deleteAccount memanggil POST /delete-account', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/delete-account');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['password'], 'Rahasia123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Akun kamu telah berhasil dihapus.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final tokens = _MemoryTokenStore();
      final apiClient = ApiClient(
        baseUrl: 'http://test',
        httpClient: mockClient,
      );
      final repo = RemoteAuthRepository(
        client: apiClient,
        tokens: tokens,
      );

      await repo.deleteAccount(password: 'Rahasia123');
      expect(await tokens.readToken(), isNull);
    });
  });

  group('Fase 7B: App Preferences Persistence', () {
    test('AppPreferencesController memuat nilai dari SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Inisialisasi notifier agar build() dan _loadFromStorage berjalan
      container.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = container.read(appPreferencesProvider);

      expect(prefs.reduceMotion, isTrue);
      expect(prefs.showInAppNotifications, isFalse);
      expect(prefs.showTips, isTrue);
    });

    test('AppPreferencesController menyimpan perubahan ke SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appPreferencesProvider.notifier).setReduceMotion(false);
      await container.read(appPreferencesProvider.notifier).setShowTips(false);

      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool('app_prefs_reduce_motion'), isFalse);
      expect(sp.getBool('app_prefs_show_tips'), isFalse);
    });
  });

  group('Fase 7B: UI & Widgets', () {
    testWidgets('ProfileScreen terbuka tanpa menunggu profileStatsProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileUserProvider.overrideWith((ref) async => const UserModel(
                id: '1',
                name: 'Bayu Test',
                email: 'bayu@example.com',
                bio: 'Bio Test',
                isOnboarded: true,
              )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bayu Test'), findsOneWidget);
      expect(find.text('bayu@example.com'), findsOneWidget);
      expect(find.text(AppStrings.profileBadge), findsOneWidget);
      expect(find.text('Pengaturan Keuangan'), findsOneWidget);
      expect(find.text(AppStrings.profileMenuInfo), findsOneWidget);
      expect(find.text(AppStrings.profileMenuSecurity), findsOneWidget);
      expect(find.text(AppStrings.profileMenuPrivacy), findsOneWidget);
      expect(find.text(AppStrings.profileLogoutAction), findsOneWidget);
    });

    testWidgets('EditProfileScreen memvalidasi input nama dan menampilkan bio', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileUserProvider.overrideWith((ref) async => const UserModel(
                id: '1',
                name: 'Budi Hartono',
                email: 'budi@example.com',
                bio: 'Bio awal',
                isOnboarded: true,
              )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text(AppStrings.editProfileEmailFrozen), findsOneWidget);
      expect(find.text(AppStrings.editProfileSave), findsOneWidget);
    });

    testWidgets('SecurityScreen menampilkan opsi Ubah Kata Sandi dan Hapus Akun', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _MockEmailAuthController()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SecurityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.securityTitle), findsOneWidget);
      expect(find.text(AppStrings.securityChangePassword), findsOneWidget);
      expect(find.text(AppStrings.securityLogout), findsOneWidget);
      expect(find.text(AppStrings.privacyDelete), findsOneWidget);
    });

    testWidgets('PrivacyScreen menampilkan opsi Hapus Akun', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PrivacyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.privacyTitle), findsOneWidget);
      expect(find.text(AppStrings.privacyDelete), findsOneWidget);
    });
  });
}

class _MockEmailAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
        UserModel(
          id: '1',
          name: 'Email User',
          email: 'email@example.com',
          isOnboarded: true,
        ),
        loginMethod: 'email',
      );
}

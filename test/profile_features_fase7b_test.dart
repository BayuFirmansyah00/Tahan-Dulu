import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/utils/date_formatter.dart';
import 'package:tahan_dulu/core/widgets/app_avatar.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/api_recurring_transaction.dart';
import 'package:tahan_dulu/data/models/financial_settings.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/profile/presentation/providers/financial_settings_controller.dart';
import 'package:tahan_dulu/features/profile/presentation/providers/profile_providers.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/financial_settings_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/privacy_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/security_screen.dart';
import 'package:tahan_dulu/features/recurring/presentation/providers/recurring_controller.dart';

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

    test('ApiClient normalizes baseUrl with trailing slash and path without double slashes', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({'success': true, 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // baseUrl memiliki trailing slash, path memiliki leading slash
      final clientWithSlash = ApiClient(
        baseUrl: 'https://tahandulu.kreasikan.site/api/',
        httpClient: mockClient,
      );
      await clientWithSlash.get('/user/avatar');
      expect(requestedUrl, 'https://tahandulu.kreasikan.site/api/user/avatar');

      // baseUrl tanpa trailing slash, path tanpa leading slash
      final clientNoSlash = ApiClient(
        baseUrl: 'https://tahandulu.kreasikan.site/api',
        httpClient: mockClient,
      );
      await clientNoSlash.get('user/avatar');
      expect(requestedUrl, 'https://tahandulu.kreasikan.site/api/user/avatar');
    });

    test('resolveAvatarUrl correctly normalizes relative paths and external URLs', () {
      // 1. Path tanpa /storage/ (format raw Filament FileUpload)
      final urlFromFilament = resolveAvatarUrl('avatars/avatar_123_abc.jpg');
      expect(urlFromFilament, contains('/storage/avatars/avatar_123_abc.jpg'));
      expect(urlFromFilament.contains('//storage'), isFalse);
      expect(urlFromFilament.contains('/api/storage'), isFalse);

      // 2. Path yang sudah diawali /storage/
      final urlWithStorage = resolveAvatarUrl('/storage/avatars/avatar_123_abc.jpg');
      expect(urlWithStorage, contains('/storage/avatars/avatar_123_abc.jpg'));
      expect(urlWithStorage.contains('//storage'), isFalse);

      // 3. URL absolut Google OAuth eksternal tidak diubah
      final googleUrl = 'https://lh3.googleusercontent.com/a/ACg8ocISomeAvatarUrl=s96-c';
      expect(resolveAvatarUrl(googleUrl), googleUrl);

      // 4. String kosong
      expect(resolveAvatarUrl(''), '');
    });

    test('RemoteAuthRepository.deleteAvatar calls DELETE /user/avatar', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/user/avatar');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Foto profil berhasil dihapus',
            'data': {
              'id': 123,
              'name': 'Budi User',
              'email': 'budi@example.com',
              'avatar_url': null,
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

      final result = await repo.deleteAvatar();
      expect(result.avatarUrl, isNull);
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
      expect(find.text('Rencana Keuangan'), findsOneWidget);
      expect(find.text(AppStrings.recurringIncomesTitle), findsOneWidget);
      expect(find.text(AppStrings.recurringExpensesTitle), findsOneWidget);
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
      expect(find.text(AppStrings.editProfilePhoto), findsOneWidget);
      // Gaji & Siklus Anggaran telah dihapus dari EditProfileScreen demi simplifikasi personal info
      expect(find.text('Gaji & Siklus Anggaran'), findsNothing);
      expect(find.text('Buka Pengaturan Keuangan'), findsNothing);
    });

    testWidgets('EditProfileScreen membuka bottom sheet foto profil saat tombol Ubah Foto ditekan', (tester) async {
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

      await tester.tap(find.text(AppStrings.editProfilePhoto));
      await tester.pumpAndSettle();

      expect(find.text('Foto Profil'), findsOneWidget);
      expect(find.text('Ambil Foto (Kamera)'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
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

  group('Fase 7C: Multi-User Isolation & Preferences Hardening', () {
    test('AppPreferences mengisolasi preferensi per pengguna (User A vs User B)', () async {
      final sp = await SharedPreferences.getInstance();

      // Simulasikan User A (id: 'user_a')
      final containerA = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _MockScopedAuthController('user_a')),
        ],
      );
      addTearDown(containerA.dispose);

      containerA.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // User A mengubah reduceMotion menjadi true dan showTips menjadi false
      await containerA.read(appPreferencesProvider.notifier).setReduceMotion(true);
      await containerA.read(appPreferencesProvider.notifier).setShowTips(false);

      expect(sp.getBool('app_prefs_reduce_motion_user_a'), isTrue);
      expect(sp.getBool('app_prefs_show_tips_user_a'), isFalse);

      // Simulasikan User B (id: 'user_b') login di perangkat yang sama
      final containerB = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _MockScopedAuthController('user_b')),
        ],
      );
      addTearDown(containerB.dispose);

      containerB.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // User B mengubah preferensinya sendiri ke nilai berlawanan
      await containerB.read(appPreferencesProvider.notifier).setReduceMotion(false);
      await containerB.read(appPreferencesProvider.notifier).setShowTips(true);
      await containerB.read(appPreferencesProvider.notifier).setShowInAppNotifications(false);

      expect(sp.getBool('app_prefs_reduce_motion_user_b'), isFalse);
      expect(sp.getBool('app_prefs_show_tips_user_b'), isTrue);
      expect(sp.getBool('app_prefs_in_app_notif_user_b'), isFalse);

      // Pastikan preferensi User A di SharedPreferences tetap tidak berubah/bocor
      expect(sp.getBool('app_prefs_reduce_motion_user_a'), isTrue);
      expect(sp.getBool('app_prefs_show_tips_user_a'), isFalse);
      expect(sp.getBool('app_prefs_reduce_motion_user_b'), isFalse);
      expect(sp.getBool('app_prefs_show_tips_user_b'), isTrue);
    });

    test('One-time migration mentransfer kunci legacy global ke user dan menghapus kunci legacy', () async {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('app_prefs_reduce_motion', true);
      await sp.setBool('app_prefs_show_tips', false);

      final containerMigrate = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _MockScopedAuthController('user_legacy')),
        ],
      );
      addTearDown(containerMigrate.dispose);

      containerMigrate.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = containerMigrate.read(appPreferencesProvider);

      expect(prefs.reduceMotion, isTrue);
      expect(prefs.showTips, isFalse);

      // Kunci scoped terbentuk dan kunci global dihapus
      expect(sp.getBool('app_prefs_reduce_motion_user_legacy'), isTrue);
      expect(sp.getBool('app_prefs_show_tips_user_legacy'), isFalse);
      expect(sp.containsKey('app_prefs_reduce_motion'), isFalse);
      expect(sp.containsKey('app_prefs_show_tips'), isFalse);

      // Akun baru (user_fresh) login setelahnya tidak mewarisi preferensi legacy
      final containerFresh = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _MockScopedAuthController('user_fresh')),
        ],
      );
      addTearDown(containerFresh.dispose);

      containerFresh.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefsFresh = containerFresh.read(appPreferencesProvider);

      expect(prefsFresh.reduceMotion, isFalse); // default bersih
      expect(prefsFresh.showTips, isTrue); // default bersih
    });
  });

  group('Fase 7C: Responsive Layout Validation (360dp, 393dp, 412dp)', () {
    final screenSizes = [
      const Size(360, 800), // Standar layar kecil (misal: Galaxy A series)
      const Size(393, 852), // Standar modern (misal: Pixel 7 / iPhone 14)
      const Size(412, 915), // Layar lebar (misal: Pixel 7 Pro)
    ];

    for (final size in screenSizes) {
      testWidgets('ProfileScreen responsif pada lebar ${size.width}dp tanpa overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: [
            profileUserProvider.overrideWith((ref) async => const UserModel(
                  id: '10',
                  name: 'Responsive Tester',
                  email: 'responsive@example.com',
                  bio: 'Testing across screen sizes seamlessly',
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

        expect(tester.takeException(), isNull);
        expect(find.text('Responsive Tester'), findsOneWidget);
        expect(find.text('Testing across screen sizes seamlessly'), findsOneWidget);
      });
    }
  });

  group('Fase 6C: Profile Avatar, Financial Settings & Indonesian Dates', () {
    test('DateFormatter memformat rentang tanggal ISO ke format Indonesia yang mudah dibaca', () {
      final formatted = DateFormatter.formatIsoRange('2026-11-23', '2026-12-22');
      expect(formatted, '23 November – 22 Desember 2026');

      final sameMonth = DateFormatter.formatIsoRange('2026-11-01', '2026-11-30');
      expect(sameMonth, '1 – 30 November 2026');

      final singleDate = DateFormatter.formatIsoDate('2026-12-25');
      expect(singleDate, '25 Desember 2026');
    });

    testWidgets('AppAvatar menampilkan inisial teks saat avatarUrl kosong', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(name: 'Andi Pratama', avatarUrl: null, radius: 28),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('FinancialSettingsScreen menampilkan judul Rencana Keuangan dan Ringkasan Arus Kas Terjadwal', (tester) async {
      const sampleSettings = FinancialSettings(
        currentMonthlyIncome: 7500000,
        currentMonthlyIncomeFormatted: 'Rp 7.500.000',
        currentSalaryDay: 25,
        activePeriod: ActivePeriodInfo(
          id: 1,
          periodStart: '2026-11-23',
          periodEnd: '2026-12-22',
          daysRemaining: 27,
          monthlyIncome: 7500000,
          isActive: true,
          spendableAllocation: 3500000,
          safeDailySpending: 120000,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          financialSettingsControllerProvider.overrideWith(
            () => _MockFinancialSettingsController(sampleSettings),
          ),
          recurringIncomesProvider.overrideWith((ref) async => const []),
          recurringExpensesProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FinancialSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rencana Keuangan'), findsOneWidget);
      expect(find.text('Rencana Keuangan Aktif'), findsOneWidget);
      expect(find.text('Ringkasan Arus Kas Terjadwal'), findsOneWidget);
      expect(find.text('Pemasukan Rutin'), findsWidgets);
      expect(find.text('Pengeluaran Rutin'), findsWidgets);
      expect(find.textContaining('23 November – 22 Desember 2026'), findsOneWidget);
    });

    testWidgets('FinancialSettingsScreen menampilkan status loading saat jadwal arus kas sedang dimuat', (tester) async {
      const sampleSettings = FinancialSettings(
        currentMonthlyIncome: 5000000,
        currentSalaryDay: 25,
      );

      final completer = Completer<List<ApiRecurringTransaction>>();

      final container = ProviderContainer(
        overrides: [
          financialSettingsControllerProvider.overrideWith(
            () => _MockFinancialSettingsController(sampleSettings),
          ),
          recurringIncomesProvider.overrideWith((ref) => completer.future),
          recurringExpensesProvider.overrideWith((ref) => completer.future),
        ],
      );
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(const []);
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FinancialSettingsScreen(),
          ),
        ),
      );
      await tester.pump(); // Pump frame without settling so async remains loading

      expect(find.text('Menghitung arus kas terjadwal...'), findsOneWidget);

      // Selesaikan completer agar tidak ada async pending
      completer.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('FinancialSettingsScreen menampilkan pesan error saat pemuatan jadwal gagal', (tester) async {
      const sampleSettings = FinancialSettings(
        currentMonthlyIncome: 5000000,
        currentSalaryDay: 25,
      );

      final container = ProviderContainer(
        overrides: [
          financialSettingsControllerProvider.overrideWith(
            () => _MockFinancialSettingsController(sampleSettings),
          ),
          recurringIncomesProvider.overrideWith((ref) async => throw Exception('Koneksi terputus')),
          recurringExpensesProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FinancialSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat ringkasan transaksi rutin'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('FinancialSettingsScreen mengalkulasi arus kas terjadwal dengan frekuensi di periode aktif', (tester) async {
      const sampleSettings = FinancialSettings(
        currentMonthlyIncome: 5000000,
        currentSalaryDay: 23,
        activePeriod: ActivePeriodInfo(
          id: 1,
          periodStart: '2026-11-23',
          periodEnd: '2026-12-22', // 30 days
          daysRemaining: 28,
          monthlyIncome: 5000000,
          isActive: true,
          spendableAllocation: 2500000,
          safeDailySpending: 89000,
        ),
      );

      const incomes = <ApiRecurringTransaction>[
        ApiRecurringTransaction(
          id: 'inc-1',
          title: 'Gaji Pokok',
          type: 'income',
          category: 'salary',
          amount: 5000000,
          frequency: 'monthly',
          nextDueDate: '2026-11-25',
          isActive: true,
          makeAutomatic: false,
        ),
      ];

      const expenses = <ApiRecurringTransaction>[
        ApiRecurringTransaction(
          id: 'exp-1',
          title: 'Uang Makan Harian',
          type: 'expense',
          category: 'needs',
          amount: 20000,
          frequency: 'daily',
          isActive: true,
          makeAutomatic: false,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          financialSettingsControllerProvider.overrideWith(
            () => _MockFinancialSettingsController(sampleSettings),
          ),
          recurringIncomesProvider.overrideWith((ref) async => incomes),
          recurringExpensesProvider.overrideWith((ref) async => expenses),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FinancialSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pemasukan rutin 5.000.000 (1 jadwal, 1x periode ini)
      expect(find.text('Rp 5.000.000'), findsWidgets);
      expect(find.textContaining('1 jadwal (1x periode ini)'), findsOneWidget);

      // Pengeluaran harian 20.000 x 30 hari = 600.000 (1 jadwal, 30x periode ini)
      expect(find.text('Rp 600.000'), findsOneWidget);
      expect(find.textContaining('1 jadwal (30x periode ini)'), findsOneWidget);

      // Arus kas bersih: 5.000.000 - 600.000 = + Rp 4.400.000
      expect(find.text('+ Rp 4.400.000'), findsOneWidget);
    });
  });
}

class _MockFinancialSettingsController extends FinancialSettingsController {
  _MockFinancialSettingsController(this._initial);
  final FinancialSettings _initial;

  @override
  Future<FinancialSettings> build() async => _initial;
}

class _MockScopedAuthController extends AuthController {
  _MockScopedAuthController(this.userId);
  final String userId;

  @override
  AuthState build() => AuthState.authenticated(
        UserModel(
          id: userId,
          name: 'User $userId',
          email: '$userId@example.com',
          isOnboarded: true,
        ),
        loginMethod: 'email',
      );
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

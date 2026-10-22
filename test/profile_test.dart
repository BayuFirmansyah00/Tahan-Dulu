import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/models/app_preferences.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/saving_reminder_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/providers/profile_providers.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/about_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/help_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/privacy_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/profile_screen.dart';
import 'package:tahan_dulu/features/profile/presentation/screens/security_screen.dart';

Widget _dummy(String label) => Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );

GoRouter _testRouter({String initial = '/settings'}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'app',
            builder: (context, state) => const AppSettingsScreen(),
          ),
          GoRoute(
            path: 'security',
            builder: (context, state) => const SecurityScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) =>
                const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'savings',
            builder: (context, state) => const SavingReminderScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => _dummy('Dummy Dashboard'),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => _dummy('Dummy Transaksi'),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => _dummy('Dummy Goals'),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => _dummy('LoginDummy'),
      ),
    ],
  );
}

Future<ProviderContainer> _pumpProfile(
  WidgetTester tester, {
  String initial = '/settings',
  Future<void> Function(ProviderContainer)? arrange,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (arrange != null) {
    await tester.runAsync(() => arrange(container));
  }
  final router = _testRouter(initial: initial);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  // Flush mockDelay yang tersisa agar tidak menggantung saat dispose.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

/// Scroll daftar hingga target terlihat (drag manual: aman walau ada
/// beberapa Scrollable seperti field pencarian).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
    final scrollables = find.byType(CustomScrollView).evaluate();
    if (scrollables.isEmpty) break;
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Profil: repository & provider', () {
    test('statistik dihitung dari repo nyata (2/3/3)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final stats = await container.read(profileStatsProvider.future);
      expect(stats.activeGoals, 2);
      expect(stats.accounts, 3);
      expect(stats.transactions, 3);
    });

    test('profil memakai user dashboard bila belum login', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final user = await container.read(profileUserProvider.future);
      expect(user.name, 'Bayu Firmansyah');
    });

    test('update profil menyimpan nama dan bio', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(authControllerProvider.notifier)
          .updateProfile(name: 'Bayu Baru', bio: 'Menabung giat');
      expect(ok, isTrue);
      final user = await container.read(profileUserProvider.future);
      expect(user.name, 'Bayu Baru');
      expect(user.bio, 'Menabung giat');
    });

    test('update profil menolak nama kosong', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(authControllerProvider.notifier)
          .updateProfile(name: '   ');
      expect(ok, isFalse);
    });

    test('double submit update profil hanya satu yang lolos', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      final results = await Future.wait([
        notifier.updateProfile(name: 'A'),
        notifier.updateProfile(name: 'B'),
      ]);
      expect(results.where((e) => e).length, 1);
    });

    test('logout mereset sesi tanpa menghapus data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.loginWithEmail(email: 'a@b.com', password: 'x');
      expect(container.read(authControllerProvider).user, isNotNull);
      await notifier.logout();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.initial,
      );
      final stats = await container.read(profileStatsProvider.future);
      expect(stats.transactions, 3);
    });

    test('login mencatat metode email vs google', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.loginWithEmail(email: 'a@b.com', password: 'x');
      expect(
        container.read(authControllerProvider).loginMethod,
        'email',
      );
      await notifier.signInWithGoogle();
      expect(
        container.read(authControllerProvider).loginMethod,
        'google',
      );
    });

    test('preferensi default dan perubahan tema', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(appPreferencesProvider).theme,
        AppThemeChoice.system,
      );
      container
          .read(appPreferencesProvider.notifier)
          .setTheme(AppThemeChoice.light);
      expect(
        container.read(appPreferencesProvider).theme,
        AppThemeChoice.light,
      );
      // Gelap belum tersedia: ditolak.
      container
          .read(appPreferencesProvider.notifier)
          .setTheme(AppThemeChoice.dark);
      expect(
        container.read(appPreferencesProvider).theme,
        AppThemeChoice.light,
      );
    });
  });

  group('Layar Profil Utama', () {
    testWidgets('tampil data, badge, dan menu (tanpa kartu perjalanan)',
        (tester) async {
      await _pumpProfile(tester);

      expect(find.text(AppStrings.profileTitle), findsWidgets);
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      expect(find.text('Bayu Firmansyah'), findsOneWidget);
      expect(find.text(AppStrings.profileEmailUnavailable), findsOneWidget);
      expect(find.text(AppStrings.profileBadge), findsOneWidget);
      expect(find.text(AppStrings.profileEditAction), findsOneWidget);
      // Kartu Perjalanan Keuanganmu dihapus dari profil.
      expect(find.text(AppStrings.profileJourneyTitle), findsNothing);
      expect(find.text(AppStrings.profileMenuInfo), findsOneWidget);
      expect(find.text(AppStrings.profileMenuApp), findsOneWidget);
      expect(find.text(AppStrings.profileMenuNotif), findsOneWidget);
      expect(find.text(AppStrings.profileMenuSecurity), findsOneWidget);
      expect(find.text(AppStrings.profileMenuPrivacy), findsOneWidget);
      expect(find.text(AppStrings.profileMenuHelp), findsOneWidget);
      expect(find.text(AppStrings.profileMenuAbout), findsOneWidget);
      expect(find.text(AppStrings.profileLogoutAction), findsOneWidget);
      expect(find.text(AppStrings.profileTipsBody), findsOneWidget);
    });

    testWidgets('navigasi ke tujuh halaman pengaturan', (tester) async {
      await _pumpProfile(tester);

      final cases = <String, String>{
        AppStrings.profileMenuInfo: AppStrings.editProfileTitle,
        AppStrings.profileMenuApp: AppStrings.appSettingsTitle,
        AppStrings.profileMenuNotif: AppStrings.notifSettingsTitle,
        AppStrings.profileMenuSecurity: AppStrings.securityTitle,
        AppStrings.profileMenuPrivacy: AppStrings.privacyTitle,
        AppStrings.profileMenuHelp: AppStrings.helpTitle,
        AppStrings.profileMenuAbout: AppStrings.aboutTitle,
      };
      for (final entry in cases.entries) {
        await _tapVisible(tester, find.text(entry.key));
        expect(find.text(entry.value), findsWidgets);
        await _goBack(tester);
        expect(
          find.text(AppStrings.profileSubtitle),
          findsOneWidget,
        );
      }
    });

    testWidgets('bottom navigation Profil aktif dan Home berfungsi',
        (tester) async {
      await _pumpProfile(tester);

      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.navProfile), findsWidgets);
      await _tapVisible(tester, find.text(AppStrings.navHome));
      expect(find.text('Dummy Dashboard'), findsWidgets);
    });

    testWidgets('dialog logout: batal menutup, konfirmasi ke login',
        (tester) async {
      await _pumpProfile(tester);

      await _tapVisible(
        tester,
        find.text(AppStrings.profileLogoutAction),
      );
      expect(find.text(AppStrings.logoutDialogTitle), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.logoutCancel));
      expect(
        find.text(AppStrings.profileSubtitle),
        findsOneWidget,
      );

      await _tapVisible(
        tester,
        find.text(AppStrings.profileLogoutAction),
      );
      await _tapVisible(tester, find.text(AppStrings.logoutConfirm));
      expect(find.text('LoginDummy'), findsWidgets);
    });
  });

  group('Layar Edit Profil', () {
    testWidgets('validasi menolak nama kosong', (tester) async {
      await _pumpProfile(tester, initial: '/settings/edit');

      expect(find.text(AppStrings.editProfileTitle), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          ElevatedButton,
          AppStrings.editProfileSave,
        ),
      );
      expect(
        find.text(AppStrings.editProfileNameRequired),
        findsOneWidget,
      );
    });

    testWidgets('email read-only dengan penjelasan', (tester) async {
      await _pumpProfile(tester, initial: '/settings/edit');

      expect(find.text(AppStrings.editProfileEmailFrozen), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('batal kembali tanpa menyimpan', (tester) async {
      final container = await _pumpProfile(
        tester,
        initial: '/settings/edit',
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Nama Batal',
      );
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          OutlinedButton,
          AppStrings.editProfileCancel,
        ),
      );
      expect(
        find.text(AppStrings.profileSubtitle),
        findsOneWidget,
      );
      final user = await tester.runAsync(
        () => container.read(profileUserProvider.future),
      );
      expect(user!.name, 'Bayu Firmansyah');
    });

    testWidgets('simpan memperbarui nama dan kembali', (tester) async {
      await _pumpProfile(tester, initial: '/settings/edit');

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Bayu Baru',
      );
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          ElevatedButton,
          AppStrings.editProfileSave,
        ),
      );
      expect(find.text(AppStrings.editProfileSaved), findsOneWidget);
      expect(find.text('Bayu Baru'), findsWidgets);
    });

    testWidgets('batas bio 120 karakter', (tester) async {
      await _pumpProfile(tester, initial: '/settings/edit');

      await tester.enterText(
        find.byType(TextFormField).at(2),
        'halo dunia',
      );
      await tester.pump();
      expect(find.text('10/120'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'x' * 121,
      );
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          ElevatedButton,
          AppStrings.editProfileSave,
        ),
      );
      expect(
        find.text(AppStrings.editProfileBioTooLong),
        findsOneWidget,
      );
    });

    testWidgets('ubah foto jujur belum tersedia', (tester) async {
      await _pumpProfile(tester, initial: '/settings/edit');

      await _tapVisible(
        tester,
        find.text(AppStrings.editProfilePhoto),
      );
      expect(
        find.text(AppStrings.editProfilePhotoSoon),
        findsOneWidget,
      );
    });
  });

  group('Layar Pengaturan Aplikasi', () {
    testWidgets('toggle preferensi tersimpan', (tester) async {
      final container = await _pumpProfile(
        tester,
        initial: '/settings/app',
      );

      expect(find.byType(Switch), findsNWidgets(3));
      await _tapVisible(tester, find.byType(Switch).at(0));
      expect(
        container.read(appPreferencesProvider).reduceMotion,
        isTrue,
      );
      await _tapVisible(tester, find.byType(Switch).at(2));
      expect(container.read(appPreferencesProvider).showTips, isFalse);
      expect(
        find.text(AppStrings.appSettingsSessionNote),
        findsOneWidget,
      );
    });

    testWidgets('tips profil mengikuti preferensi', (tester) async {
      await _pumpProfile(tester);

      expect(find.text(AppStrings.profileTipsBody), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.profileMenuApp));
      await _tapVisible(tester, find.byType(Switch).at(2));
      await _goBack(tester);
      expect(find.text(AppStrings.profileTipsBody), findsNothing);
    });
  });

  group('Integrasi Notifikasi existing', () {
    testWidgets('menu menuju pengaturan + daftar + menabung', (tester) async {
      await _pumpProfile(tester);

      await _tapVisible(
        tester,
        find.text(AppStrings.profileMenuNotif),
      );
      expect(find.text(AppStrings.notifFinanceSection), findsOneWidget);
      await _tapVisible(
        tester,
        find.byIcon(Icons.notifications_outlined).first,
      );
      expect(find.text(AppStrings.notificationsTitle), findsWidgets);
      await _goBack(tester);
      await tester.scrollUntilVisible(
        find.text(AppStrings.reminderSavingsTitle),
        300,
      );
      await _tapVisible(
        tester,
        find.text(AppStrings.reminderSavingsTitle),
      );
      expect(find.text(AppStrings.savingAmountLabel), findsOneWidget);
    });
  });

  group('Layar Keamanan Akun', () {
    testWidgets('tanpa sesi: ajakan masuk yang jujur', (tester) async {
      await _pumpProfile(tester, initial: '/settings/security');

      // Tahap 27: ringkasan berupa banner ilustrasi header.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  AppAssets.illAccountSecurity,
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.securityNoSessionTitle), findsOneWidget);
      await _tapVisible(
        tester,
        find.text(AppStrings.securityLoginAction),
      );
      expect(find.text('LoginDummy'), findsWidgets);
    });

    testWidgets('sesi email: metode + ubah sandi + sesi + keluar',
        (tester) async {
      await _pumpProfile(
        tester,
        initial: '/settings/security',
        arrange: (container) => container
            .read(authControllerProvider.notifier)
            .loginWithEmail(email: 'a@b.com', password: 'x')
            .then((_) {}),
      );

      expect(find.text(AppStrings.securityLoginEmail), findsOneWidget);
      expect(find.text(AppStrings.securityActiveBadge), findsOneWidget);
      await _tapVisible(
        tester,
        find.text(AppStrings.securityChangePassword),
      );
      expect(
        find.text(AppStrings.securityPasswordUnavailableTitle),
        findsOneWidget,
      );
      await _tapVisible(tester, find.text('Tutup'));
      await _tapVisible(tester, find.text(AppStrings.securitySessions));
      expect(
        find.text(AppStrings.securitySessionsSoon),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(AppStrings.securityLogout),
        300,
      );
      await _tapVisible(tester, find.text(AppStrings.securityLogout));
      expect(find.text(AppStrings.logoutDialogTitle), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.logoutConfirm));
      expect(find.text('LoginDummy'), findsWidgets);
    });

    testWidgets('sesi google: tanpa ubah sandi', (tester) async {
      await _pumpProfile(
        tester,
        initial: '/settings/security',
        arrange: (container) => container
            .read(authControllerProvider.notifier)
            .signInWithGoogle()
            .then((_) {}),
      );

      expect(find.text(AppStrings.securityLoginGoogle), findsOneWidget);
      expect(
        find.text(AppStrings.securityGooglePasswordNote),
        findsOneWidget,
      );
      expect(find.text(AppStrings.securityChangePassword), findsNothing);
    });
  });

  group('Layar Privasi', () {
    testWidgets('dokumen info dan hapus jujur belum tersedia',
        (tester) async {
      await _pumpProfile(tester, initial: '/settings/privacy');

      // Tahap 27: intro berupa banner ilustrasi header.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == AppAssets.illPrivacy,
        ),
        findsOneWidget,
      );
      await _tapVisible(tester, find.text(AppStrings.privacyPolicy));
      expect(find.text(AppStrings.privacyPolicyBody), findsOneWidget);
      await _tapVisible(tester, find.text('Tutup'));
      await _tapVisible(tester, find.text(AppStrings.privacyDataUsage));
      expect(find.text(AppStrings.privacyDataUsageBody), findsOneWidget);
      await _tapVisible(tester, find.text('Tutup'));

      await _tapVisible(tester, find.text(AppStrings.privacyDelete));
      expect(find.text(AppStrings.deleteDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.deleteDialogBody), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.logoutCancel));
      expect(find.text(AppStrings.privacyTitle), findsWidgets);

      await _tapVisible(tester, find.text(AppStrings.privacyDelete));
      await _tapVisible(tester, find.text(AppStrings.deleteConfirm));
      expect(
        find.text(AppStrings.privacyDeleteUnavailable),
        findsOneWidget,
      );
      expect(find.text(AppStrings.privacyTitle), findsWidgets);
    });
  });

  group('Layar Bantuan & Dukungan', () {
    testWidgets('kategori, expand, dan pencarian lokal', (tester) async {
      await _pumpProfile(tester, initial: '/settings/help');

      expect(find.text(AppStrings.helpHeadline), findsOneWidget);
      expect(find.text(AppStrings.helpCategoryTitle), findsOneWidget);
      const question = 'Bagaimana cara mencatat transaksi?';

      // Pencarian dulu selagi field masih terlihat (belum scroll).
      await tester.enterText(
        find.byType(TextField),
        'tahandulu',
      );
      await tester.pumpAndSettle();
      expect(find.text('Apa itu TahanDulu?'), findsOneWidget);
      expect(find.text(question), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz-tidak-ada');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.helpEmptyTitle), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.helpCategoryTitle), findsOneWidget);

      const answer =
          'Ketuk tombol Catat pada navigasi bawah atau buka halaman '
          'Transaksi. Isi jenis, nominal, kategori, akun, dan tanggal, lalu '
          'periksa kembali sebelum disimpan.';
      await _scrollTo(tester, find.text(question));
      await _tapVisible(tester, find.text(question));
      expect(find.text(answer), findsOneWidget);
      await _tapVisible(tester, find.text(question));
      expect(find.text(answer), findsNothing);
    });

    testWidgets('kontak dukungan jujur segera hadir', (tester) async {
      await _pumpProfile(tester, initial: '/settings/help');

      await _scrollTo(tester, find.text(AppStrings.helpContactAction));
      await _tapVisible(tester, find.text(AppStrings.helpContactAction));
      expect(find.text(AppStrings.helpContactSoon), findsOneWidget);
    });
  });

  group('Layar Tentang', () {
    testWidgets('branding, versi, dokumen, lisensi', (tester) async {
      await _pumpProfile(tester, initial: '/settings/about');

      expect(find.text('TahanDulu'), findsWidgets);
      expect(find.text(AppStrings.aboutTagline), findsOneWidget);
      expect(find.text('Versi 1.0.0'), findsOneWidget);
      expect(find.text(AppStrings.aboutDescription), findsOneWidget);
      await _tapVisible(tester, find.text(AppStrings.aboutLicenses));
      expect(find.text(AppStrings.aboutLicensesBody), findsOneWidget);
      await _tapVisible(tester, find.text('Tutup'));
      expect(
        find.textContaining(AppStrings.aboutCopyright),
        findsOneWidget,
      );    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/saving_reminder_screen.dart';
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
            builder: (context, state) => const NotificationSettingsScreen(),
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

Future<void> _pumpSettings(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = _testRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _isSettingsAsset(Widget w) {
  if (w is! Image) return false;
  final p = w.image;
  return p is AssetImage && p.assetName.startsWith('assets/icons/');
}

Finder findAssetImage(String asset) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == asset,
);

const _menus = <String, String>{
  AppStrings.profileMenuInfo: AppStrings.profileMenuInfoDesc,
  AppStrings.profileMenuApp: AppStrings.profileMenuAppDesc,
  AppStrings.profileMenuNotif: AppStrings.profileMenuNotifDesc,
  AppStrings.profileMenuSecurity: AppStrings.profileMenuSecurityDesc,
  AppStrings.profileMenuPrivacy: AppStrings.profileMenuPrivacyDesc,
  AppStrings.profileMenuHelp: AppStrings.profileMenuHelpDesc,
  AppStrings.profileMenuAbout: AppStrings.profileMenuAboutDesc,
};

void main() {
  group('Tahap 26: modernisasi Pengaturan Akun', () {
    testWidgets('tujuh judul dan deskripsi menu tampil', (tester) async {
      await _pumpSettings(tester);

      for (final entry in _menus.entries) {
        await tester.scrollUntilVisible(find.text(entry.key), 300);
        expect(find.text(entry.key), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ikon 3D settings tampil di kartu dan header', (tester) async {
      await _pumpSettings(tester);

      // Tiap menu di-scroll hingga terlihat; setApp kini dipakai sekali
      // (kartu Pengaturan Aplikasi) karena ilustrasi header dihapus.
      final menuAssets = [
        AppAssets.setProfile,
        AppAssets.setApp,
        AppAssets.setNotif,
        AppAssets.setSecurity,
        AppAssets.setPrivacy,
        AppAssets.setHelp,
        AppAssets.setAbout,
      ];
      for (final entry in _menus.entries) {
        await tester.scrollUntilVisible(find.text(entry.key), 300);
      }
      for (final asset in menuAssets) {
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == asset,
          ),
          findsWidgets,
          reason: asset,
        );
      }
      // 7 kartu menu (ilustrasi header kanan atas dihapus).
      expect(find.byWidgetPredicate(_isSettingsAsset), findsNWidgets(7));
      expect(tester.takeException(), isNull);
    });

    // Lebar ponsel minimum realistis (360); font blok pengujian (Ahem,
    // ~2x Roboto) menjadikannya stress test yang ketat.
    testWidgets('tanpa overflow pada layar kecil 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpSettings(tester);

      for (final entry in _menus.entries) {
        await tester.scrollUntilVisible(find.text(entry.key), 300);
      }
      await tester.scrollUntilVisible(
        find.text(AppStrings.profileLogoutAction),
        300,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol kembali berfungsi', (tester) async {
      await _pumpSettings(tester);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.text('Dummy Dashboard'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigasi kartu ke route yang benar', (tester) async {
      await _pumpSettings(tester);

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
        await _tapVisible(tester, find.byIcon(Icons.arrow_back));
        expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 27: desain referensi tiga halaman', () {
    testWidgets('notifikasi: banner + enam ikon 3D + enam toggle', (
      tester,
    ) async {
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuNotif));

      expect(findAssetImage(AppAssets.illNotifActive), findsOneWidget);
      for (final asset in [
        AppAssets.setWallet,
        AppAssets.setSavingsPig,
        AppAssets.setBills,
        AppAssets.setBudget,
        AppAssets.setBag,
        AppAssets.setOverspend,
      ]) {
        await tester.scrollUntilVisible(findAssetImage(asset), 300);
        expect(findAssetImage(asset), findsOneWidget, reason: asset);
      }
      expect(find.byType(Switch), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keamanan: banner + tips + kembali berfungsi', (tester) async {
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuSecurity));

      expect(findAssetImage(AppAssets.illAccountSecurity), findsOneWidget);
      await tester.scrollUntilVisible(
        findAssetImage(AppAssets.illSecurityTips),
        300,
      );
      expect(findAssetImage(AppAssets.illSecurityTips), findsOneWidget);
      expect(find.text(AppStrings.securityLogout), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('privasi: banner + tiga ikon + banner bawah + kembali', (
      tester,
    ) async {
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuPrivacy));

      expect(findAssetImage(AppAssets.illPrivacy), findsOneWidget);
      for (final asset in [
        AppAssets.setPrivacyPolicy,
        AppAssets.setDataUsage,
        AppAssets.setDeleteAccount,
      ]) {
        await tester.scrollUntilVisible(findAssetImage(asset), 300);
      }
      expect(findAssetImage(AppAssets.setDeleteAccount), findsOneWidget);
      await tester.scrollUntilVisible(
        findAssetImage(AppAssets.illPrivacyDataSafe),
        300,
      );
      expect(findAssetImage(AppAssets.illPrivacyDataSafe), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa overflow 360x640 di ketiga halaman', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpSettings(tester);

      for (final menu in [
        AppStrings.profileMenuNotif,
        AppStrings.profileMenuSecurity,
        AppStrings.profileMenuPrivacy,
      ]) {
        await _tapVisible(tester, find.text(menu));
        // Gulir hingga dasar halaman lalu kembali.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 28: modernisasi empat halaman', () {
    testWidgets('profil: kartu perjalanan dihapus dari profil', (tester) async {
      await _pumpSettings(tester);

      expect(findAssetImage(AppAssets.illProfileSummary), findsNothing);
      expect(find.text(AppStrings.profileJourneyTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit profil: latar + badge kamera', (tester) async {
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuInfo));

      expect(findAssetImage(AppAssets.illEditProfileBg), findsOneWidget);
      expect(findAssetImage(AppAssets.setCameraBadge), findsOneWidget);
      expect(find.text(AppStrings.editProfileName), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tentang: ilustrasi + tiga ikon lokal + versi', (tester) async {
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuAbout));

      expect(findAssetImage(AppAssets.illAboutApp), findsOneWidget);
      for (final asset in [
        AppAssets.setPrivacyPolicy,
        AppAssets.setTerms,
        AppAssets.setOpenSource,
      ]) {
        await tester.scrollUntilVisible(findAssetImage(asset), 300);
        expect(findAssetImage(asset), findsOneWidget, reason: asset);
      }
      expect(find.text('Versi 1.0.0'), findsOneWidget);
      await _tapVisible(tester, find.byIcon(Icons.arrow_back));
      expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa overflow 360x640 di edit dan tentang', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpSettings(tester);

      for (final menu in [
        AppStrings.profileMenuInfo,
        AppStrings.profileMenuApp,
        AppStrings.profileMenuAbout,
      ]) {
        await _tapVisible(tester, find.text(menu));
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Kembali via AppBar; edit profil tanpa perubahan langsung pop.
        await _tapVisible(tester, find.byIcon(Icons.arrow_back));
        expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Tahap 29: polish dan responsivitas empat halaman', () {
    const sizes = [Size(360, 640), Size(393, 852), Size(412, 915)];

    testWidgets('empat halaman tanpa overflow di tiga ukuran', (tester) async {
      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await _pumpSettings(tester);

        // Profil root: CTA keluar dapat digulir hingga terlihat.
        await tester.scrollUntilVisible(
          find.text(AppStrings.profileLogoutAction),
          400,
        );
        expect(tester.takeException(), isNull);

        for (final menu in [
          AppStrings.profileMenuInfo,
          AppStrings.profileMenuApp,
          AppStrings.profileMenuAbout,
        ]) {
          await _tapVisible(tester, find.text(menu));
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -2500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _tapVisible(tester, find.byIcon(Icons.arrow_back));
          expect(find.text(AppStrings.profileSubtitle), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('tombol simpan edit profil terjangkau via scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _pumpSettings(tester);
      await _tapVisible(tester, find.text(AppStrings.profileMenuInfo));

      // ensureVisible menelusuri semua Scrollable leluhur (layar form
      // punya Scrollable internal per field teks).
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, AppStrings.editProfileSave),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ElevatedButton, AppStrings.editProfileSave),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, AppStrings.editProfileCancel),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

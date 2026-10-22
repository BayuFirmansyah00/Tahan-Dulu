import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/core/utils/currency_formatter.dart';
import 'package:tahan_dulu/data/models/app_notification.dart';
import 'package:tahan_dulu/data/models/reminder_settings.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/dashboard_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tahan_dulu/features/notifications/presentation/screens/saving_reminder_screen.dart';

/// Fake kosong untuk menguji empty state.
class _EmptyNotifications implements NotificationRepository {
  @override
  Future<List<AppNotification>> getNotifications() async => [];
  @override
  Future<void> markAsRead(String id) async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<List<ReminderPreference>> getPreferences() async => [
        for (final type in ReminderType.values)
          ReminderPreference(type: type),
      ];
  @override
  Future<void> setPreference(ReminderType type, bool enabled) async {}
  @override
  Future<SavingReminderConfig> getSavingReminder() async =>
      const SavingReminderConfig();
  @override
  Future<SavingReminderConfig> saveSavingReminder(
    SavingReminderConfig config,
  ) async =>
      config;
  @override
  Future<SavingReminderConfig> deactivateSavingReminder() async =>
      const SavingReminderConfig(enabled: false);
}

GoRouter _testRouter({String initial = AppRoutes.notifications}) {
  Widget dummy(String label) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(child: Text(label)),
      );
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.notifications,
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
        path: AppRoutes.dashboard,
        builder: (context, state) => dummy('Dummy Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) => dummy('Dummy Transaksi'),
      ),
      GoRoute(
        path: AppRoutes.goals,
        builder: (context, state) => dummy('Dummy Goals'),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => dummy('Dummy Reports'),
      ),
      GoRoute(
        path: AppRoutes.tahanDulu,
        builder: (context, state) => dummy('Dummy TahanDulu'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => dummy('Dummy Settings'),
      ),
    ],
  );
}

Future<ProviderContainer> _pumpNotifications(
  WidgetTester tester, {
  String initial = AppRoutes.notifications,
  NotificationRepository? repoOverride,
}) async {
  final container = ProviderContainer(
    overrides: [
      if (repoOverride != null)
        notificationRepositoryProvider.overrideWithValue(repoOverride),
    ],
  );
  addTearDown(container.dispose);
  final router = _testRouter(initial: initial);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Repository & provider notifikasi', () {
    test('unread count awal 3 dari 5 seed', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final unread = await container.read(unreadCountProvider.future);
      expect(unread, 3);
    });

    test('markAsRead menurunkan unread count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(notificationsControllerProvider.notifier)
          .markAsRead('notif-salary');
      final unread = await container.refresh(unreadCountProvider.future);
      expect(unread, 2);
    });

    test('markAllAsRead menghabiskan unread count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(notificationsControllerProvider.notifier)
          .markAllAsRead();
      expect(ok, isTrue);
      final unread = await container.refresh(unreadCountProvider.future);
      expect(unread, 0);
    });

    test('dashboard hasUnread reaktif terhadap markAllAsRead', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final before = await container.read(dashboardDataProvider.future);
      expect(before.hasUnread, isTrue);
      await container
          .read(notificationsControllerProvider.notifier)
          .markAllAsRead();
      final after =
          await container.refresh(dashboardDataProvider.future);
      expect(after.hasUnread, isFalse);
    });

    test('toggle preferensi tersimpan di repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ok = await container
          .read(reminderPrefsControllerProvider.notifier)
          .setEnabled(ReminderType.salary, false);
      expect(ok, isTrue);
      final prefs =
          await container.refresh(reminderPreferencesProvider.future);
      final salary = prefs.firstWhere((e) => e.type == ReminderType.salary);
      expect(salary.enabled, isFalse);
    });

    test('format Rupiah konsisten', () {
      expect(CurrencyFormatter.format(200000), 'Rp 200.000');
      expect(CurrencyFormatter.formatCompact(200000), 'Rp200.000');
    });

    test('hari efektif menangani bulan pendek', () {
      const config = SavingReminderConfig(dayOfMonth: 31);
      expect(config.effectiveDayFor(2026, 2), 28);
      expect(config.effectiveDayFor(2026, 4), 30);
      expect(config.effectiveDayFor(2026, 1), 31);
      expect(config.timeLabel, '19:00');
    });

    test('validasi nominal menolak nol', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(notificationRepositoryProvider);
      expect(
        () => repo.saveSavingReminder(const SavingReminderConfig(amount: 0)),
        throwsArgumentError,
      );
    });

    test('double submit save hanya satu yang lolos', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(savingReminderControllerProvider.notifier)
          .load();
      final notifier =
          container.read(savingReminderControllerProvider.notifier);
      final results = await Future.wait([notifier.save(), notifier.save()]);
      expect(results.where((e) => e).length, 1);
    });

    test('nonaktifkan tidak menghapus konfigurasi', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(notificationRepositoryProvider);
      await repo.saveSavingReminder(
        const SavingReminderConfig(amount: 200000),
      );
      final off = await repo.deactivateSavingReminder();
      expect(off.enabled, isFalse);
      expect(off.amount, 200000);
    });
  });

  group('Layar Notifikasi', () {
    testWidgets('menampilkan tab, aksi massal, dan grup hari',
        (tester) async {
      await _pumpNotifications(tester);

      expect(find.text(AppStrings.notificationsTitle), findsOneWidget);
      expect(find.text(AppStrings.notifTabAll), findsOneWidget);
      expect(find.text(AppStrings.notifTabUnread), findsOneWidget);
      expect(find.text(AppStrings.notifTabReminder), findsOneWidget);
      expect(find.text(AppStrings.notifMarkAllRead), findsOneWidget);
      expect(find.text(AppStrings.notifToday), findsOneWidget);
      expect(find.text('Gaji masuk hari ini'), findsOneWidget);
      expect(find.text('Target tabungan'), findsOneWidget);
      expect(find.text('TahanDulu selesai'), findsOneWidget);
      // Grup kemarin di luar lipatan: scroll hingga terlihat.
      await tester.scrollUntilVisible(
        find.text('Pengingat menabung'),
        300,
      );
      expect(find.text(AppStrings.notifYesterday), findsOneWidget);
      expect(find.text('Pengingat menabung'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Pengeluaran mendekati batas'),
        300,
      );
      expect(
        find.text('Pengeluaran mendekati batas'),
        findsOneWidget,
      );
    });

    testWidgets('tab Belum Dibaca memfilter item', (tester) async {
      await _pumpNotifications(tester);

      await _tapVisible(tester, find.text(AppStrings.notifTabUnread));
      expect(find.text('Gaji masuk hari ini'), findsOneWidget);
      expect(find.text('Target tabungan'), findsOneWidget);
      // Item yang sudah dibaca hilang dari tab ini.
      expect(find.text('Pengingat menabung'), findsNothing);
      expect(
        find.text('Pengeluaran mendekati batas'),
        findsNothing,
      );

      await _tapVisible(tester, find.text(AppStrings.notifTabAll));
      await tester.scrollUntilVisible(
        find.text('Pengingat menabung'),
        300,
      );
      expect(find.text('Pengingat menabung'), findsOneWidget);
    });

    testWidgets('tab Pengingat hanya menampilkan pengingat',
        (tester) async {
      await _pumpNotifications(tester);

      await _tapVisible(tester, find.text(AppStrings.notifTabReminder));
      expect(find.text('Gaji masuk hari ini'), findsOneWidget);
      expect(find.text('TahanDulu selesai'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Pengingat menabung'),
        300,
      );
      expect(find.text('Pengingat menabung'), findsOneWidget);
      // Bukan pengingat: target & budget hilang.
      expect(find.text('Target tabungan'), findsNothing);
      expect(
        find.text('Pengeluaran mendekati batas'),
        findsNothing,
      );
    });

    testWidgets('tandai semua dibaca mengosongkan tab Belum Dibaca',
        (tester) async {
      final container = await _pumpNotifications(tester);

      await tester.ensureVisible(find.text(AppStrings.notifMarkAllRead));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.notifMarkAllRead));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.notifAllMarkedRead), findsOneWidget);

      final unread = await tester.runAsync(
        () => container.refresh(unreadCountProvider.future),
      );
      expect(unread, 0);

      await _tapVisible(tester, find.text(AppStrings.notifTabUnread));
      expect(find.text(AppStrings.notifEmptyUnread), findsOneWidget);
    });

    testWidgets('ketuk item menandai dibaca dan navigasi', (tester) async {
      final container = await _pumpNotifications(tester);

      await _tapVisible(tester, find.text('Gaji masuk hari ini'));
      // Navigasi ke route tujuan (dummy transaksi: AppBar + body).
      expect(find.text('Dummy Transaksi'), findsWidgets);

      final unread = await tester.runAsync(
        () => container.refresh(unreadCountProvider.future),
      );
      expect(unread, 2);
    });

    testWidgets('menu mengarah ke pengaturan', (tester) async {
      await _pumpNotifications(tester);

      await _tapVisible(tester, find.byIcon(Icons.more_horiz));
      await _tapVisible(tester, find.text(AppStrings.notifMenuSettings));
      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
    });

    testWidgets('empty state saat tidak ada notifikasi', (tester) async {
      await _pumpNotifications(
        tester,
        repoOverride: _EmptyNotifications(),
      );

      expect(find.text(AppStrings.notifEmpty), findsOneWidget);
      expect(find.text(AppStrings.notifEmptyHint), findsOneWidget);
    });

    testWidgets('bottom navigation konsisten', (tester) async {
      await _pumpNotifications(tester);

      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.navRecord), findsOneWidget);
      expect(find.text(AppStrings.navGoals), findsOneWidget);
      expect(find.text(AppStrings.navProfile), findsOneWidget);
    });
  });

  group('Layar Pengaturan Notifikasi', () {
    testWidgets('menampilkan status dan enam toggle', (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/settings',
      );

      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
      // Tahap 27: status berupa banner ilustrasi header (bukan blok teks).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  AppAssets.illNotifActive,
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.notifFinanceSection), findsOneWidget);
      expect(find.text(AppStrings.reminderSalaryTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderSavingsTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderBillsTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderBudgetTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderTahanDuluTitle), findsOneWidget);
      expect(find.text(AppStrings.reminderOverspendTitle), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(6));
      expect(find.text(AppStrings.notifInfo), findsOneWidget);
    });

    testWidgets('toggle tersimpan dan persisten saat navigasi',
        (tester) async {
      final container = await _pumpNotifications(
        tester,
        initial: '/notifications/settings',
      );

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(6));
      await _tapVisible(tester, switches.first);

      final prefs = await tester.runAsync(
        () => container.refresh(reminderPreferencesProvider.future),
      );
      final salary =
          prefs!.firstWhere((e) => e.type == ReminderType.salary);
      expect(salary.enabled, isFalse);

      // Pindah ke detail menabung lalu kembali: toggle tetap mati.
      await _tapVisible(
        tester,
        find.text(AppStrings.reminderSavingsTitle),
      );
      expect(find.text(AppStrings.savingReminderTitle), findsWidgets);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      final after = await tester.runAsync(
        () => container.read(reminderPreferencesProvider.future),
      );
      expect(
        after!.firstWhere((e) => e.type == ReminderType.salary).enabled,
        isFalse,
      );
    });

    testWidgets('baris menabung membuka halaman detail', (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/settings',
      );

      await _tapVisible(
        tester,
        find.text(AppStrings.reminderSavingsTitle),
      );
      expect(find.text(AppStrings.savingAmountLabel), findsOneWidget);
    });

    testWidgets('baris lain jujur belum punya detail', (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/settings',
      );

      await _tapVisible(
        tester,
        find.text(AppStrings.reminderSalaryTitle),
      );
      expect(
        find.text(AppStrings.reminderDetailComingSoon),
        findsOneWidget,
      );
      // Tetap di halaman pengaturan.
      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
    });
  });

  group('Layar Pengingat Menabung', () {
    testWidgets('form menampilkan nilai awal sesuai referensi',
        (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      expect(find.text(AppStrings.savingReminderTitle), findsWidgets);
      expect(find.text(AppStrings.savingReminderIntro), findsOneWidget);
      expect(find.text(AppStrings.savingStatusLabel), findsOneWidget);
      expect(find.text(AppStrings.savingTargetLabel), findsOneWidget);
      expect(find.text(AppStrings.savingAmountLabel), findsOneWidget);
      expect(find.text(AppStrings.savingFrequencyLabel), findsOneWidget);
      expect(find.text(AppStrings.savingTimeLabel), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, AppStrings.savingSaveAction),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.savingDeactivateAction),
        findsOneWidget,
      );
      // Nilai awal visual.
      expect(find.text('200.000'), findsOneWidget);
      expect(find.text(AppStrings.savingFrequencyMonthly), findsWidgets);
      expect(find.text('19:00'), findsOneWidget);
      // Dropdown tertutup menampilkan nilai terpilih.
      expect(
        find.text('10 ${AppStrings.savingEveryMonthSuffix}'),
        findsOneWidget,
      );
    });

    testWidgets('target dropdown menampilkan progres goal',
        (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);
      await _tapVisible(tester, dropdown);
      // Seed goal dari MockGoalRepository.
      expect(find.textContaining('Target Investasi'), findsWidgets);
      await _tapVisible(tester, find.textContaining('Target Investasi').last);
      expect(find.textContaining('Target Investasi'), findsWidgets);
    });

    testWidgets('validasi menolak nominal nol', (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      final field = find.byType(TextFormField);
      await tester.enterText(field, '');
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          ElevatedButton,
          AppStrings.savingSaveAction,
        ),
      );
      expect(find.text(AppStrings.savingAmountRequired), findsOneWidget);
    });

    testWidgets('frekuensi mingguan menampilkan hari', (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      await _tapVisible(
        tester,
        find.byType(DropdownButtonFormField<SavingFrequency>),
      );
      await _tapVisible(
        tester,
        find.text(AppStrings.savingFrequencyWeekly).last,
      );
      expect(find.text(AppStrings.savingWeekdayLabel), findsOneWidget);
      expect(find.text('Senin'), findsWidgets);
    });

    testWidgets('frekuensi bulanan menampilkan tanggal + hint bulan pendek',
        (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      expect(find.text(AppStrings.savingDateLabel), findsOneWidget);
      expect(
        find.text(AppStrings.savingShortMonthHint),
        findsOneWidget,
      );
      await _tapVisible(tester, find.byType(DropdownButtonFormField<int>));
      expect(
        find.text('10 ${AppStrings.savingEveryMonthSuffix}').last,
        findsWidgets,
      );
    });

    testWidgets('time picker terbuka dan dapat dibatalkan',
        (tester) async {
      await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      await _tapVisible(tester, find.text('19:00'));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('19:00'), findsOneWidget);
    });

    testWidgets('simpan pengaturan memberi feedback sukses',
        (tester) async {
      final container = await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      final field = find.byType(TextFormField);
      await tester.enterText(field, '300000');
      await tester.pump();
      await _tapVisible(
        tester,
        find.widgetWithText(
          ElevatedButton,
          AppStrings.savingSaveAction,
        ),
      );
      expect(find.text(AppStrings.savingSaved), findsOneWidget);

      final saved = await tester.runAsync(
        () => container
            .read(notificationRepositoryProvider)
            .getSavingReminder(),
      );
      expect(saved!.amount, 300000);
    });

    testWidgets('nonaktifkan tanpa menghapus nominal', (tester) async {
      final container = await _pumpNotifications(
        tester,
        initial: '/notifications/savings',
      );

      await _tapVisible(
        tester,
        find.text(AppStrings.savingDeactivateAction),
      );
      expect(find.text(AppStrings.savingDeactivated), findsOneWidget);

      final saved = await tester.runAsync(
        () => container
            .read(notificationRepositoryProvider)
            .getSavingReminder(),
      );
      expect(saved!.amount, 200000);
      expect(saved.enabled, isFalse);
      expect(find.text(AppStrings.savingStatusInactive), findsOneWidget);
    });

    testWidgets('navigasi penuh notifikasi -> pengaturan -> menabung',
        (tester) async {
      await _pumpNotifications(tester);

      await _tapVisible(tester, find.byIcon(Icons.more_horiz));
      await _tapVisible(tester, find.text(AppStrings.notifMenuSettings));
      expect(find.text(AppStrings.notifSettingsTitle), findsOneWidget);
      await _tapVisible(
        tester,
        find.text(AppStrings.reminderSavingsTitle),
      );
      expect(find.text(AppStrings.savingAmountLabel), findsOneWidget);
    });
  });
}

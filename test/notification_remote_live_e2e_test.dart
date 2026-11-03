import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_auth_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_notification_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_transaction_repository.dart';
import 'package:tahan_dulu/data/datasources/remote/token_storage.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/reminder_settings.dart';

void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final client = ApiClient(baseUrl: baseUrl);

  group('Notification & Reminders Live End-to-End Remote Integration Verification', () {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userAEmail = 'alice_notif_$timestamp@example.com';
    final userBEmail = 'bob_notif_$timestamp@example.com';
    const password = 'Password123!';

    final tokenStoreA = MemoryTokenStore();
    final tokenStoreB = MemoryTokenStore();

    late RemoteAuthRepository authRepoA;
    late RemoteAccountRepository accountRepoA;
    late RemoteTransactionRepository transactionRepoA;
    late RemoteNotificationRepository notifRepoA;

    late RemoteAuthRepository authRepoB;
    late RemoteNotificationRepository notifRepoB;

    setUpAll(() async {
      authRepoA = RemoteAuthRepository(client: client, tokens: tokenStoreA);
      accountRepoA = RemoteAccountRepository(client: client, tokens: tokenStoreA);
      transactionRepoA = RemoteTransactionRepository(client: client, tokens: tokenStoreA);
      notifRepoA = RemoteNotificationRepository(client: client, tokens: tokenStoreA);

      authRepoB = RemoteAuthRepository(client: client, tokens: tokenStoreB);
      notifRepoB = RemoteNotificationRepository(client: client, tokens: tokenStoreB);
    });

    test('1. Setup User A dan User B registrasi pada backend Laravel', () async {
      final userA = await authRepoA.register(
        name: 'Alice Notification',
        email: userAEmail,
        password: password,
      );
      expect(userA.email, userAEmail);
      final tokenA = await tokenStoreA.readToken();
      expect(tokenA, isNotNull);

      final userB = await authRepoB.register(
        name: 'Bob Notification',
        email: userBEmail,
        password: password,
      );
      expect(userB.email, userBEmail);
      final tokenB = await tokenStoreB.readToken();
      expect(tokenB, isNotNull);
    });

    test('2. Setup akun keuangan awal User A (saldo Rp10.000.000)', () async {
      final acc = await accountRepoA.addAccount(
        const FinancialAccount(
          id: '',
          name: 'Rekening Operasional Alice',
          type: AccountType.bank,
          balance: 10000000,
          typeId: 1,
        ),
      );
      expect(acc.balance, 10000000.0);

      final totalBalance = await accountRepoA.getTotalBalance();
      expect(totalBalance, 10000000.0);
    });

    test('3. Baca 6 preferensi notifikasi awal User A dari backend', () async {
      final prefs = await notifRepoA.getPreferences();
      expect(prefs.length, 6);

      final prefMap = {for (final p in prefs) p.type: p.enabled};
      expect(prefMap[ReminderType.salary], isTrue);
      expect(prefMap[ReminderType.savings], isTrue);
      expect(prefMap[ReminderType.bills], isTrue);
      expect(prefMap[ReminderType.budget], isTrue);
      expect(prefMap[ReminderType.tahandulu], isTrue);
      expect(prefMap[ReminderType.overspending], isTrue);
    });

    test('4. Perbarui preferensi overspending menjadi false secara parsial', () async {
      await notifRepoA.setPreference(ReminderType.overspending, false);

      final updatedPrefs = await notifRepoA.getPreferences();
      final prefMap = {for (final p in updatedPrefs) p.type: p.enabled};

      // Hanya overspending yang berubah, 5 lainnya tetap true
      expect(prefMap[ReminderType.overspending], isFalse);
      expect(prefMap[ReminderType.salary], isTrue);
      expect(prefMap[ReminderType.savings], isTrue);
      expect(prefMap[ReminderType.bills], isTrue);
      expect(prefMap[ReminderType.budget], isTrue);
      expect(prefMap[ReminderType.tahandulu], isTrue);
    });

    test('5. Ambil konfigurasi pengingat menabung awal (belum diatur)', () async {
      final initialReminder = await notifRepoA.getSavingReminder();
      expect(initialReminder.amount, 200000.0);
      expect(initialReminder.frequency, SavingFrequency.monthly);
    });

    test('6. Simpan konfigurasi pengingat menabung bulanan ke backend', () async {
      const configToSave = SavingReminderConfig(
        amount: 500000,
        frequency: SavingFrequency.monthly,
        dayOfMonth: 15,
        hour: 20,
        minute: 30,
        enabled: true,
      );

      final saved = await notifRepoA.saveSavingReminder(configToSave);
      expect(saved.amount, 500000.0);
      expect(saved.frequency, SavingFrequency.monthly);
      expect(saved.dayOfMonth, 15);
      expect(saved.hour, 20);
      expect(saved.minute, 30);
      expect(saved.timeLabel, '20:30');
      expect(saved.enabled, isTrue);

      // Verifikasi ulang dengan get
      final fetched = await notifRepoA.getSavingReminder();
      expect(fetched.amount, 500000.0);
      expect(fetched.timeLabel, '20:30');
    });

    test('7. Nonaktifkan pengingat menabung (deactivate)', () async {
      final deactivated = await notifRepoA.deactivateSavingReminder();
      expect(deactivated.enabled, isFalse);
      expect(deactivated.amount, 500000.0);

      final fresh = await notifRepoA.getSavingReminder();
      expect(fresh.enabled, isFalse);
    });

    test('8. Baca feed notifikasi dan unread count awal', () async {
      final list = await notifRepoA.getNotifications();
      final unreadCount = await notifRepoA.getUnreadCount();

      expect(list, isA<List>());
      expect(unreadCount, list.where((e) => !e.isRead).length);
    });

    test('9. Isolasi data: User B memiliki preferensi & pengingat independen', () async {
      final prefsB = await notifRepoB.getPreferences();
      final prefMapB = {for (final p in prefsB) p.type: p.enabled};
      // Overspending User B tetap default true, tidak terpengaruh User A
      expect(prefMapB[ReminderType.overspending], isTrue);

      final reminderB = await notifRepoB.getSavingReminder();
      // Konfigurasi B belum diatur (default), tidak terpengaruh nominal 500k milik User A
      expect(reminderB.amount, 200000.0);
    });

    test('10. Integritas Finansial: Seluruh operasi notifikasi tidak merubah saldo/transaksi', () async {
      final balance = await accountRepoA.getTotalBalance();
      expect(balance, 10000000.0);

      final txs = await transactionRepoA.getTransactions();
      expect(txs.isEmpty, isTrue);
    });
  });
}


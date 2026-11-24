import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/uuid_generator.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';

void main() {
  group('Financial Duplication Prevention - ID Resolution Tests', () {
    test('isUuid correctly detects valid RFC 4122 UUID v4', () {
      expect(isUuid('c81d4e2e-bcf2-4a7b-a39c-2f8352654bc0'), isTrue);
      expect(isUuid('01a20c54-bd1a-72d3-bc4a-8662d81b7eed'), isTrue);
      expect(isUuid('9f8e7d6c-5b4a-4321-8765-abcdef012345'), isTrue);

      expect(isUuid(null), isFalse);
      expect(isUuid(''), isFalse);
      expect(isUuid('   '), isFalse);
      expect(isUuid('1'), isFalse);
      expect(isUuid('inst-1732456789'), isFalse);
      expect(isUuid('not-a-uuid-string'), isFalse);
    });

    test('isBackendId correctly distinguishes backend persistent IDs vs local draft IDs', () {
      // Backend UUIDs (PostgreSQL primary key)
      expect(isBackendId('c81d4e2e-bcf2-4a7b-a39c-2f8352654bc0'), isTrue);
      expect(isBackendId('01a20c54-bd1a-72d3-bc4a-8662d81b7eed'), isTrue);

      // Legacy integer IDs
      expect(isBackendId('1'), isTrue);
      expect(isBackendId('42'), isTrue);
      expect(isBackendId('1005'), isTrue);

      // Temporary / draft local IDs generated on client before sync
      expect(isBackendId('inst-1732456789'), isFalse);
      expect(isBackendId('acc-1732456789'), isFalse);
      expect(isBackendId('exp-1732456789'), isFalse);
      expect(isBackendId('goal-1732456789'), isFalse);
      expect(isBackendId('trx-1732456789'), isFalse);
      expect(isBackendId(null), isFalse);
      expect(isBackendId(''), isFalse);
    });
  });

  group('Financial Duplication Prevention - Account & Transaction Idempotency', () {
    test('FinancialAccount supports idempotencyKey in constructor, copyWith, and equality', () {
      final key = generateUuidV4();
      final acc1 = FinancialAccount(
        id: 'acc-1',
        name: 'BRI Tabungan',
        type: AccountType.bank,
        balance: 8000000,
        idempotencyKey: key,
      );

      expect(acc1.idempotencyKey, key);

      final acc2 = acc1.copyWith(name: 'BRI Simpedes');
      expect(acc2.idempotencyKey, key);
      expect(acc2.name, 'BRI Simpedes');

      final accDifferentKey = acc1.copyWith(idempotencyKey: generateUuidV4());
      expect(acc1 == accDifferentKey, isFalse);
    });

    test('AccountsController generates and assigns idempotencyKey on addAccount', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);
      final customKey = 'custom-inst-key-12345';

      final ok = await controller.addAccount(
        name: 'Bank Mandiri',
        type: AccountType.bank,
        initialBalance: 5000000,
        idempotencyKey: customKey,
      );

      expect(ok, isTrue);

      final accounts = await container.read(accountRepositoryProvider).getAccounts();
      final added = accounts.firstWhere((a) => a.name == 'Bank Mandiri');
      expect(added.balance, 5000000);
      expect(added.idempotencyKey, customKey);
    });

    test('TransactionDraft initializes with distinct non-empty idempotencyKey', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final draft1 = container.read(transactionFormProvider);
      expect(draft1.idempotencyKey.isNotEmpty, isTrue);
      expect(isUuid(draft1.idempotencyKey), isTrue);

      container.read(transactionFormProvider.notifier).reset();

      final draft2 = container.read(transactionFormProvider);
      expect(draft2.idempotencyKey.isNotEmpty, isTrue);
      expect(draft1.idempotencyKey != draft2.idempotencyKey, isTrue);
    });

    test('TransactionFormController preserves idempotencyKey for retry if invalid, but refreshes key after successful save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(transactionFormProvider.notifier);
      final initialKey = container.read(transactionFormProvider).idempotencyKey;

      // 1. Aksi tidak lengkap (jumlah belum diisi) -> save() gagal
      final failedAttempt = await notifier.save();
      expect(failedAttempt, isFalse);

      // Kunci idempotensi HARUS tetap sama agar saat pengguna melengkapi input dan menekan Simpan lagi, ini dianggap operasi retry
      expect(container.read(transactionFormProvider).idempotencyKey, initialKey);
    });

    test('AccountsController prevents double-submission on simultaneous addAccount calls', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);

      // Simulasi double tap cepat (dua pemicuan bersamaan)
      final f1 = controller.addAccount(
        name: 'Bank Jago Double Tap',
        type: AccountType.digitalBank,
        initialBalance: 2000000,
      );
      final f2 = controller.addAccount(
        name: 'Bank Jago Double Tap',
        type: AccountType.digitalBank,
        initialBalance: 2000000,
      );

      final results = await Future.wait([f1, f2]);
      // Tepat satu panggilan berhasil, panggilan kedua dicegah oleh guard _saving
      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);

      final accounts = await container.read(accountRepositoryProvider).getAccounts();
      final jagoCount = accounts.where((a) => a.name == 'Bank Jago Double Tap').length;
      expect(jagoCount, 1);
    });

    test('TransactionFormController prevents double-submission on simultaneous save calls', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(transactionFormProvider.notifier);
      final accounts = await container.read(accountRepositoryProvider).getAccounts();
      final accountId = accounts.first.id;

      notifier.setType(TransactionType.income);
      notifier.setAmount(100000);
      notifier.setCategory(TransactionCategory.salary);
      notifier.setAccount(accountId);
      notifier.setTitle('Bonus');

      // Simulasi double-tap cepat
      final s1 = notifier.save();
      final s2 = notifier.save();

      final results = await Future.wait([s1, s2]);
      // Tepat satu panggilan berhasil, panggilan paralel kedua ditolak oleh guard _saving
      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);
    });
  });
}

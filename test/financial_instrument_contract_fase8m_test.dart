import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/datasources/remote/remote_account_repository.dart';
import 'package:tahan_dulu/data/models/api_bank.dart';
import 'package:tahan_dulu/data/models/api_financial_instrument.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/accounts/presentation/providers/accounts_controller.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/add_account_screen.dart';

class _FakeAccountRepository implements AccountRepository {
  final List<FinancialAccount> accounts = [];
  FinancialAccount? lastAddedAccount;

  @override
  Future<List<FinancialAccount>> getAccounts() async => List.unmodifiable(accounts);

  @override
  Future<double> getTotalBalance() async =>
      accounts.fold<double>(0.0, (double sum, a) => sum + a.balance);

  @override
  Future<FinancialAccount> addAccount(FinancialAccount account) async {
    lastAddedAccount = account;
    accounts.add(account);
    return account;
  }

  @override
  Future<FinancialAccount> updateAccount(FinancialAccount account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) accounts[idx] = account;
    return account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> removeAccount(String id) async {
    accounts.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> reconcileLegacyCash({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {}

  @override
  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {
    final fromIdx = accounts.indexWhere((a) => a.id == fromId);
    final toIdx = accounts.indexWhere((a) => a.id == toId);
    if (fromIdx != -1 && toIdx != -1) {
      accounts[fromIdx] = accounts[fromIdx].copyWith(
        balance: accounts[fromIdx].balance - amount,
      );
      accounts[toIdx] = accounts[toIdx].copyWith(
        balance: accounts[toIdx].balance + amount,
      );
    }
  }
}

class _FakeInstrumentTypeRepository implements InstrumentTypeRepository {
  _FakeInstrumentTypeRepository(this.types);
  final List<ApiInstrumentType> types;

  @override
  Future<List<ApiInstrumentType>> getInstrumentTypes() async => types;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bankUuid = '01a207f3-4ad5-73f3-8a8b-01ead773d6ac';
  const digitalBankUuid = '01a207f3-f589-725c-a0d8-df47290096be';
  const ewalletUuid = '01a207f3-4ae5-70be-a837-7665f238bcd9';

  final sampleTypes = [
    const ApiInstrumentType(id: bankUuid, name: 'Bank', type: 'bank'),
    const ApiInstrumentType(id: digitalBankUuid, name: 'Bank Digital', type: 'digitalBank'),
    const ApiInstrumentType(id: ewalletUuid, name: 'E-Wallet', type: 'ewallet'),
  ];

  group('Fase 8M: Contract & Model Type Tests', () {
    test('1. ApiInstrumentType parses UUID strings without collapsing to 0', () {
      final json = {
        'id': bankUuid,
        'name': 'Bank',
        'type': 'bank',
        'logo_url': 'https://example.com/bank.png',
      };
      final parsed = ApiInstrumentType.fromJson(json);
      expect(parsed.id, bankUuid);
      expect(parsed.id, isNot('0'));
      expect(parsed.name, 'Bank');
      expect(parsed.type, 'bank');
    });

    test('2. FinancialAccount preserves String typeId UUID', () {
      const account = FinancialAccount(
        id: 'acc-uuid-1',
        name: 'BCA Utama',
        type: AccountType.bank,
        typeId: bankUuid,
        balance: 5000000,
        bankId: 111,
        bankSlug: 'bca',
      );
      expect(account.typeId, bankUuid);
      final copied = account.copyWith(name: 'BCA Secondary');
      expect(copied.typeId, bankUuid);
      expect(copied.name, 'BCA Secondary');
    });

    test('3. AccountsController resolves typeId from UUID and creates FinancialAccount with UUID typeId', () async {
      final fakeRepo = _FakeAccountRepository();
      final container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(accountsControllerProvider);
      final ok = await controller.addAccount(
        name: 'Bank Jago',
        type: AccountType.digitalBank,
        typeId: digitalBankUuid,
        initialBalance: 2500000,
        bankId: 5,
        bankSlug: 'jago',
      );

      expect(ok, isTrue);
      expect(fakeRepo.lastAddedAccount, isNotNull);
      expect(fakeRepo.lastAddedAccount!.name, 'Bank Jago');
      expect(fakeRepo.lastAddedAccount!.typeId, digitalBankUuid);
      expect(fakeRepo.lastAddedAccount!.type, AccountType.digitalBank);
      expect(fakeRepo.lastAddedAccount!.balance, 2500000.0);
    });
  });

  group('Fase 8M: AddAccountScreen UI & Dropdown UUID Tests', () {
    testWidgets('4. AddAccountScreen loads UUID instrument types and sends UUID typeId on save', (tester) async {
      final fakeRepo = _FakeAccountRepository();
      final fakeTypesRepo = _FakeInstrumentTypeRepository(sampleTypes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(fakeRepo),
            instrumentTypeRepositoryProvider.overrideWithValue(fakeTypesRepo),
          ],
          child: const MaterialApp(home: AddAccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Dropdown should be present as DropdownButtonFormField<String>
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      expect(dropdownFinder, findsOneWidget);

      // Open dropdown and select E-Wallet
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('E-Wallet').last);
      await tester.pumpAndSettle();

      // Enter account name & balance
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'GoPay Pribadi');
      await tester.enterText(fields.at(2), '500.000');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text(AppStrings.saveAccount));
      await tester.pumpAndSettle();

      // Verify that the repository received the account with ewalletUuid
      expect(fakeRepo.lastAddedAccount, isNotNull);
      expect(fakeRepo.lastAddedAccount!.name, 'GoPay Pribadi');
      expect(fakeRepo.lastAddedAccount!.typeId, ewalletUuid);
      expect(fakeRepo.lastAddedAccount!.balance, 500000.0);
    });

    testWidgets('5. AddAccountScreen displays validation error when type is unselected', (tester) async {
      final fakeRepo = _FakeAccountRepository();
      final fakeTypesRepo = _FakeInstrumentTypeRepository(sampleTypes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(fakeRepo),
            instrumentTypeRepositoryProvider.overrideWithValue(fakeTypesRepo),
          ],
          child: const MaterialApp(home: AddAccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name and balance but leave instrument type unselected
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Akun Tanpa Tipe');
      await tester.enterText(fields.at(2), '100.000');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text(AppStrings.saveAccount));
      await tester.pumpAndSettle();

      // Should display required error and NOT add account to repo
      expect(find.text(AppStrings.instrumentTypeRequired), findsOneWidget);
      expect(fakeRepo.lastAddedAccount, isNull);
    });
  });
}

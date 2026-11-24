import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/uuid_generator.dart';
import 'package:tahan_dulu/data/datasources/remote/api_client.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_review_screen.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<AppTransaction> savedTransactions = [];
  bool failNextSaveWithTimeout = false;

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    if (failNextSaveWithTimeout) {
      failNextSaveWithTimeout = false;
      throw ApiException(
        'Koneksi terputus saat menyimpan transaksi (timeout)',
        statusCode: 504,
      );
    }
    savedTransactions.add(transaction);
    return transaction;
  }

  @override
  Future<List<AppTransaction>> getRecentTransactions() async =>
      savedTransactions;

  @override
  Future<AppTransaction> getTransactionById(String id) async =>
      savedTransactions.firstWhere((t) => t.id == id);

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    dynamic instrumentId,
    int? perPage,
    int? page,
  }) async =>
      savedTransactions;

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async =>
      transaction;

  @override
  Future<void> deleteTransaction(String id) async {
    savedTransactions.removeWhere((t) => t.id == id);
  }
}

void main() {
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  group('UUID Generator Tests', () {
    test('generateUuidV4 produces valid RFC 4122 v4 UUID format', () {
      final key = generateUuidV4();
      expect(key, isNotEmpty);
      expect(uuidRegex.hasMatch(key), isTrue);
    });

    test('generateUuidV4 generates 100 distinct unique keys without collision', () {
      final keys = <String>{};
      for (var i = 0; i < 100; i++) {
        keys.add(generateUuidV4());
      }
      expect(keys.length, equals(100));
    });
  });

  group('FASE E Flutter Idempotency Scenarios (IDE-07 to IDE-12)', () {
    late FakeTransactionRepository fakeRepo;
    late ProviderContainer container;

    setUp(() async {
      fakeRepo = FakeTransactionRepository();
      container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
          accountsProvider.overrideWith(
            (ref) => Future.value([
              const FinancialAccount(
                id: 'acc-1',
                name: 'BCA Utama',
                type: AccountType.bank,
                balance: 1000000,
                institutionName: 'BCA',
              ),
            ]),
          ),
        ],
      );
      await container.read(accountsProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('IDE-07: Flutter generates idempotency_key when draft is built and preserves it across form updates', () {
      final draft = container.read(transactionFormProvider);
      expect(draft.idempotencyKey, isNotEmpty);
      expect(uuidRegex.hasMatch(draft.idempotencyKey), isTrue);

      final initialKey = draft.idempotencyKey;

      // Ubah berbagai field transaksi
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setTitle('Makan Bakso');
      notifier.setAmount(35000);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('acc-1');
      notifier.setNote('Pedas sedang');
      notifier.setFee(2000);
      notifier.setDate(DateTime(2026, 11, 8));

      final updatedDraft = container.read(transactionFormProvider);
      expect(updatedDraft.idempotencyKey, equals(initialKey));
      expect(updatedDraft.title, equals('Makan Bakso'));
      expect(updatedDraft.amount, equals(35000));
    });

    testWidgets('IDE-08: Flutter review screen rebuild does NOT regenerate idempotency_key', (tester) async {
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setTitle('Belanja Bulanan');
      notifier.setAmount(150000);
      notifier.setCategory(TransactionCategory.shopping);
      notifier.setAccount('acc-1');
      notifier.setDate(DateTime.now());

      final draftBeforeReview = container.read(transactionFormProvider);
      final keyBeforeReview = draftBeforeReview.idempotencyKey;
      expect(keyBeforeReview, isNotEmpty);

      // Render TransactionReviewScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionReviewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(transactionFormProvider).idempotencyKey, equals(keyBeforeReview));

      // Trigger multi-frame rebuilds (seperti orientation change atau UI redraw)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionReviewScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final keyAfterRebuild = container.read(transactionFormProvider).idempotencyKey;
      expect(keyAfterRebuild, equals(keyBeforeReview));
    });

    test('IDE-09: Flutter network retry sends the EXACT same idempotency_key and payload', () async {
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.setTitle('Makan Siang');
      notifier.setAmount(50000);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('acc-1');
      notifier.setDate(DateTime.now());

      final key = container.read(transactionFormProvider).idempotencyKey;
      expect(key, isNotEmpty);

      // 1. Simulasikan kegagalan jaringan (timeout 504) saat save pertama
      fakeRepo.failNextSaveWithTimeout = true;
      expect(fakeRepo.savedTransactions, isEmpty);

      ApiException? caughtError;
      try {
        await notifier.save();
      } on ApiException catch (e) {
        caughtError = e;
      }
      expect(caughtError, isNotNull);
      expect(caughtError!.statusCode, equals(504));

      // Kunci idempotensi draf tetap sama setelah gagal
      expect(container.read(transactionFormProvider).idempotencyKey, equals(key));
      expect(fakeRepo.savedTransactions, isEmpty);

      // 2. Retry simpan transaksi (user tap Coba Lagi / Simpan)
      final ok = await notifier.save();
      expect(ok, isTrue);

      // Repository menerima 1 transaksi dengan idempotencyKey yang sama persis
      expect(fakeRepo.savedTransactions.length, equals(1));
      final savedTx = fakeRepo.savedTransactions.first;
      expect(savedTx.idempotencyKey, equals(key));
      expect(savedTx.amount, equals(50000));
      expect(savedTx.title, equals('Makan Siang'));
    });

    test('IDE-10: Flutter reset() generates a fresh, distinct idempotency_key for a new transaction', () {
      final keyFirst = container.read(transactionFormProvider).idempotencyKey;
      expect(keyFirst, isNotEmpty);

      // User menyelesaikan atau membatalkan draf, lalu reset dipanggil untuk transaksi baru
      container.read(transactionFormProvider.notifier).reset();

      final keySecond = container.read(transactionFormProvider).idempotencyKey;
      expect(keySecond, isNotEmpty);
      expect(uuidRegex.hasMatch(keySecond), isTrue);

      // Kunci baru harus berbeda secara kriptografis dari kunci sebelumnya
      expect(keySecond, isNot(equals(keyFirst)));
    });

    test('IDE-11: Voice transaction carries idempotency_key from voice screen through to final save', () async {
      // Masuk ke alur pencatatan suara: reset draf
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.reset();
      final voiceDraftKey = container.read(transactionFormProvider).idempotencyKey;
      expect(voiceDraftKey, isNotEmpty);

      // Simulasikan konfirmasi hasil parsing suara (seperti di TransactionVoiceScreen._confirmAndReview)
      notifier.setType(TransactionType.expense);
      notifier.setAmount(25000);
      notifier.setCategory(TransactionCategory.food);
      notifier.setAccount('acc-1');
      notifier.setDate(DateTime.now());
      notifier.setTitle('Beli Nasi Goreng');
      notifier.setNote('Beli Nasi Goreng');

      // Pastikan key tetap utuh setelah integrasi data suara
      expect(container.read(transactionFormProvider).idempotencyKey, equals(voiceDraftKey));

      // Simpan transaksi
      final ok = await notifier.save();
      expect(ok, isTrue);

      // Pastikan payload transaksi yang dikirim ke remote repo memuat idempotencyKey yang sama
      expect(fakeRepo.savedTransactions.length, equals(1));
      expect(fakeRepo.savedTransactions.first.idempotencyKey, equals(voiceDraftKey));
      expect(fakeRepo.savedTransactions.first.title, equals('Beli Nasi Goreng'));
      expect(fakeRepo.savedTransactions.first.amount, equals(25000));
    });

    test('IDE-12: Scan receipt transaction carries idempotency_key through to final save', () async {
      // Masuk ke alur scan struk: reset draf
      final notifier = container.read(transactionFormProvider.notifier);
      notifier.reset();
      final scanDraftKey = container.read(transactionFormProvider).idempotencyKey;
      expect(scanDraftKey, isNotEmpty);

      // Simulasikan konfirmasi hasil parsing struk (seperti di TransactionScanScreen._confirmAndNavigateToForm)
      notifier.setType(TransactionType.expense);
      notifier.setAmount(121000);
      notifier.setDate(DateTime.now());
      notifier.setTitle('Indomaret Point');
      notifier.setNote('Item: Susu UHT, Roti Gandum');
      // Lengkapi kategori dan akun
      notifier.setCategory(TransactionCategory.shopping);
      notifier.setAccount('acc-1');

      // Pastikan key tetap utuh setelah integrasi data struk
      expect(container.read(transactionFormProvider).idempotencyKey, equals(scanDraftKey));

      // Simpan transaksi
      final ok = await notifier.save();
      expect(ok, isTrue);

      // Pastikan payload transaksi yang dikirim ke remote repo memuat idempotencyKey yang sama
      expect(fakeRepo.savedTransactions.length, equals(1));
      expect(fakeRepo.savedTransactions.first.idempotencyKey, equals(scanDraftKey));
      expect(fakeRepo.savedTransactions.first.title, equals('Indomaret Point'));
      expect(fakeRepo.savedTransactions.first.amount, equals(121000));
    });
  });
}

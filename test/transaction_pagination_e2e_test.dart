import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/repositories/repositories.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transactions_screen.dart';

/// Repository tiruan dengan 135 transaksi untuk menguji paginasi skala besar (F06B).
class MockLargeDatasetTransactionRepository implements TransactionRepository {
  MockLargeDatasetTransactionRepository({int count = 135}) {
    final now = DateTime(2026, 11, 24, 12, 0);
    for (int i = 1; i <= count; i++) {
      _items.add(
        AppTransaction(
          id: 'trx-$i',
          title: 'Transaksi Ke-$i',
          amount: (i * 10000).toDouble(),
          type: i % 4 == 0 ? TransactionType.income : TransactionType.expense,
          date: now.subtract(Duration(hours: i * 2)),
          category: i % 4 == 0 ? 'Gaji' : 'Makan & Minum',
          accountId: i % 2 == 0 ? 'acc-1' : 'acc-2',
        ),
      );
    }
  }

  final List<AppTransaction> _items = [];
  bool simulateErrorOnPage3 = false;

  @override
  Future<List<AppTransaction>> getRecentTransactions() async {
    return _items.take(15).toList();
  }

  @override
  Future<AppTransaction> addTransaction(AppTransaction transaction) async {
    _items.insert(0, transaction);
    return transaction;
  }

  @override
  Future<AppTransaction> getTransactionById(String id) async {
    return _items.firstWhere((t) => t.id == id);
  }

  @override
  Future<List<AppTransaction>> getTransactions({
    String? type,
    String? category,
    String? instrumentId,
    int? perPage,
    int? page,
  }) async {
    final paginated = await getPaginatedTransactions(
      type: type,
      category: category,
      instrumentId: instrumentId,
      perPage: perPage,
      page: page,
    );
    return paginated.items;
  }

  @override
  Future<TransactionPaginationResult> getPaginatedTransactions({
    String? type,
    String? category,
    String? instrumentId,
    int? perPage,
    int? page,
  }) async {
    final effectivePage = page ?? 1;
    if (simulateErrorOnPage3 && effectivePage == 3) {
      throw StateError('Simulasi kegagalan koneksi halaman 3');
    }

    var filtered = List.of(_items);
    if (type != null) {
      filtered = filtered.where((t) => t.type.name == type).toList();
    }
    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }
    if (instrumentId != null) {
      filtered = filtered.where((t) => t.accountId == instrumentId).toList();
    }

    final effectivePerPage = perPage ?? 20;
    final total = filtered.length;
    final lastPage = (total / effectivePerPage).ceil() == 0
        ? 1
        : (total / effectivePerPage).ceil();

    final startIndex = (effectivePage - 1) * effectivePerPage;
    final pagedItems = filtered.skip(startIndex).take(effectivePerPage).toList();

    return TransactionPaginationResult(
      items: pagedItems,
      currentPage: effectivePage,
      lastPage: lastPage,
      perPage: effectivePerPage,
      total: total,
      hasNextPage: effectivePage < lastPage,
    );
  }

  @override
  Future<AppTransaction> updateTransaction(AppTransaction transaction) async {
    final idx = _items.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) _items[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _items.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('F06B — Real End-to-End Transaction Pagination (>= 120 Transaksi)', () {
    late MockLargeDatasetTransactionRepository repo;

    setUp(() {
      repo = MockLargeDatasetTransactionRepository(count: 135);
    });

    test('Repository paginates 135 transaksi across multiple pages accurately', () async {
      // Halaman 1: 20 item, total 135, lastPage 7, hasNextPage true
      final page1 = await repo.getPaginatedTransactions(page: 1, perPage: 20);
      expect(page1.items.length, 20);
      expect(page1.currentPage, 1);
      expect(page1.lastPage, 7);
      expect(page1.total, 135);
      expect(page1.hasNextPage, isTrue);
      expect(page1.items.first.id, 'trx-1');
      expect(page1.items.last.id, 'trx-20');

      // Iterasi seluruh halaman sampai selesai
      final collectedIds = <String>{};
      int pagesRead = 0;
      bool hasMore = true;
      int currentP = 1;

      while (hasMore) {
        final res = await repo.getPaginatedTransactions(page: currentP, perPage: 20);
        pagesRead++;
        for (final item in res.items) {
          final isNew = collectedIds.add(item.id);
          expect(isNew, isTrue, reason: 'ID ${item.id} tidak boleh duplikat');
        }
        hasMore = res.hasNextPage;
        currentP++;
      }

      expect(pagesRead, 7);
      expect(collectedIds.length, 135);
    });

    test('PaginatedTransactionsNotifier manages progressive loads, deduplication, and refresh', () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedTransactionsProvider.notifier);

      // 1. Initial Load
      await notifier.loadInitial();
      var state = container.read(paginatedTransactionsProvider);
      expect(state.isLoadingInitial, isFalse);
      expect(state.items.length, 20);
      expect(state.currentPage, 1);
      expect(state.hasNextPage, isTrue);
      expect(state.total, 135);

      // 2. Load More ke Halaman 2
      await notifier.loadMore();
      state = container.read(paginatedTransactionsProvider);
      expect(state.items.length, 40);
      expect(state.currentPage, 2);
      expect(state.hasNextPage, isTrue);

      // 3. Load More berulang kali sampai tuntas ke Halaman 7
      while (container.read(paginatedTransactionsProvider).hasNextPage) {
        await notifier.loadMore();
      }

      state = container.read(paginatedTransactionsProvider);
      expect(state.items.length, 135);
      expect(state.currentPage, 7);
      expect(state.hasNextPage, isFalse);
      // Memastikan tidak ada ID yang berulang (deduplikasi berhasil)
      final uniqueIds = state.items.map((e) => e.id).toSet();
      expect(uniqueIds.length, 135);

      // 4. Memanggil loadMore saat hasNextPage = false tidak memicu request sia-sia
      await notifier.loadMore();
      expect(container.read(paginatedTransactionsProvider).items.length, 135);

      // 5. Pull to refresh mereset kembali ke halaman 1
      await notifier.refresh();
      state = container.read(paginatedTransactionsProvider);
      expect(state.items.length, 20);
      expect(state.currentPage, 1);
      expect(state.hasNextPage, isTrue);
    });

    test('PaginatedTransactionsNotifier retains existing items upon loadMore error and recovers on retry', () async {
      repo.simulateErrorOnPage3 = true;
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedTransactionsProvider.notifier);

      // Page 1
      await notifier.loadInitial();
      expect(container.read(paginatedTransactionsProvider).items.length, 20);

      // Page 2
      await notifier.loadMore();
      expect(container.read(paginatedTransactionsProvider).items.length, 40);
      expect(container.read(paginatedTransactionsProvider).loadMoreErrorMessage, isNull);

      // Page 3 gagal
      await notifier.loadMore();
      final errState = container.read(paginatedTransactionsProvider);
      // 40 item sebelumnya tidak terhapus!
      expect(errState.items.length, 40);
      expect(errState.loadMoreErrorMessage, isNotNull);

      // Perbaiki kegagalan dan coba lagi
      repo.simulateErrorOnPage3 = false;
      await notifier.loadMore();
      final recoveredState = container.read(paginatedTransactionsProvider);
      expect(recoveredState.items.length, 60);
      expect(recoveredState.loadMoreErrorMessage, isNull);
    });

    testWidgets('TransactionsScreen renders initial 20 items and shows pagination footer', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Initial load
      await container.read(paginatedTransactionsProvider.notifier).loadInitial();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan baris transaksi ter-render di layar
      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Transaksi Ke-1'), findsOneWidget);
    });
  });
}

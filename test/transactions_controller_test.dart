import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/rupiah_input_formatter.dart';
import 'package:tahan_dulu/data/models/transaction_model.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/transactions/presentation/providers/transactions_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void _fillValid(TransactionFormController notifier) {
  notifier.setType(TransactionType.expense);
  notifier.setAmount(41000);
  notifier.setCategory(TransactionCategory.food);
  notifier.setAccount('inst-bca');
  notifier.setDate(DateTime(2026, 10, 9));
  notifier.setNote('Ayam geprek');
}

void main() {
  test('draft defaults are incomplete', () {
    final draft = _container().read(transactionFormProvider);

    expect(draft.isAmountValid, isFalse);
    expect(draft.isCategoryValid, isFalse);
  });

  test('draft becomes complete when all fields valid', () {
    final container = _container();
    final notifier = container.read(transactionFormProvider.notifier);
    _fillValid(notifier);

    final ids = {
      for (final e in container
          .read(onboardingRepositoryProvider)
          .getOnboardingData()!
          .financialInstruments)
        e.id,
    };
    expect(container.read(transactionFormProvider).isComplete(ids), isTrue);
  });

  test('unknown account is rejected', () {
    final container = _container();
    final notifier = container.read(transactionFormProvider.notifier);
    _fillValid(notifier);
    notifier.setAccount('inst-tidak-ada');

    expect(
      container.read(transactionFormProvider).isComplete({'inst-bca'}),
      isFalse,
    );
  });

  test('save persists through repository and refreshes list', () async {
    final container = _container();
    final notifier = container.read(transactionFormProvider.notifier);
    _fillValid(notifier);

    final before =
        await container.read(transactionsProvider.future).then((l) => l.length);
    expect(await notifier.save(), isTrue);

    final after = await container.read(transactionsProvider.future);
    expect(after.length, before + 1);
    expect(after.first.title, 'Makanan');
    expect(after.first.note, 'Ayam geprek');
    expect(notifier.lastSaved?.amount, 41000);
  });

  test('concurrent save adds only one transaction', () async {
    final container = _container();
    final notifier = container.read(transactionFormProvider.notifier);
    _fillValid(notifier);

    final results = await Future.wait([notifier.save(), notifier.save()]);
    expect(results.where((e) => e).length, 1);

    final repo = container.read(transactionRepositoryProvider);
    final items = await repo.getRecentTransactions();
    expect(items.where((e) => e.note == 'Ayam geprek').length, 1);
  });

  test('save refuses incomplete draft', () async {
    final container = _container();
    expect(
      await container.read(transactionFormProvider.notifier).save(),
      isFalse,
    );
  });

  test('reset clears draft and saved state', () async {
    final container = _container();
    final notifier = container.read(transactionFormProvider.notifier);
    _fillValid(notifier);
    expect(await notifier.save(), isTrue);

    notifier.reset();
    final draft = container.read(transactionFormProvider);
    expect(draft.amount, 0);
    expect(draft.category, isNull);
    expect(notifier.lastSaved, isNull);
  });

  test('transactions are sorted newest first', () async {
    final items = await _container().read(transactionsProvider.future);

    expect(items.length, 3);
    for (var i = 0; i < items.length - 1; i++) {
      expect(
        items[i].date.isAfter(items[i + 1].date) ||
            items[i].date.isAtSameMomentAs(items[i + 1].date),
        isTrue,
      );
    }
    expect(items.first.date, DateTime(2026, 10, 5));
  });

  group('amount parsing', () {
    test('handles rupiah separators', () {
      expect(RupiahInputFormatter.parse('Rp 5.000.000'), 5000000);
      expect(RupiahInputFormatter.parse('5.000.000'), 5000000);
      expect(RupiahInputFormatter.parse('41000'), 41000);
      expect(RupiahInputFormatter.parse(''), 0);
      expect(RupiahInputFormatter.parse('abc'), 0);
    });
  });
}

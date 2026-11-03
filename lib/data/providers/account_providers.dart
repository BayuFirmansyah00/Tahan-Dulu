import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/finance_math.dart';
import '../datasources/remote/api_config.dart';
import '../models/financial_account.dart';
import '../models/transaction_model.dart';
import 'app_providers.dart';

/// Satu akun + saldo saat ini (engine) + jumlah transaksi terkait.
class AccountOverview extends Equatable {
  const AccountOverview({
    required this.account,
    required this.currentBalance,
    required this.transactionCount,
  });

  final FinancialAccount account;
  final double currentBalance;
  final int transactionCount;

  @override
  List<Object?> get props => [account, currentBalance, transactionCount];
}

/// Daftar akun beserta saldonya dari SATU sumber kanonis.
/// Reaktif terhadap perubahan akun maupun transaksi baru.
final accountsOverviewProvider =
    FutureProvider<List<AccountOverview>>((ref) async {
  final accounts =
      await ref.watch(accountRepositoryProvider).getAccounts();
  final transactions = await ref.watch(transactionsProvider.future);

  final incomeByAccount = <String, double>{};
  final expenseByAccount = <String, double>{};
  final countByAccount = <String, int>{};
  for (final t in transactions) {
    final id = t.accountId;
    if (id == null) continue;
    countByAccount[id] = (countByAccount[id] ?? 0) + 1;
    if (t.type == TransactionType.income) {
      incomeByAccount[id] = (incomeByAccount[id] ?? 0) + t.amount;
    } else {
      expenseByAccount[id] = (expenseByAccount[id] ?? 0) + t.amount;
    }
  }

  return [
    for (final account in accounts)
      AccountOverview(
        account: account,
        currentBalance: ApiConfig.useRemoteApi
            ? account.balance
            : accountBalanceOf(
                initial: account.balance,
                income: incomeByAccount[account.id] ?? 0,
                expense: expenseByAccount[account.id] ?? 0,
              ),
        transactionCount: countByAccount[account.id] ?? 0,
      ),
  ];
});

/// Total seluruh saldo akun (agregat, bukan hardcode).
final accountsTotalProvider = FutureProvider<double>((ref) async {
  final overviews = await ref.watch(accountsOverviewProvider.future);
  return totalBalanceOf(overviews.map((e) => e.currentBalance));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';

/// Controller fitur Akun: tambah, ubah, hapus via AccountRepository.
/// Kebijakan hapus: akun yang dirujuk transaksi DITOLAK agar riwayat
/// tetap utuh (tidak ada penghapusan diam-diam).
class AccountsController {
  AccountsController(this._ref);

  final Ref _ref;

  Future<void> _refresh() async {
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountsOverviewProvider);
  }

  /// Validasi form tambah/ubah. Null bila valid.
  static String? validateName(String name) =>
      name.trim().isEmpty ? AppStrings.accountNameRequired : null;

  static String? validateInitialBalance(double value) =>
      value < 0 ? AppStrings.balanceRequired : null;

  Future<bool> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
    String? institutionName,
  }) async {
    if (validateName(name) != null) return false;
    if (validateInitialBalance(initialBalance) != null) return false;
    try {
      await _ref.read(accountRepositoryProvider).addAccount(
            FinancialAccount(
              id: 'acc-${DateTime.now().millisecondsSinceEpoch}',
              name: name.trim(),
              type: type,
              balance: initialBalance,
              institutionName: institutionName?.trim().isEmpty ?? true
                  ? null
                  : institutionName!.trim(),
            ),
          );
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double initialBalance,
    String? institutionName,
  }) async {
    if (validateName(name) != null) return false;
    if (validateInitialBalance(initialBalance) != null) return false;
    try {
      await _ref.read(accountRepositoryProvider).updateAccount(
            FinancialAccount(
              id: id,
              name: name.trim(),
              type: type,
              balance: initialBalance,
              institutionName: institutionName?.trim().isEmpty ?? true
                  ? null
                  : institutionName!.trim(),
            ),
          );
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Hapus hanya bila tak ada transaksi merujuk akun ini.
  Future<bool> deleteAccount(String id) async {
    try {
      final transactions = await _ref
          .read(transactionRepositoryProvider)
          .getRecentTransactions();
      if (transactions.any((t) => t.accountId == id)) return false;
      await _ref.read(accountRepositoryProvider).removeAccount(id);
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final accountsControllerProvider = Provider<AccountsController>((ref) {
  return AccountsController(ref);
});

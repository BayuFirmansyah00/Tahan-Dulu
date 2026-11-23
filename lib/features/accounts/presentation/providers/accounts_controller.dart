import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/reports_providers.dart';

/// Controller fitur Akun: tambah, ubah, hapus via AccountRepository.
/// Kebijakan hapus: akun yang dirujuk transaksi DITOLAK agar riwayat
/// tetap utuh (tidak ada penghapusan diam-diam).
class AccountsController {
  AccountsController(this._ref);

  final Ref _ref;

  Future<void> _refresh() async {
    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountsOverviewProvider);
    _ref.invalidate(dashboardDataProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(monthlyReportProvider);
    _ref.invalidate(apiFinancialReportProvider);
  }

  /// Validasi form transfer. Null bila valid.
  static String? validateTransferAmount(double amount, double sourceBalance) {
    if (amount <= 0) {
      return AppStrings.transferAmount;
    }
    if (amount > sourceBalance) {
      return AppStrings.transferInsufficientBalance;
    }
    return null;
  }

  Future<bool> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? notes,
    String? idempotencyKey,
  }) async {
    if (fromId == toId) return false;
    if (amount <= 0) return false;
    try {
      final key = idempotencyKey ??
          'flt-${DateTime.now().microsecondsSinceEpoch}-$fromId-$toId';
      await _ref.read(accountRepositoryProvider).transfer(
            fromId: fromId,
            toId: toId,
            amount: amount,
            notes: notes,
            idempotencyKey: key,
          );
      await _refresh();
      return true;
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  /// Validasi form tambah/ubah. Null bila valid.
  static String? validateName(String name) =>
      name.trim().isEmpty ? AppStrings.accountNameRequired : null;

  static String? validateInitialBalance(double value) =>
      value < 0 ? AppStrings.balanceRequired : null;

  /// Menyelesaikan tipe akun lokal dari `type` eksplisit atau `typeId` master.
  static AccountType _resolveAccountType(AccountType? type, String? typeId) {
    if (type != null) return type;
    final idStr = typeId?.toLowerCase().trim() ?? '';
    if (idStr == '2' || idStr == 'digitalbank' || idStr.contains('digital')) {
      return AccountType.digitalBank;
    }
    if (idStr == '3' || idStr == 'ewallet' || idStr.contains('wallet')) {
      return AccountType.ewallet;
    }
    return AccountType.bank;
  }

  Future<bool> addAccount({
    required String name,
    AccountType? type,
    String? typeId,
    required double initialBalance,
    String? institutionName,
    int? bankId,
    String? bankSlug,
    String? bankName,
    String? bankLogoUrl,
    double monthlyAdminFee = 0,
    int? adminFeeDay,
    bool adminFeeEnabled = false,
  }) async {
    if (validateName(name) != null) return false;
    if (validateInitialBalance(initialBalance) != null) return false;
    try {
      final resolvedType = _resolveAccountType(type, typeId);
      final isBankCategory = resolvedType == AccountType.bank ||
          resolvedType == AccountType.digitalBank;
      final resolvedTypeId = typeId ??
          (resolvedType == AccountType.bank
              ? 'bank'
              : (resolvedType == AccountType.digitalBank ? 'digitalBank' : 'ewallet'));
      await _ref.read(accountRepositoryProvider).addAccount(
            FinancialAccount(
              id: 'acc-${DateTime.now().millisecondsSinceEpoch}',
              name: name.trim(),
              type: resolvedType,
              typeId: resolvedTypeId,
              balance: initialBalance,
              institutionName: institutionName?.trim().isEmpty ?? true
                  ? null
                  : institutionName!.trim(),
              bankId: isBankCategory ? bankId : null,
              bankSlug: isBankCategory ? bankSlug : null,
              bankName: isBankCategory ? bankName : null,
              bankLogoUrl: isBankCategory ? bankLogoUrl : null,
              monthlyAdminFee: isBankCategory && adminFeeEnabled ? monthlyAdminFee : 0,
              adminFeeDay: isBankCategory && adminFeeEnabled ? adminFeeDay : null,
              adminFeeEnabled: isBankCategory ? adminFeeEnabled : false,
            ),
          );
      await _refresh();
      return true;
    } on ApiException {
      // Error validasi backend (422) dilaporkan melalui rethrow agar UI
      // dapat menampilkan field-specific error.
      rethrow;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    AccountType? type,
    String? typeId,
    required double initialBalance,
    String? institutionName,
    int? bankId,
    String? bankSlug,
    String? bankName,
    String? bankLogoUrl,
    double monthlyAdminFee = 0,
    int? adminFeeDay,
    bool adminFeeEnabled = false,
  }) async {
    if (validateName(name) != null) return false;
    if (validateInitialBalance(initialBalance) != null) return false;
    try {
      final resolvedType = _resolveAccountType(type, typeId);
      final isBankCategory = resolvedType == AccountType.bank ||
          resolvedType == AccountType.digitalBank;
      final resolvedTypeId = typeId ??
          (resolvedType == AccountType.bank
              ? 'bank'
              : (resolvedType == AccountType.digitalBank ? 'digitalBank' : 'ewallet'));
      await _ref.read(accountRepositoryProvider).updateAccount(
            FinancialAccount(
              id: id,
              name: name.trim(),
              type: resolvedType,
              typeId: resolvedTypeId,
              balance: initialBalance,
              institutionName: institutionName?.trim().isEmpty ?? true
                  ? null
                  : institutionName!.trim(),
              bankId: isBankCategory ? bankId : null,
              bankSlug: isBankCategory ? bankSlug : null,
              bankName: isBankCategory ? bankName : null,
              bankLogoUrl: isBankCategory ? bankLogoUrl : null,
              monthlyAdminFee: isBankCategory && adminFeeEnabled ? monthlyAdminFee : 0,
              adminFeeDay: isBankCategory && adminFeeEnabled ? adminFeeDay : null,
              adminFeeEnabled: isBankCategory ? adminFeeEnabled : false,
            ),
          );
      await _refresh();
      return true;
    } on ApiException {
      rethrow;
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
    } on ApiException {
      rethrow;
    } catch (_) {
      return false;
    }
  }
}

final accountsControllerProvider = Provider<AccountsController>((ref) {
  return AccountsController(ref);
});

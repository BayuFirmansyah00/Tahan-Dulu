import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/app_providers.dart';

/// Controller fitur Investasi: daftar, tambah, ubah, hapus via
/// InvestmentRepository (Laravel API /api/investments).
class InvestmentController {
  InvestmentController(this._ref);

  final Ref _ref;

  Future<void> _refresh() async {
    _ref.invalidate(investmentsProvider);
  }

  Future<List<FinancialAccount>> loadInvestments() async {
    return _ref.read(investmentRepositoryProvider).getInvestments();
  }

  Future<bool> addInvestment({
    required String title,
    required String type,
    required double achieved,
    int? target,
  }) async {
    try {
      await _ref.read(investmentRepositoryProvider).addInvestment(
            FinancialAccount(
              id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
              name: title.trim(),
              type: AccountType.bank,
              balance: achieved,
              institutionName: type.trim().isEmpty ? null : type.trim(),
            ),
          );
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateInvestment({
    required String id,
    required String title,
    required String type,
    required double achieved,
    int? target,
  }) async {
    try {
      await _ref.read(investmentRepositoryProvider).updateInvestment(
            FinancialAccount(
              id: id,
              name: title.trim(),
              type: AccountType.bank,
              balance: achieved,
              institutionName: type.trim().isEmpty ? null : type.trim(),
            ),
          );
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeInvestment(String id) async {
    try {
      await _ref.read(investmentRepositoryProvider).removeInvestment(id);
      await _refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  String formatBalance(double value) =>
      CurrencyFormatter.formatCompact(value);
}

final investmentControllerProvider =
    Provider<InvestmentController>((ref) => InvestmentController(ref));

/// Provider daftar investasi (FutureProvider).
final investmentsProvider = FutureProvider<List<FinancialAccount>>((ref) async {
  return ref.read(investmentRepositoryProvider).getInvestments();
});

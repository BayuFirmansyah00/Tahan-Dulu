import '../models/api_monthly_budget.dart';

abstract class BudgetRepository {
  Future<ApiMonthlyBudget?> getCurrentBudget();

  Future<ApiMonthlyBudget> storeBudget({
    required int monthlyIncome,
    required List<Map<String, dynamic>> allocations,
  });
}

class MockBudgetRepository implements BudgetRepository {
  MockBudgetRepository([this._currentUserIdProvider]);

  final String? Function()? _currentUserIdProvider;
  String get _currentUserId => _currentUserIdProvider?.call() ?? 'default';

  final Map<String, ApiMonthlyBudget?> _userBudgets = {};

  ApiMonthlyBudget? get _currentBudget {
    if (!_userBudgets.containsKey(_currentUserId)) {
      if (_currentUserId == 'user-1' || _currentUserId == 'default') {
        _userBudgets[_currentUserId] = ApiMonthlyBudget(
          id: 1,
          userId: 1,
          periodStart: DateTime.now(),
          periodEnd: DateTime.now().add(const Duration(days: 30)),
          daysRemaining: 15,
          monthlyIncome: 5000000,
          totalAllocationPercentage: 100.0,
          isActive: true,
          safeDailySpending: 60000,
          isDeficit: false,
          allocations: const [
            ApiBudgetAllocation(
              id: 1,
              category: 'kebutuhan_pokok',
              percentage: 50.0,
              amount: 2500000,
              spent: 1600000,
              remaining: 900000,
            ),
            ApiBudgetAllocation(
              id: 2,
              category: 'pengeluaran_bebas',
              percentage: 5.0,
              amount: 250000,
              spent: 0,
              remaining: 250000,
            ),
            ApiBudgetAllocation(
              id: 3,
              category: 'investasi_tabungan',
              percentage: 30.0,
              amount: 1500000,
              spent: 0,
              remaining: 1500000,
            ),
            ApiBudgetAllocation(
              id: 4,
              category: 'dana_darurat',
              percentage: 15.0,
              amount: 750000,
              spent: 0,
              remaining: 750000,
            ),
          ],
        );
      } else {
        _userBudgets[_currentUserId] = null;
      }
    }
    return _userBudgets[_currentUserId];
  }

  set _currentBudget(ApiMonthlyBudget? val) {
    _userBudgets[_currentUserId] = val;
  }

  @override
  Future<ApiMonthlyBudget?> getCurrentBudget() async {
    return _currentBudget;
  }

  @override
  Future<ApiMonthlyBudget> storeBudget({
    required int monthlyIncome,
    required List<Map<String, dynamic>> allocations,
  }) async {
    final list = allocations.map((a) {
      final pct = (a['percentage'] as num).toDouble();
      final amt = (monthlyIncome * pct / 100).round();
      return ApiBudgetAllocation(
        id: allocations.indexOf(a) + 1,
        category: a['category'] as String,
        percentage: pct,
        amount: amt,
        spent: 0,
        remaining: amt,
      );
    }).toList();

    _currentBudget = ApiMonthlyBudget(
      id: 1,
      userId: 1,
      periodStart: DateTime.now(),
      periodEnd: DateTime.now().add(const Duration(days: 30)),
      daysRemaining: 30,
      monthlyIncome: monthlyIncome,
      totalAllocationPercentage: list.fold(0.0, (s, e) => s + e.percentage),
      isActive: true,
      safeDailySpending: (monthlyIncome * 0.5 / 30).round(),
      isDeficit: false,
      allocations: list,
    );

    return _currentBudget!;
  }
}

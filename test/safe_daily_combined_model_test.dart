import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/currency_formatter.dart';
import 'package:tahan_dulu/data/models/api_monthly_budget.dart';
import 'package:tahan_dulu/data/models/dashboard_data.dart';
import 'package:tahan_dulu/data/models/user_model.dart';

void main() {
  group('Safe Daily Combined Model (Uang Aman Hari Ini Gabungan)', () {
    test('1. ApiMonthlyBudget fromJson parses combined model correctly', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'period_start': '2026-10-25',
        'period_end': '2026-11-24',
        'days_remaining': 19,
        'monthly_income': 6000000,
        'total_allocation_percentage': 100.0,
        'is_active': true,
        'today_allowance': 111111,
        'today_spent': 21000,
        'today_remaining': 90111,
        'safe_daily_spending': 110005,
        'is_today_overspent': false,
        'is_deficit': false,
        'allocations': [
          {
            'id': 1,
            'category': 'kebutuhan_pokok',
            'percentage': 50.0,
            'amount': 3000000,
            'spent': 909891,
            'remaining': 2090109,
          },
        ],
      };

      final budget = ApiMonthlyBudget.fromJson(json);

      expect(budget.id, 1);
      expect(budget.daysRemaining, 19);
      expect(budget.todayAllowance, 111111);
      expect(budget.todaySpent, 21000);
      expect(budget.todayRemaining, 90111);
      expect(budget.safeDailySpending, 110005);
      expect(budget.isTodayOverspent, isFalse);
      expect(budget.effectiveTodayRemaining, 90111);
    });

    test('2. Skenario E.2: Pengeluaran Rp21.000 dari jatah Rp111.111 menghasilkan Rp90.111 & rata-rata Rp110.005', () {
      const initialAllowance = 111111.0;
      const expenseToday = 21000.0;
      const sisaPokokAwalHari = 2111109.0;
      const daysRemaining = 19;

      // Jatah awal hari ini
      final calculatedInitial = (sisaPokokAwalHari / daysRemaining).floorToDouble();
      expect(calculatedInitial, initialAllowance);

      // Sisa jatah hari ini (nilai utama)
      final todayRemaining = calculatedInitial - expenseToday;
      expect(todayRemaining, 90111.0);

      // Batas rata-rata harian terbaru (informasi pendukung)
      final sisaPokokBaru = sisaPokokAwalHari - expenseToday;
      final safeDailyAverage = (sisaPokokBaru / daysRemaining).floorToDouble();
      expect(safeDailyAverage, 110005.0);

      final data = DashboardData(
        user: const UserModel(id: '1', name: 'User Test'),
        monthlyIncome: 6000000,
        expensesTotal: 888891,
        goalContribution: 0,
        remainingFlexible: sisaPokokBaru,
        safeDaily: todayRemaining,
        safeDailyAverage: safeDailyAverage,
        todayRemaining: todayRemaining,
        todayAllowance: initialAllowance,
        todaySpent: expenseToday,
        isTodayOverspent: false,
        totalBalance: 5000000,
        actualMonthExpense: 909891,
        actualMonthIncome: 6000000,
        goals: const [],
        pendingCount: 0,
        hasUnread: false,
      );

      expect(data.safeDaily, 90111.0);
      expect(data.safeDailyAverage, 110005.0);
      expect(data.isTodayOverspent, isFalse);
    });

    test('3. Skenario E.6: Pengeluaran melebihi jatah harian menghasilkan nilai negatif & isTodayOverspent', () {
      final jsonOverspent = {
        'id': 1,
        'user_id': 10,
        'period_start': '2026-10-25',
        'period_end': '2026-11-24',
        'days_remaining': 19,
        'monthly_income': 6000000,
        'total_allocation_percentage': 100.0,
        'is_active': true,
        'today_allowance': 111111,
        'today_spent': 150000,
        'today_remaining': -38889,
        'safe_daily_spending': 103216,
        'is_today_overspent': true,
        'is_deficit': false,
        'allocations': [],
      };

      final budget = ApiMonthlyBudget.fromJson(jsonOverspent);

      expect(budget.todayRemaining, -38889);
      expect(budget.isTodayOverspent, isTrue);
      expect(budget.effectiveTodayRemaining, -38889);
    });

    test('4. CurrencyFormatter formats positive and negative amounts cleanly', () {
      expect(CurrencyFormatter.formatCompact(111111), 'Rp111.111');
      expect(CurrencyFormatter.formatCompact(90111), 'Rp90.111');
      expect(CurrencyFormatter.formatCompact(110005), 'Rp110.005');
      // Format negatif untuk status overspent
      expect(CurrencyFormatter.formatCompact(-38889), '-Rp38.889');
      expect(CurrencyFormatter.format(-38889), '-Rp 38.889');
    });

    test('5. Backward compatibility: Fallback aman jika backend versi lama tanpa today_remaining', () {
      final oldJson = {
        'id': 1,
        'user_id': 10,
        'period_start': '2026-10-25',
        'period_end': '2026-11-24',
        'days_remaining': 19,
        'monthly_income': 6000000,
        'total_allocation_percentage': 100.0,
        'is_active': true,
        'safe_daily_spending': 100000,
        'is_deficit': false,
        'allocations': [],
      };

      final budget = ApiMonthlyBudget.fromJson(oldJson);

      expect(budget.safeDailySpending, 100000);
      expect(budget.effectiveTodayRemaining, 100000);
      expect(budget.effectiveTodayAllowance, 100000);
      expect(budget.effectiveTodaySpent, 0);
      expect(budget.isTodayOverspent, isFalse);
    });
  });
}


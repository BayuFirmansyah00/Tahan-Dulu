import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/finance_math.dart';
import 'package:tahan_dulu/data/models/financial_plan.dart';

void main() {
  group('Fase 1 - FinancialPlan & Batas Belanja Harian', () {
    test('canonical data produces exact Rp305.555 per day for 9 days remaining', () {
      final plan = FinancialPlan.fromOnboarding(
        monthlyIncome: 5000000,
        salaryDay: 25,
        kebutuhanPokokPercent: 50.0,
        pengeluaranBebasPercent: 5.0,
        investasiTabunganPercent: 30.0,
        danaDaruratPercent: 15.0,
        recurringExpensesTotal: 1200000,
        goalName: 'Dana Pensiun',
        goalMonthlyContribution: 500000,
        referenceDate: DateTime(2026, 11, 16),
      );

      // Income & Allocations
      expect(plan.monthlyIncome, 5000000);
      expect(plan.kebutuhanPokok, 2500000);
      expect(plan.pengeluaranBebas, 250000);
      expect(plan.investasiTabungan, 1500000);
      expect(plan.danaDarurat, 750000);
      expect(plan.unallocated, 0);

      // Period & Daily Limit
      expect(plan.daysRemaining, 9);
      expect(plan.dailySpendingLimit, 305555);
      expect(plan.safePerDay, 305555.0);

      // Commitments & Goal
      expect(plan.recurringExpensesTotal, 1200000);
      expect(plan.goalName, 'Dana Pensiun');
      expect(plan.goalMonthlyContribution, 500000);
    });

    test('budget allocation under 100% shows unallocated remainder', () {
      final plan = FinancialPlan.fromOnboarding(
        monthlyIncome: 10000000,
        salaryDay: 25,
        kebutuhanPokokPercent: 40.0,
        pengeluaranBebasPercent: 10.0,
        investasiTabunganPercent: 20.0,
        danaDaruratPercent: 10.0,
        referenceDate: DateTime(2026, 11, 16),
      );

      expect(plan.kebutuhanPokok, 4000000);
      expect(plan.pengeluaranBebas, 1000000);
      expect(plan.investasiTabungan, 2000000);
      expect(plan.danaDarurat, 1000000);

      // 40 + 10 + 20 + 10 = 80%, unallocated = 20%
      expect(plan.unallocatedPercent, 20.0);
      expect(plan.unallocated, 2000000);

      // Spendable: 4.000.000 + 1.000.000 = 5.000.000 / 9 days
      expect(plan.daysRemaining, 9);
      expect(plan.dailySpendingLimit, 555555);
    });

    test('dailySpendingRemaining reflects negative deficit when overspent', () {
      final baseline = dailySpendingBaseline(
        spendableAllocation: 2750000,
        spentBeforeToday: 0,
        daysRemaining: 9,
      );
      expect(baseline, 305555);

      final remainingNormal = dailySpendingRemaining(
        baselineToday: baseline.toDouble(),
        spentToday: 100000,
      );
      expect(remainingNormal, 205555.0);

      final remainingDeficit = dailySpendingRemaining(
        baselineToday: baseline.toDouble(),
        spentToday: 350000,
      );
      expect(remainingDeficit, -44445.0);
    });

    test('budgetPeriodDaysRemaining handles post-payday reference dates', () {
      // If reference date is Nov 26 and payday is 25:
      // Period is Nov 25 to Dec 24 inclusive.
      // Days remaining from Nov 26 to Dec 24 = 29 days.
      final days = budgetPeriodDaysRemaining(25, now: DateTime(2026, 11, 26));
      expect(days, 29);
    });
  });
}

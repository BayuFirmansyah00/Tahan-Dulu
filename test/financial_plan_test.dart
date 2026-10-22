import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_plan.dart';

void main() {
  test('canonical data produces design numbers', () {
    final plan = FinancialPlan.fromOnboarding(
      monthlyIncome: 5000000,
      needsTotal: 2500000,
      goalName: 'Investasi',
    );

    expect(plan.needs, 2500000);
    expect(plan.saving, 800000);
    expect(plan.investment, 500000);
    expect(plan.flexible, 1200000);
    expect(plan.safePerDay, 40000);
    expect(plan.goalName, 'Investasi');
  });

  test('custom inputs stay consistent', () {
    final plan = FinancialPlan.fromOnboarding(
      monthlyIncome: 10000000,
      needsTotal: 3000000,
      goalName: 'Dana Darurat',
    );

    expect(plan.needs, 3000000);
    expect(plan.flexible, 5700000);
    expect(plan.safePerDay, 190000);
  });

  test('negative remainder clamps to zero', () {
    final plan = FinancialPlan.fromOnboarding(
      monthlyIncome: 1000000,
      needsTotal: 900000,
    );

    expect(plan.flexible, 0);
    expect(plan.safePerDay, 0);
  });
}

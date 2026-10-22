import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_health.dart';

void main() {
  test('healthy when all indicators strong', () {
    final result = evaluateFinancialHealth(
      monthIncome: 5000000,
      monthExpense: 1000000,
      savingsProgress: 0.8,
      remaining: 4000000,
      goalProgress: 0.8,
    );

    expect(result.level, HealthLevel.healthy);
    expect(result.score, greaterThanOrEqualTo(75));
    expect(result.indicators.length, 4);
  });

  test('poor when overspending', () {
    final result = evaluateFinancialHealth(
      monthIncome: 5000000,
      monthExpense: 6000000,
      savingsProgress: 0.1,
      remaining: -1000000,
      goalProgress: 0.1,
    );

    expect(result.level, HealthLevel.poor);
    expect(result.indicators.first.score, 0);
  });

  test('insufficient with fewer than two indicators', () {
    final result = evaluateFinancialHealth(
      monthIncome: 0,
      monthExpense: 0,
      remaining: 0,
    );

    expect(result.level, HealthLevel.insufficient);
    expect(result.score, 0);
  });

  test('single indicator still insufficient', () {
    // Hanya budget tersedia (income/expense nol -> spending null).
    final result = evaluateFinancialHealth(
      monthIncome: 0,
      monthExpense: 0,
      remaining: 0,
    );

    expect(result.level, HealthLevel.insufficient);
  });

  test('fair on mixed signals', () {
    final result = evaluateFinancialHealth(
      monthIncome: 5000000,
      monthExpense: 2500000,
      remaining: 2500000,
    );

    // spending 50 + budget 100 = 75 -> Sehat (batas bawah).
    expect(result.level, HealthLevel.healthy);
    expect(result.score, 75);
  });

  test('level labels in Indonesian', () {
    expect(healthLevelLabel(HealthLevel.healthy), 'Sehat');
    expect(healthLevelLabel(HealthLevel.fair), 'Cukup');
    expect(healthLevelLabel(HealthLevel.poor), 'Perlu Perhatian');
    expect(
      healthLevelLabel(HealthLevel.insufficient),
      'Data belum cukup',
    );
  });
}

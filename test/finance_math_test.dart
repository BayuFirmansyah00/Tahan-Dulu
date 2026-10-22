import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/finance_math.dart';

void main() {
  test('monthsUntil counts calendar months, minimum 1', () {
    final now = DateTime(2026, 10, 8);
    expect(monthsUntil(DateTime(2027, 6, 30), now: now), 8);
    expect(monthsUntil(DateTime(2026, 10, 8), now: now), 1);
    expect(monthsUntil(DateTime(2020, 1, 1), now: now), 1);
  });

  test('daysInMonth follows calendar', () {
    expect(daysInMonth(DateTime(2026, 10, 8)), 31);
    expect(daysInMonth(DateTime(2026, 2, 1)), 28);
    expect(daysInMonth(DateTime(2024, 2, 1)), 29);
  });

  test('totalBalanceOf sums initial balances', () {
    expect(totalBalanceOf([5000000, 1000000, 500000]), 6500000);
    expect(totalBalanceOf(const []), 0);
  });

  test('totalExpensesOf sums monthly amounts', () {
    expect(totalExpensesOf([1500000, 400000, 300000, 300000]), 2500000);
  });

  test('remainingFlexible subtracts expenses and contribution', () {
    expect(
      remainingFlexible(
        income: 5000000,
        expenses: 2500000,
        goalContribution: 1250000,
      ),
      1250000,
    );
  });

  test('accountBalanceOf applies only its own transactions', () {
    expect(
      accountBalanceOf(initial: 5000000, income: 200000, expense: 50000),
      5150000,
    );
    expect(
      accountBalanceOf(initial: 300000, income: 0, expense: 0),
      300000,
    );
    expect(
      accountBalanceOf(initial: 0, income: 0, expense: 100000),
      -100000,
    );
  });

  test('safeDailySpending across month boundaries', () {
    // Akhir Oktober (31 hari): 1.250.000 / 31 = 40.322 -> 40.000.
    expect(
      safeDailySpending(
        remaining: 1250000,
        now: DateTime(2026, 10, 31),
      ),
      40000,
    );
    // Awal November (30 hari): 900.000 / 30 = 30.000 pas.
    expect(
      safeDailySpending(
        remaining: 900000,
        now: DateTime(2026, 11, 1),
      ),
      30000,
    );
    // Februari kabisat (29 hari): 290.000 / 29 = 10.000 pas.
    expect(
      safeDailySpending(
        remaining: 290000,
        now: DateTime(2024, 2, 10),
      ),
      10000,
    );
    // Sisa nol/negatif -> nol, tidak pernah negatif.
    expect(safeDailySpending(remaining: 0, now: DateTime(2026, 10, 8)), 0);
    expect(
      safeDailySpending(remaining: -1000, now: DateTime(2026, 10, 8)),
      0,
    );
  });
}

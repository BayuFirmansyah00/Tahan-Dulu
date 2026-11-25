import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/scheduled_cashflow_calculator.dart';
import 'package:tahan_dulu/data/models/api_recurring_transaction.dart';

void main() {
  group('ScheduledCashflowCalculator', () {
    final periodStart = DateTime(2026, 11, 23);
    final periodEnd = DateTime(2026, 12, 22); // 30 days total

    test('daily schedule counts occurrences for every day in period', () {
      const dailyItem = ApiRecurringTransaction(
        id: '1',
        title: 'Makan Siang Harian',
        type: 'expense',
        category: 'needs',
        amount: 25000,
        frequency: 'daily',
        isActive: true,
        makeAutomatic: false,
      );

      final count = ScheduledCashflowCalculator.calculateOccurrences(
        item: dailyItem,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // 23 Nov to 22 Dec inclusive is 30 days
      expect(count, equals(30));

      final result = ScheduledCashflowCalculator.calculateCashflow(
        items: [dailyItem],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(result.activeCount, equals(1));
      expect(result.totalOccurrences, equals(30));
      expect(result.totalAmount, equals(25000 * 30));
    });

    test('weekly schedule counts weekly occurrences correctly', () {
      // 2026-11-25 is a Wednesday
      const weeklyItem = ApiRecurringTransaction(
        id: '2',
        title: 'Les Bahasa',
        type: 'expense',
        category: 'education',
        amount: 150000,
        frequency: 'weekly',
        nextDueDate: '2026-11-25',
        isActive: true,
        makeAutomatic: false,
      );

      final count = ScheduledCashflowCalculator.calculateOccurrences(
        item: weeklyItem,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // Wednesdays in 23 Nov - 22 Dec 2026:
      // Nov 25, Dec 2, Dec 9, Dec 16 (4 Wednesdays)
      expect(count, equals(4));

      final result = ScheduledCashflowCalculator.calculateCashflow(
        items: [weeklyItem],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(result.totalAmount, equals(150000 * 4));
    });

    test('monthly schedule clamps to short month and counts once per cycle', () {
      // Scheduled on day 31
      const monthlyItem = ApiRecurringTransaction(
        id: '3',
        title: 'Tabungan Akhir Bulan',
        type: 'expense',
        category: 'savings',
        amount: 500000,
        frequency: 'monthly',
        nextDueDate: '2026-10-31',
        isActive: true,
        makeAutomatic: false,
      );

      // In Nov 23 - Dec 22 period:
      // November has 30 days (clamped to Nov 30, which is in range [Nov 23, Dec 22]) -> 1 occurrence
      final count = ScheduledCashflowCalculator.calculateOccurrences(
        item: monthlyItem,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(count, equals(1));
    });

    test('yearly schedule counts 1 if date falls inside period, 0 if outside', () {
      const yearlyInside = ApiRecurringTransaction(
        id: '4',
        title: 'Pajak Kendaraan',
        type: 'expense',
        category: 'transport',
        amount: 1200000,
        frequency: 'yearly',
        nextDueDate: '2026-12-05',
        isActive: true,
        makeAutomatic: false,
      );

      const yearlyOutside = ApiRecurringTransaction(
        id: '5',
        title: 'Asuransi Tahunan',
        type: 'expense',
        category: 'bills',
        amount: 3000000,
        frequency: 'yearly',
        nextDueDate: '2026-04-15',
        isActive: true,
        makeAutomatic: false,
      );

      final countInside = ScheduledCashflowCalculator.calculateOccurrences(
        item: yearlyInside,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(countInside, equals(1));

      final countOutside = ScheduledCashflowCalculator.calculateOccurrences(
        item: yearlyOutside,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(countOutside, equals(0));
    });

    test('inactive schedule returns 0 occurrences', () {
      const inactiveItem = ApiRecurringTransaction(
        id: '6',
        title: 'Langganan Gym (Dijeda)',
        type: 'expense',
        category: 'others',
        amount: 350000,
        frequency: 'monthly',
        nextDueDate: '2026-11-28',
        isActive: false, // Inactive
        makeAutomatic: false,
      );

      final count = ScheduledCashflowCalculator.calculateOccurrences(
        item: inactiveItem,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(count, equals(0));

      final result = ScheduledCashflowCalculator.calculateCashflow(
        items: [inactiveItem],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      expect(result.activeCount, equals(0));
      expect(result.totalAmount, equals(0));
    });

    test('calculateSummary properly calculates net cashflow', () {
      const incomeMonthly = ApiRecurringTransaction(
        id: '10',
        title: 'Gaji Kantor',
        type: 'income',
        category: 'salary',
        amount: 8000000,
        frequency: 'monthly',
        nextDueDate: '2026-11-25',
        isActive: true,
        makeAutomatic: false,
      );

      const expenseDaily = ApiRecurringTransaction(
        id: '20',
        title: 'Uang Makan',
        type: 'expense',
        category: 'needs',
        amount: 50000,
        frequency: 'daily',
        isActive: true,
        makeAutomatic: false,
      );

      final summary = ScheduledCashflowCalculator.calculateSummary(
        incomes: [incomeMonthly],
        expenses: [expenseDaily],
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(summary.income.totalAmount, equals(8000000));
      expect(summary.expense.totalAmount, equals(50000 * 30)); // 1,500,000
      expect(summary.netCashflow, equals(8000000 - 1500000)); // +6,500,000
    });
  });
}

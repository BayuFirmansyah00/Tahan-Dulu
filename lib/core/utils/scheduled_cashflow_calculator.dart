import 'dart:math';
import '../../data/models/api_recurring_transaction.dart';

/// Hasil kalkulasi per-item transaksi rutin dalam periode anggaran.
class ScheduledItemOccurrence {
  const ScheduledItemOccurrence({
    required this.item,
    required this.occurrences,
    required this.totalAmount,
  });

  final ApiRecurringTransaction item;
  final int occurrences;
  final int totalAmount;
}

/// Hasil kalkulasi agregat arus kas terjadwal.
class ScheduledCashflowResult {
  const ScheduledCashflowResult({
    required this.totalAmount,
    required this.activeCount,
    required this.totalOccurrences,
    required this.itemOccurrences,
  });

  final int totalAmount;
  final int activeCount;
  final int totalOccurrences;
  final List<ScheduledItemOccurrence> itemOccurrences;

  static const empty = ScheduledCashflowResult(
    totalAmount: 0,
    activeCount: 0,
    totalOccurrences: 0,
    itemOccurrences: [],
  );
}

/// Ringkasan arus kas terjadwal masuk dan keluar.
class ScheduledCashflowSummary {
  const ScheduledCashflowSummary({
    required this.income,
    required this.expense,
  });

  final ScheduledCashflowResult income;
  final ScheduledCashflowResult expense;

  int get netCashflow => income.totalAmount - expense.totalAmount;

  static const empty = ScheduledCashflowSummary(
    income: ScheduledCashflowResult.empty,
    expense: ScheduledCashflowResult.empty,
  );
}

/// Kalkulator arus kas terjadwal dengan penyesuaian frekuensi (Harian, Mingguan, Bulanan, Tahunan)
/// dan perataan tanggal bulan pendek (short-month date clamping).
class ScheduledCashflowCalculator {
  /// Menghitung jumlah hari dalam bulan tertentu dengan mempertimbangkan tahun kabisat.
  static int getDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const daysPerMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysPerMonth[month];
  }

  /// Menghitung kemunculan (occurrences) sebuah jadwal transaksi dalam rentang periode budget.
  static int calculateOccurrences({
    required ApiRecurringTransaction item,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (!item.isActive) {
      return 0;
    }

    final start = DateTime(periodStart.year, periodStart.month, periodStart.day);
    final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day, 23, 59, 59);

    if (end.isBefore(start)) {
      return 0;
    }

    final freq = item.frequency.toLowerCase().trim();
    final dueDate = item.parsedNextDueDate ??
        (item.createdAt != null ? DateTime.tryParse(item.createdAt!) : null) ??
        start;

    switch (freq) {
      case 'daily':
        // Harian: muncul setiap hari di dalam rentang periode anggaran
        final diffDays = end.difference(start).inDays + 1;
        return max(0, diffDays);

      case 'weekly':
        // Mingguan: hitung jumlah tanggal dengan hari dalam minggu yang sama dalam rentang
        int count = 0;
        final targetWeekday = dueDate.weekday;
        var cursor = start;
        while (!cursor.isAfter(end)) {
          if (cursor.weekday == targetWeekday) {
            count++;
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        return count;

      case 'monthly':
        // Bulanan: jatuh pada hari tertentu dengan date clamping untuk bulan pendek
        int count = 0;
        final targetDay = dueDate.day;

        // Loop melalui setiap bulan dari start sampai end
        int currentYear = start.year;
        int currentMonth = start.month;

        while (true) {
          final maxDayInMonth = getDaysInMonth(currentYear, currentMonth);
          final clampedDay = min(targetDay, maxDayInMonth);
          final occurrenceDate = DateTime(currentYear, currentMonth, clampedDay);

          if (!occurrenceDate.isBefore(start) && !occurrenceDate.isAfter(end)) {
            count++;
          }

          if (currentYear == end.year && currentMonth == end.month) {
            break;
          }

          currentMonth++;
          if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
          }
        }
        return count;

      case 'yearly':
        // Tahunan: jatuh pada bulan dan hari tertentu setiap tahun
        int count = 0;
        final targetMonth = dueDate.month;
        final targetDay = dueDate.day;

        for (int y = start.year; y <= end.year; y++) {
          final maxDayInMonth = getDaysInMonth(y, targetMonth);
          final clampedDay = min(targetDay, maxDayInMonth);
          final occurrenceDate = DateTime(y, targetMonth, clampedDay);

          if (!occurrenceDate.isBefore(start) && !occurrenceDate.isAfter(end)) {
            count++;
          }
        }
        return count;

      default:
        // Default ke bulanan jika tidak dikenal
        return 1;
    }
  }

  /// Menghitung total arus kas terjadwal untuk daftar transaksi rutin.
  static ScheduledCashflowResult calculateCashflow({
    required List<ApiRecurringTransaction> items,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final now = DateTime.now();
    final start = periodStart ?? DateTime(now.year, now.month, 1);
    final end = periodEnd ?? DateTime(now.year, now.month, getDaysInMonth(now.year, now.month));

    final activeItems = items.where((i) => i.isActive).toList();
    int totalAmount = 0;
    int totalOccurrences = 0;
    final itemOccurrences = <ScheduledItemOccurrence>[];

    for (final item in activeItems) {
      final occurrences = calculateOccurrences(
        item: item,
        periodStart: start,
        periodEnd: end,
      );

      final itemTotal = item.amount * occurrences;
      totalAmount += itemTotal;
      totalOccurrences += occurrences;

      itemOccurrences.add(
        ScheduledItemOccurrence(
          item: item,
          occurrences: occurrences,
          totalAmount: itemTotal,
        ),
      );
    }

    return ScheduledCashflowResult(
      totalAmount: totalAmount,
      activeCount: activeItems.length,
      totalOccurrences: totalOccurrences,
      itemOccurrences: List.unmodifiable(itemOccurrences),
    );
  }

  /// Menghitung ringkasan lengkap arus kas terjadwal pemasukan dan pengeluaran.
  static ScheduledCashflowSummary calculateSummary({
    required List<ApiRecurringTransaction> incomes,
    required List<ApiRecurringTransaction> expenses,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final incomeResult = calculateCashflow(
      items: incomes,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    final expenseResult = calculateCashflow(
      items: expenses,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    return ScheduledCashflowSummary(
      income: incomeResult,
      expense: expenseResult,
    );
  }
}

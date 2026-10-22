import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/goal_math.dart';
import 'package:tahan_dulu/data/models/financial_goal.dart';

void main() {
  group('goalRemaining', () {
    test('sisa normal', () {
      expect(
        goalRemaining(target: 10000000, collected: 3500000),
        6500000,
      );
    });

    test('tanpa dana terkumpul', () {
      expect(
        goalRemaining(target: 10000000, collected: 0),
        10000000,
      );
    });

    test('kelebihan setoran tidak negatif', () {
      expect(
        goalRemaining(target: 10000000, collected: 12000000),
        0,
      );
    });
  });

  group('ceilToStep', () {
    test('tepat kelipatan tetap', () {
      expect(ceilToStep(250000), 250000);
    });

    test('pecahan dibulatkan ke atas', () {
      expect(ceilToStep(166666.67), 167000);
      expect(ceilToStep(1428571.4), 1429000);
    });

    test('nol dan negatif menjadi nol', () {
      expect(ceilToStep(0), 0);
      expect(ceilToStep(-500), 0);
    });
  });

  group('periodsUntil', () {
    final now = DateTime(2026, 1, 15);

    test('bulanan memakai bulan kalender', () {
      expect(
        periodsUntil(
          deadline: DateTime(2026, 7, 20),
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        7,
      );
    });

    test('bulanan minimal satu periode', () {
      expect(
        periodsUntil(
          deadline: DateTime(2026, 1, 25),
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        1,
      );
    });

    test('mingguan memakai minggu kalender nyata', () {
      // 10 hari -> 2 periode mingguan (bukan 10/30 bulan x4).
      expect(
        periodsUntil(
          deadline: DateTime(2026, 1, 25),
          frequency: DepositFrequency.weekly,
          now: now,
        ),
        2,
      );
      expect(
        periodsUntil(
          deadline: DateTime(2026, 1, 22),
          frequency: DepositFrequency.weekly,
          now: now,
        ),
        1,
      );
    });

    test('tenggat lewat atau null menjadi null', () {
      expect(
        periodsUntil(
          deadline: DateTime(2026, 1, 10),
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
      expect(
        periodsUntil(
          deadline: DateTime(2026, 1, 10),
          frequency: DepositFrequency.weekly,
          now: now,
        ),
        isNull,
      );
      expect(
        periodsUntil(
          deadline: null,
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('recommendedPerPeriod', () {
    final now = DateTime(2026, 1, 15);

    test('bulanan dibulatkan ke atas dan pasti mencapai target', () {
      final rec = recommendedPerPeriod(
        target: 10000000,
        collected: 0,
        deadline: DateTime(2026, 7, 15),
        frequency: DepositFrequency.monthly,
        now: now,
      );
      expect(rec, 1429000);
      // 7 periode x rekomendasi menutup target.
      expect(rec! * 7, greaterThanOrEqualTo(10000000));
    });

    test('memperhitungkan dana yang sudah terkumpul', () {
      final rec = recommendedPerPeriod(
        target: 10000000,
        collected: 3500000,
        deadline: DateTime(2026, 7, 15),
        frequency: DepositFrequency.monthly,
        now: now,
      );
      // Sisa 6,5jt / 7 periode -> 928571,43 -> 929000.
      expect(rec, 929000);
    });

    test('mingguan memakai minggu nyata', () {
      final rec = recommendedPerPeriod(
        target: 1000000,
        collected: 0,
        deadline: DateTime(2026, 1, 29),
        frequency: DepositFrequency.weekly,
        now: DateTime(2026, 1, 1),
      );
      expect(rec, 250000);
    });

    test('target tercapai menjadi nol', () {
      expect(
        recommendedPerPeriod(
          target: 1000000,
          collected: 1000000,
          deadline: DateTime(2026, 7, 15),
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        0,
      );
    });

    test('tenggat lewat atau null menjadi null', () {
      expect(
        recommendedPerPeriod(
          target: 1000000,
          collected: 0,
          deadline: DateTime(2025, 12, 31),
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
      expect(
        recommendedPerPeriod(
          target: 1000000,
          collected: 0,
          deadline: null,
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('estimateReachDate', () {
    final now = DateTime(2026, 1, 10);

    test('bulanan menambah bulan kalender', () {
      expect(
        estimateReachDate(
          target: 1000000,
          collected: 0,
          perDeposit: 250000,
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        DateTime(2026, 5, 10),
      );
    });

    test('mingguan menambah kelipatan 7 hari', () {
      expect(
        estimateReachDate(
          target: 500000,
          collected: 0,
          perDeposit: 250000,
          frequency: DepositFrequency.weekly,
          now: now,
        ),
        DateTime(2026, 1, 24),
      );
    });

    test('nominal lebih besar mencapai lebih cepat', () {
      final slow = estimateReachDate(
        target: 1000000,
        collected: 0,
        perDeposit: 250000,
        frequency: DepositFrequency.monthly,
        now: now,
      )!;
      final fast = estimateReachDate(
        target: 1000000,
        collected: 0,
        perDeposit: 500000,
        frequency: DepositFrequency.monthly,
        now: now,
      )!;
      expect(fast.isBefore(slow), isTrue);
    });

    test('sudah tercapai atau nominal nol menjadi null', () {
      expect(
        estimateReachDate(
          target: 1000000,
          collected: 1000000,
          perDeposit: 250000,
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
      expect(
        estimateReachDate(
          target: 1000000,
          collected: 0,
          perDeposit: 0,
          frequency: DepositFrequency.monthly,
          now: now,
        ),
        isNull,
      );
    });
  });
}

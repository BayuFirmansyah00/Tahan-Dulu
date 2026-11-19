import '../models/financial_settings.dart';

abstract class FinancialSettingsRepository {
  /// Ambil pengaturan keuangan saat ini, budget aktif, dan status pending.
  Future<FinancialSettings> getSettings();

  /// Hitung preview masa transisi sebelum simpan.
  Future<FinancialTransitionInfo> getPreview({
    required int monthlyIncome,
    required int salaryDay,
  });

  /// Simpan pengaturan keuangan baru (akan mulai berlaku periode berikutnya).
  Future<FinancialSettings> updateSettings({
    required int monthlyIncome,
    required int salaryDay,
    List<Map<String, dynamic>>? allocations,
    int? transitionBudget,
    bool transitionConfirmed = false,
  });

  /// Batalkan perubahan yang masih berstatus pending sebelum tanggal berlaku.
  Future<FinancialSettings> cancelPending();
}

/// Implementasi mock untuk pengujian offline.
class MockFinancialSettingsRepository implements FinancialSettingsRepository {
  MockFinancialSettingsRepository({
    int initialIncome = 5000000,
    int initialSalaryDay = 25,
  })  : _income = initialIncome,
        _salaryDay = initialSalaryDay;

  final int _income;
  final int _salaryDay;
  PendingFinancialChange? _pending;

  @override
  Future<FinancialSettings> getSettings() async {
    return FinancialSettings(
      currentMonthlyIncome: _income,
      currentMonthlyIncomeFormatted: 'Rp $_income',
      currentSalaryDay: _salaryDay,
      pendingChange: _pending,
      activePeriod: ActivePeriodInfo(
        id: 1,
        periodStart: '2026-10-25',
        periodEnd: '2026-11-24',
        daysRemaining: 8,
        monthlyIncome: _income,
        monthlyIncomeFormatted: 'Rp $_income',
        isActive: true,
        spendableAllocation: (_income * 0.8).toInt(),
        safeDailySpending: ((_income * 0.8) / 8).toInt(),
      ),
    );
  }

  @override
  Future<FinancialTransitionInfo> getPreview({
    required int monthlyIncome,
    required int salaryDay,
  }) async {
    final hasTransition = salaryDay != _salaryDay;
    return FinancialTransitionInfo(
      currentMonthlyIncome: _income,
      currentSalaryDay: _salaryDay,
      proposedMonthlyIncome: monthlyIncome,
      proposedSalaryDay: salaryDay,
      effectiveDate: '2026-11-25',
      effectiveDateFormatted: '25 November 2026',
      hasTransition: hasTransition,
      transitionStart: hasTransition ? '2026-11-25' : null,
      transitionEnd: hasTransition ? '2026-11-30' : null,
      transitionDays: hasTransition ? 6 : 0,
      nextFullPeriodStart: hasTransition ? '2026-12-01' : '2026-11-25',
      nextFullPeriodStartFormatted: hasTransition ? '01 Desember 2026' : '25 November 2026',
      nextFullPeriodEnd: hasTransition ? '2026-12-31' : '2026-12-24',
      nextFullPeriodEndFormatted: hasTransition ? '31 Desember 2026' : '24 Desember 2026',
      note: hasTransition
          ? 'Perubahan tanggal gajian menghasilkan penyesuaian selama 6 hari.'
          : 'Perubahan berlaku penuh mulai periode berikutnya.',
    );
  }

  @override
  Future<FinancialSettings> updateSettings({
    required int monthlyIncome,
    required int salaryDay,
    List<Map<String, dynamic>>? allocations,
    int? transitionBudget,
    bool transitionConfirmed = false,
  }) async {
    final preview = await getPreview(
      monthlyIncome: monthlyIncome,
      salaryDay: salaryDay,
    );

    _pending = PendingFinancialChange(
      hasPending: true,
      pendingMonthlyIncome: monthlyIncome,
      pendingMonthlyIncomeFormatted: 'Rp $monthlyIncome',
      pendingSalaryDay: salaryDay,
      effectiveDate: preview.effectiveDate,
      effectiveDateFormatted: preview.effectiveDateFormatted,
      transitionBudget: transitionBudget,
      transitionBudgetFormatted: transitionBudget != null ? 'Rp $transitionBudget' : null,
      transitionConfirmed: transitionConfirmed,
      transitionInfo: preview,
    );

    return getSettings();
  }

  @override
  Future<FinancialSettings> cancelPending() async {
    _pending = null;
    return getSettings();
  }
}


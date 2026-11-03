import '../datasources/mock/mock_data.dart';
import '../models/financial_goal.dart';
import '../models/financial_instrument.dart';
import '../models/onboarding_data.dart';
import '../models/recurring_expense.dart';

// ---------------------------------------------------------------------------
// Repository onboarding (No.3–No.4). In-memory: tanpa SharedPreferences/db.
// Nanti diganti Laravel API tanpa mengubah UI.
// ---------------------------------------------------------------------------

abstract class OnboardingRepository {
  OnboardingData? getSalarySetup();
  Future<OnboardingData> saveSalarySetup({
    required double monthlyIncome,
    required int salaryDay,
  });

  OnboardingData? getOnboardingData();
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  );
  Future<OnboardingData> saveExpenses(List<RecurringExpense> expenses);
  Future<OnboardingData> saveGoal(FinancialGoal goal);

  /// CRUD instrumen (sumber tunggal juga untuk fitur Akun).
  /// Update/delete mempertahankan field yang tidak diubah (fee, dsb).
  Future<FinancialInstrument> addInstrument(FinancialInstrument instrument);
  Future<FinancialInstrument> updateInstrument(FinancialInstrument instrument);
  Future<void> removeInstrument(String id);

  /// Bersihkan data / cache onboarding (digunakan saat logout / ganti akun).
  void clear();
}

/// Penyimpanan sementara di memori, diisi default data demo canonical.
class InMemoryOnboardingRepository implements OnboardingRepository {
  OnboardingData? _data = OnboardingData(
    monthlyIncome: MockData.income,
    salaryDay: MockData.salaryDay,
    financialInstruments: MockData.instruments,
    recurringExpenses: MockData.expenses,
    financialGoal: MockData.defaultGoal,
  );

  @override
  OnboardingData? getSalarySetup() => _data;

  @override
  Future<OnboardingData> saveSalarySetup({
    required double monthlyIncome,
    required int salaryDay,
  }) {
    // Hanya field gaji yang ditulis — instrumen tidak dioverwrite.
    _data = (_data ??
            OnboardingData(
              monthlyIncome: monthlyIncome,
              salaryDay: salaryDay,
              financialInstruments: MockData.instruments,
            ))
        .copyWith(monthlyIncome: monthlyIncome, salaryDay: salaryDay);
    return mockDelay(_data!);
  }

  @override
  OnboardingData? getOnboardingData() => _data;

  @override
  Future<OnboardingData> saveInstruments(
    List<FinancialInstrument> instruments,
  ) {
    // Hanya instrumen yang ditulis — data No.3 tetap tersimpan.
    _data = (_data ??
            OnboardingData(
              monthlyIncome: MockData.income,
              salaryDay: MockData.salaryDay,
            ))
        .copyWith(financialInstruments: instruments);
    return mockDelay(_data!);
  }

  @override
  Future<OnboardingData> saveExpenses(List<RecurringExpense> expenses) {
    // Hanya expenses yang ditulis — data No.3 & No.4 tetap tersimpan.
    _data = (_data ??
            OnboardingData(
              monthlyIncome: MockData.income,
              salaryDay: MockData.salaryDay,
            ))
        .copyWith(recurringExpenses: expenses);
    return mockDelay(_data!);
  }

  @override
  Future<OnboardingData> saveGoal(FinancialGoal goal) {
    // Hanya goal yang ditulis — data No.3, No.4, No.5 tetap tersimpan.
    _data = (_data ??
            OnboardingData(
              monthlyIncome: MockData.income,
              salaryDay: MockData.salaryDay,
            ))
        .copyWith(financialGoal: goal);
    return mockDelay(_data!);
  }

  List<FinancialInstrument> _instruments() =>
      List.of(_data?.financialInstruments ?? const []);

  void _writeInstruments(List<FinancialInstrument> instruments) {
    _data = (_data ??
            OnboardingData(
              monthlyIncome: MockData.income,
              salaryDay: MockData.salaryDay,
            ))
        .copyWith(financialInstruments: instruments);
  }

  @override
  Future<FinancialInstrument> addInstrument(
    FinancialInstrument instrument,
  ) {
    final items = _instruments()..add(instrument);
    _writeInstruments(items);
    return mockDelay(instrument);
  }

  @override
  Future<FinancialInstrument> updateInstrument(
    FinancialInstrument instrument,
  ) {
    final items = [
      for (final e in _instruments())
        if (e.id == instrument.id) instrument else e,
    ];
    _writeInstruments(items);
    return mockDelay(instrument);
  }

  @override
  Future<void> removeInstrument(String id) {
    _writeInstruments(
      [for (final e in _instruments()) if (e.id != id) e],
    );
    return mockDelay(null);
  }

  @override
  void clear() {
    _data = null;
  }
}

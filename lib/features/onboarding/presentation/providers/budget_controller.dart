import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'onboarding_status_provider.dart';
import 'salary_controller.dart';

class BudgetState extends Equatable {
  const BudgetState({
    required this.monthlyIncome,
    this.kebutuhanPokok = 50.0,
    this.pengeluaranBebas = 5.0,
    this.investasiTabungan = 30.0,
    this.danaDarurat = 15.0,
    this.isSaving = false,
    this.errorMessage,
  });

  final int monthlyIncome;
  final double kebutuhanPokok;
  final double pengeluaranBebas;
  final double investasiTabungan;
  final double danaDarurat;
  final bool isSaving;
  final String? errorMessage;

  double get totalPercentage =>
      kebutuhanPokok + pengeluaranBebas + investasiTabungan + danaDarurat;

  double get remainingPercentage {
    final rem = 100.0 - totalPercentage;
    return rem < 0 ? 0.0 : rem;
  }

  bool get isExceeding100 => totalPercentage > 100.001;

  bool get isValid => totalPercentage > 0 && totalPercentage <= 100.001;

  int get amountKebutuhanPokok =>
      (monthlyIncome * kebutuhanPokok / 100).floor();
  int get amountPengeluaranBebas =>
      (monthlyIncome * pengeluaranBebas / 100).floor();
  int get amountInvestasiTabungan =>
      (monthlyIncome * investasiTabungan / 100).floor();
  int get amountDanaDarurat =>
      (monthlyIncome * danaDarurat / 100).floor();

  int get totalAllocatedAmount =>
      amountKebutuhanPokok +
      amountPengeluaranBebas +
      amountInvestasiTabungan +
      amountDanaDarurat;

  int get remainingAmount {
    final rem = monthlyIncome - totalAllocatedAmount;
    return rem < 0 ? 0 : rem;
  }

  BudgetState copyWith({
    int? monthlyIncome,
    double? kebutuhanPokok,
    double? pengeluaranBebas,
    double? investasiTabungan,
    double? danaDarurat,
    bool? isSaving,
    String? Function()? errorMessage,
  }) {
    return BudgetState(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      kebutuhanPokok: kebutuhanPokok ?? this.kebutuhanPokok,
      pengeluaranBebas: pengeluaranBebas ?? this.pengeluaranBebas,
      investasiTabungan: investasiTabungan ?? this.investasiTabungan,
      danaDarurat: danaDarurat ?? this.danaDarurat,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        monthlyIncome,
        kebutuhanPokok,
        pengeluaranBebas,
        investasiTabungan,
        danaDarurat,
        isSaving,
        errorMessage,
      ];
}

class BudgetController extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    final salary = ref.watch(salaryControllerProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final income = salary.monthlyIncome > 0
        ? salary.monthlyIncome.toInt()
        : (authUser?.monthlyIncome ?? 5000000);

    return BudgetState(monthlyIncome: income);
  }

  void updateIncome(int income) {
    if (income >= 0) {
      state = state.copyWith(monthlyIncome: income);
    }
  }

  void updateKebutuhanPokok(double value) {
    state = state.copyWith(kebutuhanPokok: value.clamp(0, 100));
  }

  void updatePengeluaranBebas(double value) {
    state = state.copyWith(pengeluaranBebas: value.clamp(0, 100));
  }

  void updateInvestasiTabungan(double value) {
    state = state.copyWith(investasiTabungan: value.clamp(0, 100));
  }

  void updateDanaDarurat(double value) {
    state = state.copyWith(danaDarurat: value.clamp(0, 100));
  }

  void resetToDefault() {
    state = state.copyWith(
      kebutuhanPokok: 50.0,
      pengeluaranBebas: 5.0,
      investasiTabungan: 30.0,
      danaDarurat: 15.0,
      errorMessage: () => null,
    );
  }

  Future<bool> saveBudget() async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true, errorMessage: () => null);

    try {
      final allocations = [
        {'category': 'kebutuhan_pokok', 'percentage': state.kebutuhanPokok},
        {'category': 'pengeluaran_bebas', 'percentage': state.pengeluaranBebas},
        {'category': 'investasi_tabungan', 'percentage': state.investasiTabungan},
        {'category': 'dana_darurat', 'percentage': state.danaDarurat},
      ];

      // 1. Simpan konfigurasi anggaran ke backend Laravel
      await ref.read(budgetRepositoryProvider).storeBudget(
            monthlyIncome: state.monthlyIncome,
            allocations: allocations,
          );

      // 2. Tandai status onboarding selesai pada user
      final salary = ref.read(salaryControllerProvider);
      await ref.read(authControllerProvider.notifier).updateFinancialInfo(
            monthlyIncome: state.monthlyIncome,
            salaryDay: salary.salaryDay,
            isOnboarded: true,
          );

      // 3. Invalidate seluruh provider dashboard & data
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(profileUserProvider);
      ref.invalidate(onboardingStatusProvider);

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final budgetControllerProvider =
    NotifierProvider<BudgetController, BudgetState>(
  BudgetController.new,
);

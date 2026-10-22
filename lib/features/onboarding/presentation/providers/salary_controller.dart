import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/onboarding_providers.dart';

/// State No.3: numeric income + hari gajian sebagai source of truth.
/// UI hanya menampilkan & meneruskan event.
class SalaryState extends Equatable {
  const SalaryState({
    required this.monthlyIncome,
    required this.salaryDay,
    this.isSaving = false,
  });

  final double monthlyIncome;
  final int salaryDay;
  final bool isSaving;

  bool get isIncomeValid => monthlyIncome > 0;
  bool get isDayValid => salaryDay >= 1 && salaryDay <= 31;
  bool get canContinue => isIncomeValid && isDayValid && !isSaving;

  SalaryState copyWith({
    double? monthlyIncome,
    int? salaryDay,
    bool? isSaving,
  }) {
    return SalaryState(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      salaryDay: salaryDay ?? this.salaryDay,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [monthlyIncome, salaryDay, isSaving];
}

/// Controller No.3: menampung input, menyimpan via [OnboardingRepository].
/// Data tersimpan dapat dipakai ulang langkah onboarding berikutnya.
class SalaryController extends Notifier<SalaryState> {
  @override
  SalaryState build() {
    final saved = ref.read(onboardingRepositoryProvider).getSalarySetup();
    return SalaryState(
      monthlyIncome: saved?.monthlyIncome ?? 0,
      salaryDay: saved?.salaryDay ?? 25,
    );
  }

  void setIncome(double value) {
    state = state.copyWith(monthlyIncome: value);
  }

  void setSalaryDay(int day) {
    state = state.copyWith(salaryDay: day);
  }

  /// Simpan setup gaji. Berhasil -> true (UI bernavigasi ke No.4).
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(onboardingRepositoryProvider).saveSalarySetup(
            monthlyIncome: state.monthlyIncome,
            salaryDay: state.salaryDay,
          );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final salaryControllerProvider =
    NotifierProvider<SalaryController, SalaryState>(SalaryController.new);

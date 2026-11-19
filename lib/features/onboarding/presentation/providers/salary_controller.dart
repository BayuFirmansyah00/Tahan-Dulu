import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/providers/onboarding_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

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
    final user = ref.read(authControllerProvider).user;
    final income = (saved != null && saved.monthlyIncome > 0)
        ? saved.monthlyIncome
        : (user?.monthlyIncome?.toDouble() ?? 0.0);
    final day = (saved != null && saved.salaryDay >= 1 && saved.salaryDay <= 31)
        ? saved.salaryDay
        : (user?.salaryDay != null && user!.salaryDay! >= 1 && user.salaryDay! <= 31
            ? user.salaryDay!
            : 25);
    return SalaryState(
      monthlyIncome: income,
      salaryDay: day,
    );
  }

  void setIncome(double value) {
    state = state.copyWith(monthlyIncome: value);
  }

  void setSalaryDay(int day) {
    state = state.copyWith(salaryDay: day);
  }

  /// Simpan setup gaji. Berhasil -> true (UI bernavigasi ke No.4).
  ///
  /// Menyimpan via repository onboarding (PUT /user ke backend).
  /// Sinkronisasi ke AuthController dilakukan secara lokal tanpa mengirim HTTP request duplikat.
  Future<bool> save() async {
    if (!state.canContinue) return false;
    state = state.copyWith(isSaving: true);
    try {
      await ref.read(onboardingRepositoryProvider).saveSalarySetup(
            monthlyIncome: state.monthlyIncome,
            salaryDay: state.salaryDay,
          );

      // Sinkronkan state user di AuthController secara lokal tanpa duplikasi request HTTP PUT /user
      final currentUser = ref.read(authControllerProvider).user;
      if (currentUser != null) {
        ref.read(authControllerProvider.notifier).syncLocalUser(
              currentUser.copyWith(
                monthlyIncome: () => state.monthlyIncome.round(),
                salaryDay: () => state.salaryDay,
              ),
            );
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Pulihkan data gaji yang sudah tersimpan sebelumnya dari backend/profil.
  Future<void> loadExisting() async {
    final user = ref.read(authControllerProvider).user;
    if (user != null && (user.monthlyIncome ?? 0) > 0) {
      state = state.copyWith(
        monthlyIncome: user.monthlyIncome!.toDouble(),
        salaryDay: (user.salaryDay != null && user.salaryDay! >= 1 && user.salaryDay! <= 31)
            ? user.salaryDay!
            : state.salaryDay,
      );
    }
    try {
      final remote =
          await ref.read(onboardingRepositoryProvider).fetchExistingSalary();
      if (remote.income > 0) {
        state = state.copyWith(
          monthlyIncome: remote.income,
          salaryDay: remote.salaryDay,
        );
      }
    } catch (_) {}
  }

  /// Reset state (digunakan saat logout / ganti akun).
  void reset() {
    state = const SalaryState(monthlyIncome: 0, salaryDay: 25);
  }
}

final salaryControllerProvider =
    NotifierProvider<SalaryController, SalaryState>(SalaryController.new);

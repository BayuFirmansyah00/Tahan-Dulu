import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/finance_math.dart';
import '../../features/onboarding/presentation/providers/budget_controller.dart';
import '../../features/onboarding/presentation/providers/expenses_controller.dart';
import '../../features/onboarding/presentation/providers/goal_controller.dart';
import '../../features/onboarding/presentation/providers/salary_controller.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/api_config.dart';
import '../datasources/remote/remote_onboarding_repository.dart';
import '../datasources/remote/token_storage.dart';
import '../models/financial_plan.dart';
import '../repositories/onboarding_repository.dart';

/// Provider repository onboarding — ganti InMemory -> API cukup di sini.
/// Dipakai bersama oleh controller No.3 dan No.4 (satu sumber data).
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  if (!ApiConfig.useRemoteApi) return InMemoryOnboardingRepository();
  return RemoteOnboardingRepository(
    client: ApiClient(baseUrl: ApiConfig.baseUrl),
    tokens: TokenStorage(),
  );
});

/// Ringkasan rencana read-only untuk layar penyelesaian onboarding.
/// Dihitung dari data onboarding nyata (gaji, alokasi budget, pengeluaran rutin, target).
final financialPlanProvider = Provider<FinancialPlan>((ref) {
  final salaryState = ref.watch(salaryControllerProvider);
  final budgetState = ref.watch(budgetControllerProvider);
  final expensesState = ref.watch(expensesControllerProvider);
  final goalState = ref.watch(goalControllerProvider);
  final repoData = ref.watch(onboardingRepositoryProvider).getOnboardingData();

  final income = salaryState.monthlyIncome > 0
      ? salaryState.monthlyIncome
      : (budgetState.monthlyIncome > 0
          ? budgetState.monthlyIncome.toDouble()
          : (repoData?.monthlyIncome ?? 0.0));

  final salaryDay = (salaryState.salaryDay >= 1 && salaryState.salaryDay <= 31)
      ? salaryState.salaryDay
      : (repoData?.salaryDay ?? 25);

  final recurringTotal = expensesState.expenses.isNotEmpty
      ? expensesState.total
      : (repoData?.recurringExpenses ?? const []).fold<double>(
          0,
          (sum, e) => sum + e.monthlyAmount,
        );

  final goalName = goalState.name.trim().isNotEmpty
      ? goalState.name.trim()
      : (repoData?.financialGoal?.name ?? 'Investasi');

  final goalContribution = goalState.targetAmount > 0
      ? goalState.monthlyContribution
      : (repoData?.financialGoal?.deadline != null
          ? repoData!.financialGoal!.targetAmount /
              monthsUntil(repoData.financialGoal!.deadline!)
          : 0.0);

  final goalTargetAmount = goalState.targetAmount > 0
      ? goalState.targetAmount
      : (repoData?.financialGoal?.targetAmount ?? 0.0);

  return FinancialPlan.fromOnboarding(
    monthlyIncome: income,
    salaryDay: salaryDay,
    kebutuhanPokokPercent: budgetState.kebutuhanPokok,
    pengeluaranBebasPercent: budgetState.pengeluaranBebas,
    investasiTabunganPercent: budgetState.investasiTabungan,
    danaDaruratPercent: budgetState.danaDarurat,
    recurringExpensesTotal: recurringTotal,
    goalName: goalName,
    goalMonthlyContribution: goalContribution,
    goalTargetAmount: goalTargetAmount,
  );
});

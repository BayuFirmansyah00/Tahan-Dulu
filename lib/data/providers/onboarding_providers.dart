import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_plan.dart';
import '../repositories/onboarding_repository.dart';

/// Provider repository onboarding — ganti InMemory -> API cukup di sini.
/// Dipakai bersama oleh controller No.3 dan No.4 (satu sumber data).
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return InMemoryOnboardingRepository();
});

/// Ringkasan rencana read-only untuk layar penyelesaian onboarding.
/// Dihitung dari data No.3 (income), No.5 (needs), No.7 (nama target).
final financialPlanProvider = Provider<FinancialPlan>((ref) {
  final data = ref.watch(onboardingRepositoryProvider).getOnboardingData();
  final needs = (data?.recurringExpenses ?? const []).fold<double>(
    0,
    (sum, e) => sum + e.monthlyAmount,
  );
  return FinancialPlan.fromOnboarding(
    monthlyIncome: data?.monthlyIncome ?? 0,
    needsTotal: needs,
    goalName: data?.financialGoal?.name ?? 'Investasi',
  );
});

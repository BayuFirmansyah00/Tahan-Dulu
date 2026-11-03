import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/remote/api_config.dart';
import '../datasources/remote/api_client.dart';
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
/// Dihitung dari data onboarding (monthlyIncome, recurringExpenses, financialGoal).
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

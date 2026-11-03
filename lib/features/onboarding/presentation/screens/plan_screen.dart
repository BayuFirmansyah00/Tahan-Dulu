import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/financial_plan.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../onboarding/presentation/providers/salary_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/onboarding_status_provider.dart';

/// Layar penyelesaian onboarding: ringkasan rencana keuangan + CTA masuk.
/// Bukan Dashboard — Dashboard tetap placeholder tahap ini.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(financialPlanProvider);
    final textTheme = Theme.of(context).textTheme;

    final allocations = [
      (
        asset: AppAssets.obNeeds,
        icon: Icons.home_outlined,
        foreground: AppColors.error,
        background: const Color(0xFFFEE2E2),
        label: AppStrings.catNeeds,
        value: plan.needs,
      ),
      (
        asset: AppAssets.obEmergency,
        icon: Icons.savings_outlined,
        foreground: AppColors.warning,
        background: const Color(0xFFFEF3C7),
        label: AppStrings.saving,
        value: plan.saving,
      ),
      (
        asset: AppAssets.obInvestment,
        icon: Icons.show_chart_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
        label: AppStrings.investment,
        value: plan.investment,
      ),
      (
        asset: AppAssets.obAllocFlexible,
        icon: Icons.account_balance_wallet_outlined,
        foreground: AppColors.textPrimary,
        background: AppColors.surfaceVariant,
        label: AppStrings.flexibleExpense,
        value: plan.flexible,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAssets.successIllustration,
                          height: 190,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.planTitle,
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.planSubtitle,
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.monthlyIncomeLabel,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatCompact(plan.monthlyIncome),
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppStrings.monthlyAllocation,
                            style: textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in allocations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AllocationRow(
                              asset: item.asset,
                              icon: item.icon,
                              foreground: item.foreground,
                              background: item.background,
                              label: item.label,
                              value: item.value,
                            ),
                          ),
                        const SizedBox(height: 6),
                        _SafeCard(plan: plan),
                        const SizedBox(height: 12),
                        _GoalCard(plan: plan),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppStrings.planAdjustable,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.startAppButton,
                    isLoading: _completing,
                    onPressed: _completing
                        ? null
                        : () async {
                            final router = GoRouter.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _completing = true);
                            try {
                              final salary = ref.read(salaryControllerProvider);
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .updateFinancialInfo(
                                monthlyIncome: salary.monthlyIncome > 0
                                    ? salary.monthlyIncome.toInt()
                                    : null,
                                salaryDay: salary.salaryDay,
                                isOnboarded: true,
                              );
                              ref.invalidate(dashboardDataProvider);
                              ref.invalidate(accountsProvider);
                              ref.invalidate(profileUserProvider);
                              ref.invalidate(onboardingStatusProvider);
                              if (!mounted) return;
                              router.go(AppRoutes.dashboard);
                            } catch (_) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text(AppStrings.saveFailed)),
                              );
                            } finally {
                              if (mounted) setState(() => _completing = false);
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.asset,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.label,
    required this.value,
  });

  final String asset;
  final IconData icon;
  final Color foreground;
  final Color background;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Image.asset(
          asset,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: foreground, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: textTheme.bodyLarge),
        ),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SafeCard extends StatelessWidget {
  const _SafeCard({required this.plan});

  final FinancialPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.safeToday,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(plan.safePerDay),
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                Text(
                  AppStrings.safeTodayDesc,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.plan});

  final FinancialPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target ${plan.goalName}',
                  style: textTheme.labelSmall,
                ),
                Text(
                  '${CurrencyFormatter.formatCompact(plan.investment)} '
                  '${AppStrings.perMonth}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

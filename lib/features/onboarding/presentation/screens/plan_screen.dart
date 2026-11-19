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
import '../../../onboarding/presentation/providers/budget_controller.dart';
import '../../../onboarding/presentation/providers/expenses_controller.dart';
import '../../../onboarding/presentation/providers/goal_controller.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _hydratePlanData();
      }
    });
  }

  Future<void> _hydratePlanData() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.hydrateAll();
    if (!mounted) return;
    await ref.read(budgetControllerProvider.notifier).loadExisting();
    await ref.read(salaryControllerProvider.notifier).loadExisting();
    await ref.read(expensesControllerProvider.notifier).loadExisting();
    await ref.read(goalControllerProvider.notifier).loadExisting();
  }

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
        label: '${AppStrings.catNeeds} (${plan.kebutuhanPokokPercent.toStringAsFixed(0)}%)',
        value: plan.kebutuhanPokok,
      ),
      (
        asset: AppAssets.obAllocFlexible,
        icon: Icons.account_balance_wallet_outlined,
        foreground: AppColors.textPrimary,
        background: AppColors.surfaceVariant,
        label: '${AppStrings.flexibleExpense} (${plan.pengeluaranBebasPercent.toStringAsFixed(0)}%)',
        value: plan.pengeluaranBebas,
      ),
      (
        asset: AppAssets.obInvestment,
        icon: Icons.show_chart_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
        label: '${AppStrings.investmentSaving} (${plan.investasiTabunganPercent.toStringAsFixed(0)}%)',
        value: plan.investasiTabungan,
      ),
      (
        asset: AppAssets.obEmergency,
        icon: Icons.savings_outlined,
        foreground: AppColors.warning,
        background: const Color(0xFFFEF3C7),
        label: '${AppStrings.emergencyFund} (${plan.danaDaruratPercent.toStringAsFixed(0)}%)',
        value: plan.danaDarurat,
      ),
      if (plan.unallocated > 0)
        (
          asset: AppAssets.obAllocFlexible,
          icon: Icons.pie_chart_outline,
          foreground: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
          label: '${AppStrings.unallocatedBudget} (${plan.unallocatedPercent.toStringAsFixed(0)}%)',
          value: plan.unallocated,
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
                        _RecurringCommitmentCard(plan: plan),
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
                              final saved = await ref
                                  .read(authControllerProvider.notifier)
                                  .updateFinancialInfo(
                                    monthlyIncome: salary.monthlyIncome > 0
                                        ? salary.monthlyIncome.toInt()
                                        : null,
                                    salaryDay: salary.salaryDay,
                                    isOnboarded: true,
                                  );
                              if (!saved) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(AppStrings.saveFailed),
                                    ),
                                  );
                                }
                                return;
                              }
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
                                  content: Text(AppStrings.saveFailed),
                                ),
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
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        Text(
          CurrencyFormatter.formatCompact(value),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final isDeficit = plan.safePerDay < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDeficit ? AppColors.error : AppColors.primary,
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
            child: Icon(
              isDeficit ? Icons.warning_amber_rounded : Icons.verified_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.safeToday,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isDeficit) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppStrings.todayDeficitBadge,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatCompact(plan.safePerDay),
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${AppStrings.safeTodayDesc} (${plan.daysRemaining} hari tersisa)',
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
    final hasGoal = plan.goalTargetAmount > 0;

    if (!hasGoal) {
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
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flag_outlined,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.goalsSection, style: textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Belum diatur (dapat dibuat kapan saja di Dashboard)',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayAmount = plan.goalMonthlyContribution > 0
        ? plan.goalMonthlyContribution
        : plan.investasiTabungan;

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
                Text('Target ${plan.goalName}', style: textTheme.labelSmall),
                Text(
                  '${CurrencyFormatter.formatCompact(displayAmount)} '
                  '${AppStrings.perMonth}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _RecurringCommitmentCard extends StatelessWidget {
  const _RecurringCommitmentCard({required this.plan});

  final FinancialPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasExpenses = plan.recurringExpensesTotal > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasExpenses
            ? AppColors.surfaceVariant.withValues(alpha: 0.5)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasExpenses ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: hasExpenses ? Border.all(color: AppColors.border) : null,
            ),
            child: Icon(
              hasExpenses ? Icons.repeat_rounded : Icons.receipt_long_outlined,
              color: hasExpenses ? AppColors.textPrimary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.recurringCommitmentLabel,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasExpenses) ...[
                  Text(
                    '${CurrencyFormatter.formatCompact(plan.recurringExpensesTotal)} '
                    '${AppStrings.perMonth}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.recurringCommitmentDesc,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Belum ada pengeluaran rutin (diatur nanti)',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

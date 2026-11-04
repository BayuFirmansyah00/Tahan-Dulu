import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/goal_math.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Detail Target: ring progres, info, setoran/preview, edit.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.goalDetailTitle),
        actions: [
          IconButton(
            icon: const AppImageIcon(
              assetPath: AppAssets.actionDelete,
              size: 22,
              fallbackIcon: Icons.delete_outline,
            ),
            tooltip: 'Hapus Target',
            onPressed: () async {
              final items = goals.asData?.value;
              final match = items?.where((e) => e.id == goalId).firstOrNull;
              if (match == null) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus target ini?'),
                  content: Text(
                    '“${match.name}” akan dihapus. Riwayat transaksi pengeluaran aktual dan saldo akun kamu tetap utuh.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(AppStrings.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final ok = await ref
                  .read(goalsControllerProvider.notifier)
                  .deleteGoal(goalId);
              if (!context.mounted) return;
              if (ok) {
                context.go(AppRoutes.goals);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.saveFailed)),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 3,
        onTap: (i) => goalsBottomNavTap(context, i),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: goals.when(
              data: (items) {
                final matches =
                    items.where((e) => e.id == goalId);
                if (matches.isEmpty) {
                  return const GoalNotFoundView();
                }
                return _Body(goal: matches.first);
              },
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(goalsListProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Rekomendasi & estimasi dari mesin kalkulasi bersama.
    final perLabel = goal.frequency == DepositFrequency.monthly
        ? AppStrings.perMonth
        : AppStrings.perWeekSuffix;
    final recommendation = recommendedPerPeriod(
      target: goal.targetAmount,
      collected: goal.currentAmount,
      deadline: goal.deadline,
      frequency: goal.frequency,
    );
    final eta = estimateReachDate(
      target: goal.targetAmount,
      collected: goal.currentAmount,
      perDeposit: goal.recurringAmount,
      frequency: goal.frequency,
    );
    final String recommendValue;
    if (goal.isReached) {
      recommendValue = AppStrings.goalReachedNoDeposit;
    } else if (recommendation == null) {
      recommendValue = AppStrings.goalRescheduleNote;
    } else {
      recommendValue =
          '${CurrencyFormatter.formatCompact(recommendation)} $perLabel';
    }
    final String etaValue;
    if (goal.isReached) {
      etaValue = AppStrings.goalStatusReached;
    } else if (eta != null) {
      etaValue = DateFormatter.monthYear(eta);
    } else {
      etaValue = AppStrings.simulateUnreachable;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GoalHeader(category: goal.category, height: 150),
          const SizedBox(height: 12),
          Text(goal.name, style: textTheme.headlineMedium),
          Text(
            goalCategoryLabel(goal.category),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GoalCircularProgress(progress: goal.progress),
          const SizedBox(height: 8),
          Text(
            '${CurrencyFormatter.formatCompact(goal.currentAmount)}'
            ' dari ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (goal.isReached) ...[
            const SizedBox(height: 12),
            _ReachedBanner(goal: goal),
          ],
          const SizedBox(height: 16),
          _InfoRow(
            label: AppStrings.goalSavedAmount,
            value: CurrencyFormatter.formatCompact(goal.currentAmount),
          ),
          _InfoRow(
            label: AppStrings.goalRemaining,
            value: CurrencyFormatter.formatCompact(goal.remaining),
          ),
          _InfoRow(
            label: AppStrings.goalDetailDeadline,
            value: goal.deadline == null
                ? '-'
                : DateFormatter.dayMonthYear(goal.deadline!),
          ),
          _InfoRow(
            label: AppStrings.goalDetailPeriodic,
            value: goal.recurringAmount > 0
                ? '${CurrencyFormatter.formatCompact(goal.recurringAmount)}'
                    ' ${goal.frequency == DepositFrequency.monthly ? AppStrings.perMonth : AppStrings.perWeekSuffix}'
                : '-',
          ),
          _AdvisoryRow(
            label: AppStrings.goalRecommendLabel,
            value: recommendValue,
            isWarning: !goal.isReached && recommendation == null,
          ),
          _AdvisoryRow(
            label: AppStrings.goalDetailEta,
            value: etaValue,
            isWarning: !goal.isReached && eta == null,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: AppStrings.addFundsAction,
            assetPath: AppAssets.actionAddMoney,
            icon: Icons.add,
            onPressed: () => context.push(
              '${AppRoutes.goals}/${goal.id}/deposit',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppOutlineButton(
                  label: AppStrings.historyTitle,
                  assetPath: AppAssets.actionHistory,
                  icon: Icons.history_outlined,
                  onPressed: () => context.push(
                    '${AppRoutes.goals}/${goal.id}/history',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppOutlineButton(
                  label: AppStrings.simulateTitle,
                  assetPath: AppAssets.actionSimulation,
                  icon: Icons.query_stats_outlined,
                  onPressed: () => context.push(
                    '${AppRoutes.goals}/${goal.id}/simulate',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppOutlineButton(
            label: AppStrings.editGoalAction,
            assetPath: AppAssets.actionEdit,
            icon: Icons.edit_outlined,
            onPressed: () => context.push(
              '${AppRoutes.goals}/${goal.id}/edit',
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris info bertumpuk (label di atas, nilai di bawah) untuk teks
/// rekomendasi/estimasi yang bisa panjang — aman di layar sempit,
/// tidak seperti [_InfoRow] yang berdampingan.
class _AdvisoryRow extends StatelessWidget {
  const _AdvisoryRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWarning
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReachedBanner extends StatelessWidget {
  const _ReachedBanner({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.goals}/${goal.id}/achieved',
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const AppImageIcon(
              assetPath: AppAssets.rankMedal1,
              size: 22,
              fallbackIcon: Icons.emoji_events_outlined,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.achievedBadge,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ),
            const AppImageIcon(
              assetPath: AppAssets.navForward,
              size: 20,
              fallbackIcon: Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../widgets/goal_widgets.dart';

/// Daftar Target Keuangan: ringkasan total + kartu per target.
class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.goalsListTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.priorityTitle,
            onPressed: () => context.push(AppRoutes.goalsPriority),
            icon: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Image.asset(
                AppAssets.priorityNavIcon,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.leaderboard_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
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
              data: (items) => items.isEmpty
                  ? const _EmptyList()
                  : _List(items: items),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(goalsListProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatefulWidget {
  const _List({required this.items});

  final List<FinancialGoal> items;

  @override
  State<_List> createState() => _ListState();
}

/// Tab daftar target: aktif / tercapai / lewat tenggat.
/// Klasifikasi murni dari state yang ada (tanpa field baru).
enum GoalTab { active, reached, overdue }

/// Saring daftar target per tab. [now] untuk determinisme test.
List<FinancialGoal> goalsForTab(
  List<FinancialGoal> items,
  GoalTab tab, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  bool isOverdue(FinancialGoal goal) =>
      !goal.isReached &&
      goal.deadline != null &&
      !goal.deadline!.isAfter(current);
  switch (tab) {
    case GoalTab.reached:
      return items.where((e) => e.isReached).toList();
    case GoalTab.overdue:
      return items.where(isOverdue).toList();
    case GoalTab.active:
      return items.where((e) => !e.isReached && !isOverdue(e)).toList();
  }
}

class _ListState extends State<_List> {
  GoalTab _tab = GoalTab.active;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = widget.items;
    final totalTarget =
        items.fold<double>(0, (sum, e) => sum + e.targetAmount);
    final totalSaved =
        items.fold<double>(0, (sum, e) => sum + e.currentAmount);
    final overall = totalTarget <= 0 ? 0.0 : totalSaved / totalTarget;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.goalsListSubtitle,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.goalsTotalTarget,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.formatCompact(
                                totalTarget,
                              ),
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF6D8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.txSavings,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(
                                Icons.savings_outlined,
                                color: AppColors.warning,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.goalsTotalSaved,
                                    style:
                                        textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.formatCompact(
                                        totalSaved,
                                      ),
                                      style: textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GoalLinearProgress(value: overall),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(overall * 100).round()}%',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TabBar(
            tab: _tab,
            activeCount: goalsForTab(items, GoalTab.active).length,
            reachedCount: goalsForTab(items, GoalTab.reached).length,
            overdueCount: goalsForTab(items, GoalTab.overdue).length,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 8),
          for (final goal in goalsForTab(items, _tab)) ...[
            _GoalCard(goal: goal),
            const SizedBox(height: 10),
          ],
          if (goalsForTab(items, _tab).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppStrings.goalTabEmpty,
                style: textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 6),
          _NewGoalButton(),
        ],
      ),
    );
  }
}

class _NewGoalButton extends ConsumerWidget {
  const _NewGoalButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      label: AppStrings.newGoalButton,
      icon: Icons.add,
      onPressed: () {
        ref.read(goalsControllerProvider.notifier).reset();
        context.push(AppRoutes.goalsNew);
      },
    );
  }
}

/// Badge status target: tercapai / tenggat lewat / aktif.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final bool overdue = !goal.isReached &&
        goal.deadline != null &&
        !goal.deadline!.isAfter(DateTime.now());
    final String label;
    final Color foreground;
    final Color background;
    if (goal.isReached) {
      label = AppStrings.goalStatusReached;
      foreground = AppColors.primary;
      background = AppColors.primarySoft;
    } else if (overdue) {
      label = AppStrings.goalStatusOverdue;
      foreground = AppColors.error;
      background = const Color(0xFFFEE2E2);
    } else {
      label = AppStrings.goalStatusActive;
      foreground = AppColors.textSecondary;
      background = AppColors.surfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Tab filter daftar target dengan jumlah per status.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tab,
    required this.activeCount,
    required this.reachedCount,
    required this.overdueCount,
    required this.onChanged,
  });

  final GoalTab tab;
  final int activeCount;
  final int reachedCount;
  final int overdueCount;
  final ValueChanged<GoalTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(GoalTab value, String label, int count) {
      final selected = tab == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            '$label $count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(GoalTab.active, AppStrings.goalStatusActive, activeCount),
        chip(GoalTab.reached, AppStrings.goalStatusReached, reachedCount),
        chip(GoalTab.overdue, AppStrings.goalTabOverdue, overdueCount),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.goals}/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GoalIcon(category: goal.category, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: textTheme.titleMedium),
                      Text(
                        '${CurrencyFormatter.formatCompact(goal.currentAmount)}'
                        ' / ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GoalLinearProgress(value: goal.progress, height: 6),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${CurrencyFormatter.formatCompact(goal.remaining)} lagi',
                style: textTheme.labelSmall,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(
                  AppAssets.goalActionCalendar,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    goal.deadline == null
                        ? '${AppStrings.goalDeadlineLabel}: -'
                        : '${AppStrings.goalDeadlineLabel}: '
                            '${DateFormatter.dayMonthYear(goal.deadline!)}',
                    style: textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(goal: goal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyList extends ConsumerWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.goalsPiggy,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.flag_outlined,
                size: 72,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.goalEmptyTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.goalEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: AppStrings.newGoalAction,
              icon: Icons.add,
              onPressed: () {
                ref.read(goalsControllerProvider.notifier).reset();
                context.push(AppRoutes.goalsNew);
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/goal_deposit.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Target Tercapai: hanya bila progres benar-benar 100%+.
/// Tanpa klaim pembelian investasi; tanpa tombol investasi palsu.
class GoalAchievedScreen extends ConsumerWidget {
  const GoalAchievedScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsListProvider);
    final deposits = ref.watch(goalDepositsProvider(goalId));

    return Scaffold(
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
                  return const Center(
                    child: Text(AppStrings.accountNotFound),
                  );
                }
                final goal = matches.first;
                // Tanpa redirect otomatis: baca tepat setelah invalidasi
                // bisa transien; rebuild berikutnya mengoreksi tampilan.
                // Status jujur ditampilkan, bukan dialihkan diam-diam.
                if (!goal.isReached) {
                  return _NotReached(goalId: goalId);
                }
                return deposits.when(
                  data: (list) => _Body(
                    goalName: goal.name,
                    category: goalCategoryLabel(goal.category),
                    target: goal.targetAmount,
                    collected: goal.currentAmount,
                    months: _durationMonths(list),
                  ),
                  loading: () => const AppLoading(),
                  error: (e, _) =>
                      Center(child: AppErrorState(onRetry: () => ref.invalidate(goalDepositsProvider(goalId)))),
                );
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

/// Durasi bulan kalender setoran pertama-terakhir, minimal 1 bila ada.
int _durationMonths(List<GoalDeposit> deposits) {
  if (deposits.isEmpty) return 1;
  var first = deposits.first.date;
  var last = first;
  for (final d in deposits) {
    if (d.date.isBefore(first)) first = d.date;
    if (d.date.isAfter(last)) last = d.date;
  }
  final span = (last.year - first.year) * 12 + (last.month - first.month) + 1;
  return span < 1 ? 1 : span;
}

/// Status jujur saat target dibuka tetapi belum tercapai
/// (mis. baca transien atau deep link): kembali manual, tanpa lompatan.
class _NotReached extends StatelessWidget {
  const _NotReached({required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.simulateUnreachable,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: AppStrings.backToHome,
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.goalName,
    required this.category,
    required this.target,
    required this.collected,
    required this.months,
  });

  final String goalName;
  final String category;
  final double target;
  final double collected;
  final int months;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const AppImageIcon(
            assetPath: AppAssets.statusSuccess,
            size: 88,
            fallbackIcon: Icons.check_circle,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.achievedTitle,
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.achievedSubtitle} $goalName.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            goalName,
            style: textTheme.titleMedium,
          ),
          Text(
            CurrencyFormatter.formatCompact(target),
            style: textTheme.headlineMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          PriorityChip(label: AppStrings.achievedBadge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: AppStrings.achievedDuration,
                  value: '$months ${AppStrings.monthSuffix}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: AppStrings.achievedTotalDeposits,
                  value: CurrencyFormatter.formatCompact(collected),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.achievedNextTitle,
              style: textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: AppStrings.newGoalAction,
            onPressed: () {
              context.go(AppRoutes.goalsNew);
            },
          ),
          const SizedBox(height: 12),
          AppOutlineButton(
            label: AppStrings.backToHome,
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

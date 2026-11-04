import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/finance_math.dart';
import '../../../../core/utils/goal_math.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../widgets/goal_widgets.dart';

/// Simulasi Target: slider bulanan + estimasi, tanpa mutasi.
/// "Gunakan" hanya menyimpan rencana setelah konfirmasi.
class GoalSimulateScreen extends ConsumerStatefulWidget {
  const GoalSimulateScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalSimulateScreen> createState() =>
      _GoalSimulateScreenState();
}

class _GoalSimulateScreenState
    extends ConsumerState<GoalSimulateScreen> {
  double? _simulated;
  DepositFrequency? _frequency;

  Future<void> _usePlan(double amount, DepositFrequency frequency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmUsePlanTitle),
        content: const Text(AppStrings.confirmUsePlanBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.usePlanAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(goalsControllerProvider.notifier)
        .applyPlan(
          goalId: widget.goalId,
          recurringAmount: amount,
          frequency: frequency,
        );
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsListProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.simulateTitle),
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
                    items.where((e) => e.id == widget.goalId);
                if (matches.isEmpty) {
                  return const Center(
                    child: Text(AppStrings.accountNotFound),
                  );
                }
                final goal = matches.first;
                final frequency = _frequency ?? goal.frequency;
                final simulated = _simulated ??
                    (goal.recurringAmount > 0
                        ? goal.recurringAmount
                        : 500000.0);
                // Mesin kalkulasi bersama dengan Atur Target & Detail.
                final eta = estimateReachDate(
                  target: goal.targetAmount,
                  collected: goal.currentAmount,
                  perDeposit: simulated,
                  frequency: frequency,
                );
                final reached = goal.isReached;
                final perLabel =
                    frequency == DepositFrequency.monthly
                        ? AppStrings.perMonth
                        : AppStrings.perWeekSuffix;
                // Sisa waktu hingga estimasi tercapai.
                final now = DateTime.now();
                final String? remainingText;
                if (reached || eta == null) {
                  remainingText = null;
                } else if (frequency == DepositFrequency.monthly) {
                  final months = monthsUntil(eta, now: now);
                  remainingText =
                      'dalam $months ${AppStrings.monthSuffix} lagi';
                } else {
                  final weeks = eta.difference(now).inDays ~/ 7;
                  remainingText =
                      'dalam ${weeks < 1 ? 1 : weeks} ${AppStrings.weekSuffix} lagi';
                }
                final missesDeadline = !reached &&
                    eta != null &&
                    goal.deadline != null &&
                    eta.isAfter(goal.deadline!);

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.simulateQuestion,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.simulateHint,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            GoalSummaryHeader(goal: goal),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.depositFrequency,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            FrequencyToggle(
                              frequency: frequency,
                              onChanged: (f) =>
                                  setState(() => _frequency = f),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.simulateAmount,
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(simulated),
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            Slider(
                              value: simulated
                                  .clamp(50000.0, 3000000.0),
                              min: 50000,
                              max: 3000000,
                              divisions: 59,
                              label: CurrencyFormatter.formatCompact(
                                simulated,
                              ),
                              onChanged: (v) =>
                                  setState(() => _simulated = v),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.simulateEta,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            if (reached)
                              Text(
                                AppStrings.simulateReached,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (eta == null)
                              Text(
                                AppStrings.simulateUnreachable,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error,
                                ),
                              )
                            else
                              Text(
                                '${DateFormatter.monthYear(eta)} $perLabel',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                            if (remainingText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                remainingText,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                            if (missesDeadline) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      AppAssets.goalActionWarning,
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) =>
                                          const Icon(
                                        Icons.warning_amber_outlined,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppStrings.goalShortfallNote,
                                        style: textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Rencana saat ini: '
                              '${CurrencyFormatter.formatCompact(goal.recurringAmount)}'
                              ' ${goal.frequency == DepositFrequency.monthly ? AppStrings.perMonth : AppStrings.perWeekSuffix}',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: AppButton(
                        label: AppStrings.usePlanAction,
                        onPressed: reached
                            ? null
                            : () => _usePlan(simulated, frequency),
                      ),
                    ),
                  ],
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

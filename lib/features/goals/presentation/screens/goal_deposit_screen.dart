import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../widgets/goal_widgets.dart';

const List<double> _quickAmounts = [100000, 250000, 500000, 1000000];

/// Tambah Dana: nominal + cepat + sumber + preview + konfirmasi.
/// Setoran = alokasi (tidak mengurangi saldo akun, tidak tercatat
/// sebagai pengeluaran). Guard ganda bawaan.
class GoalDepositScreen extends ConsumerStatefulWidget {
  const GoalDepositScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDepositScreen> createState() => _GoalDepositScreenState();
}

class _GoalDepositScreenState extends ConsumerState<GoalDepositScreen> {
  late final TextEditingController _amountController;
  double _amount = 0;
  String? _accountId;
  bool _submitting = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    final data =
        ref.read(onboardingRepositoryProvider).getOnboardingData();
    final instruments = data?.financialInstruments ?? const [];
    if (instruments.isNotEmpty) _accountId = instruments.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm(FinancialGoal goal) async {
    if (_amount <= 0) return;
    setState(() {
      _submitting = true;
      _saveFailed = false;
    });
    try {
      final saved = await ref
          .read(goalsControllerProvider.notifier)
          .addDeposit(
            goalId: goal.id,
            amount: _amount,
            accountId: _accountId,
          );
      if (!mounted) return;
      if (saved == null) {
        setState(() => _saveFailed = true);
        return;
      }
      final updated = goal.copyWith(
        currentAmount: goal.currentAmount + _amount,
      );
      if (updated.isReached) {
        context.push('${AppRoutes.goals}/${goal.id}/achieved');
      } else {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.depositTitle)),
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
                return _Body(
                  goal: matches.first,
                  amountController: _amountController,
                  amount: _amount,
                  accountId: _accountId,
                  submitting: _submitting,
                  saveFailed: _saveFailed,
                  onAmount: (v) => setState(() => _amount = v),
                  onQuick: (v) {
                    _amountController.text =
                        RupiahInputFormatter.format(v);
                    setState(() => _amount = v);
                  },
                  onAccount: (v) => setState(() => _accountId = v),
                  onConfirm: () => _confirm(matches.first),
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

class _Body extends StatelessWidget {
  const _Body({
    required this.goal,
    required this.amountController,
    required this.amount,
    required this.accountId,
    required this.submitting,
    required this.saveFailed,
    required this.onAmount,
    required this.onQuick,
    required this.onAccount,
    required this.onConfirm,
  });

  final FinancialGoal goal;
  final TextEditingController amountController;
  final double amount;
  final String? accountId;
  final bool submitting;
  final bool saveFailed;
  final ValueChanged<double> onAmount;
  final ValueChanged<double> onQuick;
  final ValueChanged<String?> onAccount;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final after = goal.currentAmount + (amount > 0 ? amount : 0);
    final beforeProgress = goal.progress.clamp(0.0, 1.0);
    final afterProgress = (goal.targetAmount <= 0
            ? 0.0
            : after / goal.targetAmount)
        .clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.depositTo,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  goal.name,
                  style: textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                Text(
                  AppStrings.depositHelp,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                GoalSummaryHeader(goal: goal),
                const SizedBox(height: 16),
                AppTextField(
                  controller: amountController,
                  label: AppStrings.periodicSaving,
                  hint: '0',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (v) =>
                      onAmount(RupiahInputFormatter.parse(v)),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.quickAmounts,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final quick in _quickAmounts)
                      _QuickChip(
                        label:
                            '+${CurrencyFormatter.formatCompact(quick)}',
                        selected: amount == quick,
                        onTap: () => onQuick(quick),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.fundingSource,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GoalAccountDropdown(
                  value: accountId,
                  onChanged: onAccount,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.depositPreview,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${CurrencyFormatter.formatCompact(goal.currentAmount)}'
                        ' → ${CurrencyFormatter.formatCompact(after)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GoalLinearProgress(value: beforeProgress, height: 6),
                      const SizedBox(height: 4),
                      GoalLinearProgress(value: afterProgress, height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets.goalActionInfo,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.depositImpactNote,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (saveFailed) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.saveFailed,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: AppButton(
            label: AppStrings.confirmDepositAction,
            isLoading: submitting,
            onPressed: submitting || amount <= 0 ? null : onConfirm,
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

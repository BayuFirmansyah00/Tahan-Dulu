import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../goals/presentation/utils/goal_category_ui.dart';
import '../providers/goal_controller.dart';

String _categoryLabel(GoalCategory category) => goalCategoryLabel(category);

String _formatMonth(DateTime date) => DateFormatter.monthYear(date);

/// No.7 — Target Keuangan: kategori, nama, nominal, waktu, estimasi.
/// Selesai -> Dashboard (No.8, placeholder tahap ini).
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(goalControllerProvider);
    _nameController = TextEditingController(text: state.name);
    _amountController = TextEditingController(
      text: state.targetAmount > 0
          ? RupiahInputFormatter.format(state.targetAmount)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _markTouched() {
    if (!_touched) setState(() => _touched = true);
  }

  Future<void> _pickDate(DateTime current) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final initial = current.isBefore(tomorrow) ? tomorrow : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) {
      ref.read(goalControllerProvider.notifier).setTargetDate(picked);
      _markTouched();
    }
  }

  Future<void> _finish() async {
    final ok = await ref.read(goalControllerProvider.notifier).save();
    if (ok && mounted) context.go(AppRoutes.onboardingPlan);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalControllerProvider);
    final notifier = ref.read(goalControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final showNameError = _touched && !state.isNameValid;
    final showAmountError = _touched && !state.isAmountValid;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.onboardingStep4,
                              style: textTheme.labelSmall,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 1.0,
                                  minHeight: 8,
                                  backgroundColor: AppColors.primarySoft,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.goalsTitle,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.goalsSubtitle,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.goalCategoryLabel,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final category in GoalCategory.values)
                              _GoalChip(
                                asset: goalOnboardingAssetFor(category),
                                label: _categoryLabel(category),
                                selected: state.category == category,
                                onTap: () {
                                  notifier.setCategory(category);
                                  _markTouched();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _nameController,
                          label: AppStrings.goalName,
                          hint: AppStrings.goalNameHint,
                          onChanged: (v) {
                            notifier.setName(v);
                            _markTouched();
                          },
                        ),
                        if (showNameError) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.goalNameRequired,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _amountController,
                          label: AppStrings.goalAmount,
                          hint: '0',
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: (v) {
                            notifier.setTargetAmount(
                              RupiahInputFormatter.parse(v),
                            );
                            _markTouched();
                          },
                        ),
                        if (showAmountError) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.goalAmountRequired,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(AppStrings.goalDate,
                            style: textTheme.labelLarge),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _pickDate(state.targetDate),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatMonth(state.targetDate),
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SummaryCard(state: state),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.goalHelper,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.doneButton,
                    isLoading: state.isSaving,
                    onPressed:
                        state.canContinue ? _finish : null,
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

/// Ringkasan target: nama, nominal, waktu, estimasi setoran.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final GoalState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.name.isEmpty ? '-' : state.name,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(state.targetAmount),
            style: textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${_formatMonth(state.targetDate)}',
            style: textTheme.bodyMedium,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.contributionTitle,
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${CurrencyFormatter.formatCompact(
                    state.monthlyContribution,
                  )} ${AppStrings.perMonth}',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Aset 3D kecil; null -> chip teks saja (outline konsisten).
  final String? asset;
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
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null) ...[
              Image.asset(
                asset!,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(width: 22, height: 22),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

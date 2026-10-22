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
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Atur Target langkah 2: ringkasan + rencana berkala + simpan final.
/// Guard: draf langkah 1 tak valid -> kembali ke buat target.
class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  late final TextEditingController _planController;
  bool _saving = false;

  /// True bila pengguna mengetik nominal rencana manual (prefill
  /// rekomendasi tidak boleh menimpa ketikan).
  bool _planTouched = false;

  /// Isi field rencana dari rekomendasi mesin bila pengguna belum
  /// mengetik. Dipakai saat layar dibuka & saat frekuensi diganti.
  void _applyRecommendation() {
    final draft = ref.read(goalsControllerProvider);
    final rec = recommendedPerPeriod(
      target: draft.targetAmount,
      collected: 0,
      deadline: draft.targetDate,
      frequency: draft.frequency,
    );
    if (rec == null || rec <= 0 || !mounted) return;
    _planController.text = RupiahInputFormatter.format(rec);
    ref.read(goalsControllerProvider.notifier).setRecurringAmount(rec);
  }

  @override
  void initState() {
    super.initState();
    _planController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(goalsControllerProvider);
      if (!draft.isStepOneValid) {
        if (mounted) context.go(AppRoutes.goalsNew);
        return;
      }
      if (draft.recurringAmount > 0) {
        _planController.text =
            RupiahInputFormatter.format(draft.recurringAmount);
      } else {
        _applyRecommendation();
      }
    });
  }

  @override
  void dispose() {
    _planController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved =
          await ref.read(goalsControllerProvider.notifier).saveGoal();
      if (!mounted) return;
      if (saved != null) {
        context.go('${AppRoutes.goals}/${saved.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(goalsControllerProvider);
    final notifier = ref.read(goalsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final remaining = draft.targetAmount;
    final perPeriod = notifier.requiredPerPeriod(
      remaining: remaining,
      targetDate: draft.targetDate ?? DateTime.now(),
      frequency: draft.frequency,
    );
    final perLabel =
        draft.frequency == DepositFrequency.monthly
            ? AppStrings.perMonth
            : AppStrings.perWeekSuffix;
    // Estimasi tercapai dari nominal rencana saat ini; bila melewati
    // tenggat tampilkan peringatan selisihnya.
    final eta = estimateReachDate(
      target: draft.targetAmount,
      collected: 0,
      perDeposit: draft.recurringAmount,
      frequency: draft.frequency,
    );
    final missesDeadline = eta != null &&
        draft.targetDate != null &&
        eta.isAfter(draft.targetDate!);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.setupGoalTitle)),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 3,
        onTap: (i) => goalsBottomNavTap(context, i),
      ),
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
                        GoalHeader(
                          category:
                              draft.category ?? GoalCategory.others,
                          height: 140,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            draft.name.isEmpty ? '-' : draft.name,
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        Center(
                          child: Text(
                            draft.category == null
                                ? '-'
                                : 'Kategori: ${goalCategoryLabel(draft.category!)}',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: AppStrings.goalAmount,
                          value: CurrencyFormatter.formatCompact(
                            draft.targetAmount,
                          ),
                        ),
                        _InfoRow(
                          label: AppStrings.goalDate,
                          value: draft.targetDate == null
                              ? '-'
                              : DateFormatter.dayMonthYear(
                                  draft.targetDate!,
                                ),
                        ),
                        _InfoRow(
                          label: AppStrings.goalSavedAmount,
                          value: CurrencyFormatter.formatCompact(0),
                        ),
                        _InfoRow(
                          label: AppStrings.goalRemaining,
                          value: CurrencyFormatter.formatCompact(remaining),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.periodicSaving,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _planController,
                          hint: '0',
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: (v) {
                            _planTouched = true;
                            notifier.setRecurringAmountText(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        FrequencyToggle(
                          frequency: draft.frequency,
                          onChanged: (frequency) {
                            notifier.setFrequency(frequency);
                            if (!_planTouched) _applyRecommendation();
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.savingSource,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        GoalAccountDropdown(
                          value: draft.sourceAccountId,
                          onChanged: notifier.setSourceAccount,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: perPeriod > 0
                              ? Text(
                                  'Untuk mencapai target ini, kamu perlu menyisihkan sekitar '
                                  '${CurrencyFormatter.formatCompact(perPeriod)}'
                                  ' $perLabel',
                                  style: textTheme.bodyMedium,
                                )
                              : Text(
                                  AppStrings.estimateUnreachable,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                ),
                        ),
                        if (draft.recurringAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: missesDeadline
                                    ? Theme.of(context).colorScheme.error
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eta == null
                                      ? AppStrings.estimateUnreachable
                                      : '${AppStrings.goalEtaLabel}: '
                                          '${DateFormatter.monthYear(eta)}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: eta == null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .error
                                        : null,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (missesDeadline) ...[
                                  const SizedBox(height: 8),
                                  Row(
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
                                ],
                              ],
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
                    label: AppStrings.saveGoalAction,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
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

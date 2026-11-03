import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/reminder_settings.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../goals/presentation/providers/goals_controller.dart';
import '../providers/notifications_providers.dart';

/// Layar Pengingat Menabung: form jadwal menyisihkan dana per target.
class SavingReminderScreen extends ConsumerStatefulWidget {
  const SavingReminderScreen({super.key});

  @override
  ConsumerState<SavingReminderScreen> createState() =>
      _SavingReminderScreenState();
}

class _SavingReminderScreenState extends ConsumerState<SavingReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  bool _saving = false;
  bool _initializedAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    Future.microtask(
      () => ref.read(savingReminderControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onNav(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.transactions);
      case 2:
        context.push(AppRoutes.transactionRecordMethod);
      case 3:
        context.push(AppRoutes.goals);
      case 4:
        context.push(AppRoutes.settings);
    }
  }

  void _syncAmountOnce(SavingReminderDraft draft) {
    if (_initializedAmount || !draft.loaded) return;
    _initializedAmount = true;
    _amountController.text =
        RupiahInputFormatter.format(draft.amount.toInt());
  }

  Future<void> _pickTime(SavingReminderDraft draft) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: draft.hour, minute: draft.minute),
    );
    if (picked != null) {
      ref
          .read(savingReminderControllerProvider.notifier)
          .setTime(picked.hour, picked.minute);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(savingReminderControllerProvider.notifier)
          .save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? AppStrings.savingSaved : AppStrings.savingSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(savingReminderControllerProvider.notifier)
          .deactivate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? AppStrings.savingDeactivated : AppStrings.savingSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _frequencyLabel(SavingFrequency frequency) {
    switch (frequency) {
      case SavingFrequency.daily:
        return AppStrings.savingFrequencyDaily;
      case SavingFrequency.weekly:
        return AppStrings.savingFrequencyWeekly;
      case SavingFrequency.monthly:
        return AppStrings.savingFrequencyMonthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(savingReminderControllerProvider);
    final goals = ref.watch(goalsListProvider);
    _syncAmountOnce(draft);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.savingReminderTitle)),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: goals.when(
              data: (goalList) => _Form(
                formKey: _formKey,
                draft: draft,
                goals: goalList,
                amountController: _amountController,
                saving: _saving,
                frequencyLabel: _frequencyLabel,
                onPickTime: () => _pickTime(draft),
                onSave: _save,
                onDeactivate: _deactivate,
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(goalsListProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends ConsumerWidget {
  const _Form({
    required this.formKey,
    required this.draft,
    required this.goals,
    required this.amountController,
    required this.saving,
    required this.frequencyLabel,
    required this.onPickTime,
    required this.onSave,
    required this.onDeactivate,
  });

  final GlobalKey<FormState> formKey;
  final SavingReminderDraft draft;
  final List<dynamic> goals;
  final TextEditingController amountController;
  final bool saving;
  final String Function(SavingFrequency) frequencyLabel;
  final VoidCallback onPickTime;
  final VoidCallback onSave;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(savingReminderControllerProvider.notifier);

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroCard(textTheme: textTheme),
            const SizedBox(height: 16),
            _StatusRow(
              draft: draft,
              textTheme: textTheme,
              onChanged: notifier.setEnabled,
            ),
            const SizedBox(height: 14),
            _Label(textTheme: textTheme, text: AppStrings.savingTargetLabel),
            const SizedBox(height: 6),
            goals.isEmpty
                ? _EmptyGoalCard(textTheme: textTheme)
                : DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: draft.goalId != null &&
                            goals.any((g) => g.id == draft.goalId)
                        ? draft.goalId
                        : null,
                    hint: const Text(AppStrings.savingTargetHint),
                    items: [
                      for (final g in goals)
                        DropdownMenuItem<String>(
                          value: g.id as String,
                          child: Text(
                            '${g.name} • '
                            '${CurrencyFormatter.formatCompact(g.currentAmount)}'
                            ' / ${CurrencyFormatter.formatCompact(g.targetAmount)}'
                            ' (${((g.progress as double) * 100).round()}%)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: notifier.setGoal,
                  ),
            const SizedBox(height: 14),
            _Label(textTheme: textTheme, text: AppStrings.savingAmountLabel),
            const SizedBox(height: 6),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: const InputDecoration(prefixText: 'Rp '),
              validator: (_) =>
                  draft.isAmountValid ? null : AppStrings.savingAmountRequired,
              onChanged: notifier.setAmountText,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.savingAmountHint,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            _Label(
              textTheme: textTheme,
              text: AppStrings.savingFrequencyLabel,
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<SavingFrequency>(
              isExpanded: true,
              initialValue: draft.frequency,
              items: [
                for (final f in SavingFrequency.values)
                  DropdownMenuItem(
                    value: f,
                    child: Text(frequencyLabel(f)),
                  ),
              ],
              onChanged: (f) {
                if (f != null) notifier.setFrequency(f);
              },
            ),
            const SizedBox(height: 14),
            if (draft.frequency == SavingFrequency.weekly) ...[
              _Label(textTheme: textTheme, text: AppStrings.savingWeekdayLabel),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: draft.weekday,
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(indonesianWeekdays[i - 1]),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) notifier.setWeekday(v);
                },
              ),
            ] else if (draft.frequency == SavingFrequency.monthly) ...[
              _Label(textTheme: textTheme, text: AppStrings.savingDateLabel),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: draft.dayOfMonth,
                items: [
                  for (var d = 1; d <= 31; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(
                        '$d ${AppStrings.savingEveryMonthSuffix}',
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) notifier.setDayOfMonth(v);
                },
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.savingShortMonthHint,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Text(
                AppStrings.savingDailyHint,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _Label(textTheme: textTheme, text: AppStrings.savingTimeLabel),
            const SizedBox(height: 6),
            InkWell(
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        draft.timeLabel,
                        style: textTheme.titleMedium,
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
            AppButton(
              label: AppStrings.savingSaveAction,
              isLoading: saving,
              onPressed: saving ? null : onSave,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: saving ? null : onDeactivate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.savingDeactivateAction,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.savingReminderTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.savingReminderIntro,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.draft,
    required this.textTheme,
    required this.onChanged,
  });

  final SavingReminderDraft draft;
  final TextTheme textTheme;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.savingStatusLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              draft.enabled
                  ? AppStrings.savingStatusActive
                  : AppStrings.savingStatusInactive,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: draft.enabled,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
        Text(
          AppStrings.savingStatusHint,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.textTheme, required this.text});

  final TextTheme textTheme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyGoalCard extends StatelessWidget {
  const _EmptyGoalCard({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.savingTargetEmpty,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          AppOutlineButton(
            label: AppStrings.savingTargetAction,
            onPressed: () => context.push(AppRoutes.goals),
          ),
        ],
      ),
    );
  }
}

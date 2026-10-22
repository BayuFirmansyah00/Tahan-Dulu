import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Edit Target: prefill + simpan perubahan (deposito tak tersentuh).
class GoalEditScreen extends ConsumerStatefulWidget {
  const GoalEditScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  GoalCategory? _category;
  DateTime? _date;

  /// Nama kustom tersimpan/diketik untuk kategori Lainnya.
  String _customName = '';
  bool _initialized = false;
  bool _attempted = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initFrom(FinancialGoal goal) {
    _nameController.text = goal.name;
    _amountController.text =
        RupiahInputFormatter.format(goal.targetAmount);
    _category = goal.category;
    _date = goal.deadline;
    // Muat nama kustom tersimpan: bila nama tersimpan bukan label
    // kategorinya, anggap kustom agar tidak hilang saat ke Lainnya.
    _customName = goal.category == GoalCategory.others
        ? goal.name
        : (goal.name != goalCategoryLabel(goal.category)
            ? goal.name
            : '');
    _initialized = true;
  }

  /// Ganti kategori saat edit: standar -> nama otomatis; Lainnya ->
  /// kembalikan nama kustom. Nominal & tanggal tidak tersentuh.
  void _selectCategory(GoalCategory category) {
    setState(() {
      _category = category;
      if (category == GoalCategory.others) {
        _nameController.text = _customName;
      } else {
        _nameController.text = goalCategoryLabel(category);
      }
    });
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _date != null && _date!.isAfter(tomorrow) ? _date! : tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(FinancialGoal goal) async {
    final amount = RupiahInputFormatter.parse(_amountController.text);
    final name = _nameController.text.trim();
    final date = _date;
    if (name.isEmpty ||
        amount <= 0 ||
        date == null ||
        !date.isAfter(DateTime.now()) ||
        _category == null) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(goalsControllerProvider.notifier)
          .updateGoalFields(
            id: goal.id,
            name: name,
            category: _category!,
            targetAmount: amount,
            targetDate: date,
            recurringAmount: goal.recurringAmount,
            frequency: goal.frequency,
            sourceAccountId: goal.sourceAccountId,
          );
      if (!mounted) return;
      if (ok) {
        context.pop();
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
    final goals = ref.watch(goalsListProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editGoalAction)),
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
                if (!_initialized) _initFrom(goal);
                final nameInvalid = _attempted &&
                    _nameController.text.trim().isEmpty;
                final amountInvalid = _attempted &&
                    RupiahInputFormatter.parse(
                          _amountController.text,
                        ) <=
                        0;
                final dateInvalid = _attempted &&
                    (_date == null ||
                        !_date!.isAfter(DateTime.now()));
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
                              AppStrings.goalCategoryLabel,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.85,
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              children: [
                                for (final category
                                    in GoalCategory.values)
                                  GoalCategoryTile(
                                    category: category,
                                    selected: _category == category,
                                    onTap: () =>
                                        _selectCategory(category),
                                  ),
                              ],
                            ),
                            if (_category != null &&
                                _category != GoalCategory.others) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.goalNameAutoNote,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 12),
                            GoalHeader(
                              category: _category ?? goal.category,
                              height: 130,
                            ),
                            const SizedBox(height: 16),
                            if (_category == null ||
                                _category == GoalCategory.others) ...[
                              AppTextField(
                                controller: _nameController,
                                label: AppStrings.goalName,
                                hint: AppStrings.goalNameHint,
                                onChanged: (v) => _customName = v,
                              ),
                              if (nameInvalid) ...[
                                const SizedBox(height: 6),
                                _FieldError(
                                  text: AppStrings.goalNameRequired,
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                            AppTextField(
                              controller: _amountController,
                              label: AppStrings.goalAmount,
                              hint: '0',
                              prefixText: 'Rp ',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                RupiahInputFormatter()
                              ],
                            ),
                            if (amountInvalid) ...[
                              const SizedBox(height: 6),
                              _FieldError(
                                text: AppStrings.goalAmountRequired,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.goalDate,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            GoalDateBox(
                              text: _date == null
                                  ? AppStrings.goalDateHint
                                  : DateFormatter.dayMonthYear(_date!),
                              onTap: _pickDate,
                            ),
                            if (dateInvalid) ...[
                              const SizedBox(height: 6),
                              _FieldError(
                                text: AppStrings.goalDateRequired,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: AppButton(
                        label: AppStrings.saveChanges,
                        isLoading: _saving,
                        onPressed:
                            _saving ? null : () => _save(goal),
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

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}

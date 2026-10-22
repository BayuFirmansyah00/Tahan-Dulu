import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Buat Target Baru langkah 1: kategori grid + nama + nominal + tanggal.
/// "Lanjutkan" validasi dulu; draf diteruskan (belum disimpan).
class GoalCreateScreen extends ConsumerStatefulWidget {
  const GoalCreateScreen({super.key});

  @override
  ConsumerState<GoalCreateScreen> createState() => _GoalCreateScreenState();
}

class _GoalCreateScreenState extends ConsumerState<GoalCreateScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  bool _attempted = false;

  /// Nama kustom yang diketik saat kategori Lainnya (dipertahankan
  /// selama form terbuka walau sempat pindah kategori).
  late String _customName;

  /// Pilih kategori: standar -> nama otomatis mengikuti label;
  /// Lainnya -> kembalikan nama kustom yang tersimpan.
  /// Nominal & tanggal tidak tersentuh.
  void _selectCategory(GoalCategory category) {
    final notifier = ref.read(goalsControllerProvider.notifier);
    notifier.setCategory(category);
    if (category == GoalCategory.others) {
      notifier.setName(_customName);
      _nameController.text = _customName;
    } else {
      final label = goalCategoryLabel(category);
      notifier.setName(label);
      _nameController.text = label;
    }
  }

  @override
  void initState() {
    super.initState();
    final draft = ref.read(goalsControllerProvider);
    _nameController = TextEditingController(text: draft.name);
    _customName =
        draft.category == GoalCategory.others ? draft.name : '';
    _amountController = TextEditingController(
      text: draft.targetAmount > 0
          ? RupiahInputFormatter.format(draft.targetAmount)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(tomorrow)
          ? current
          : tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) {
      ref.read(goalsControllerProvider.notifier).setTargetDate(picked);
    }
  }

  void _next() {
    if (!ref.read(goalsControllerProvider).isStepOneValid) {
      setState(() => _attempted = true);
      return;
    }
    context.push(AppRoutes.goalsSetup);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(goalsControllerProvider);
    final notifier = ref.read(goalsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createGoalTitle)),
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
                        Text(
                          AppStrings.createGoalQuestion,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.createGoalHint,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final category in GoalCategory.values)
                              GoalCategoryTile(
                                category: category,
                                selected: draft.category == category,
                                onTap: () => _selectCategory(category),
                              ),
                          ],
                        ),
                        if (draft.category != null &&
                            draft.category != GoalCategory.others) ...[
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.goalNameAutoNote,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                        if (draft.category != null) ...[
                          const SizedBox(height: 16),
                          GoalHeader(category: draft.category!),
                        ],
                        const SizedBox(height: 16),
                        if (draft.category == null ||
                            draft.category == GoalCategory.others) ...[
                          AppTextField(
                            controller: _nameController,
                            label: AppStrings.goalName,
                            hint: AppStrings.goalNameHint,
                            onChanged: (v) {
                              _customName = v;
                              notifier.setName(v);
                            },
                          ),
                          if (_attempted && !draft.isNameValid) ...[
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
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: notifier.setTargetAmountText,
                        ),
                        if (_attempted && !draft.isAmountValid) ...[
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
                          text: draft.targetDate == null
                              ? AppStrings.goalDateHint
                              : DateFormatter.dayMonthYear(
                                  draft.targetDate!,
                                ),
                          onTap: () => _pickDate(draft.targetDate),
                        ),
                        if (_attempted && !draft.isDateValid) ...[
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.continueAction,
                    onPressed: _next,
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

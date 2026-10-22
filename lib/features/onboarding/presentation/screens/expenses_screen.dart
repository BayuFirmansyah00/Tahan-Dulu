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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/recurring_expense.dart';
import '../providers/expenses_controller.dart';

/// Visual per kategori: aset 3D lokal + fallback outline + tint.
/// needs: rumah. transport: mobil. bills: kwitansi. shopping: tas.
/// others: tanpa aset cocok -> outline generik yang konsisten.
({String? asset, IconData icon, Color foreground, Color background})
    _visualOf(
  ExpenseCategory category,
) {
  switch (category) {
    case ExpenseCategory.needs:
      return (
        asset: AppAssets.obNeeds,
        icon: Icons.shopping_basket_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ExpenseCategory.transport:
      return (
        asset: AppAssets.obTransport,
        icon: Icons.directions_car_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ExpenseCategory.bills:
      return (
        asset: AppAssets.obBills,
        icon: Icons.receipt_long_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ExpenseCategory.shopping:
      return (
        asset: AppAssets.obShopping,
        icon: Icons.shopping_bag_outlined,
        foreground: AppColors.warning,
        background: const Color(0xFFFEF3C7),
      );
    case ExpenseCategory.others:
      return (
        asset: null,
        icon: Icons.category_outlined,
        foreground: AppColors.textSecondary,
        background: AppColors.surfaceVariant,
      );
  }
}

String _categoryLabel(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.needs:
      return AppStrings.catNeeds;
    case ExpenseCategory.transport:
      return AppStrings.catTransport;
    case ExpenseCategory.bills:
      return AppStrings.catBills;
    case ExpenseCategory.shopping:
      return AppStrings.catShopping;
    case ExpenseCategory.others:
      return AppStrings.catOthers;
  }
}

/// No.5 — Pengeluaran Rutin: daftar, tambah, ubah, hapus, ringkasan.
/// Sukses simpan -> No.7 (/onboarding/goals, placeholder tahap ini).
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(expensesControllerProvider.notifier).save();
    if (ok && context.mounted) {
      context.push(AppRoutes.onboardingGoals);
    }
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref, [
    RecurringExpense? expense,
  ]) async {
    final result = await showDialog<_ExpenseDialogResult>(
      context: context,
      builder: (context) => _ExpenseDialog(expense: expense),
    );
    if (result == null) return;
    final notifier = ref.read(expensesControllerProvider.notifier);
    if (result.deleted && result.expense != null) {
      notifier.removeExpense(result.expense!.id);
    } else if (result.expense != null) {
      if (expense == null) {
        notifier.addExpense(result.expense!);
      } else {
        notifier.updateExpense(result.expense!);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expensesControllerProvider);
    final textTheme = Theme.of(context).textTheme;

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
                              AppStrings.onboardingStep3,
                              style: textTheme.labelSmall,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 0.75,
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
                          AppStrings.expensesTitle,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.expensesSubtitle,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        for (final expense in state.expenses) ...[
                          _ExpenseCard(
                            expense: expense,
                            onTap: () =>
                                _openDialog(context, ref, expense),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openDialog(context, ref),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addExpense),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        if (state.expenses.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.noExpenseError,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _TotalCard(total: state.total),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.continueButton,
                    isLoading: state.isSaving,
                    onPressed:
                        state.canContinue ? () => _continue(context, ref) : null,
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

/// Card pengeluaran: icon kategori, nama, nominal, chevron edit.
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onTap});

  final RecurringExpense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = _visualOf(expense.category);
    final asset = visual.asset;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (asset != null)
              Image.asset(
                asset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackTile(visual: visual),
              )
            else
              _FallbackTile(visual: visual),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.name, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    _categoryLabel(expense.category),
                    style: textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCompact(expense.monthlyAmount),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile outline fallback bila tidak ada/gagal aset kategori.
class _FallbackTile extends StatelessWidget {
  const _FallbackTile({required this.visual});

  final ({
    String? asset,
    IconData icon,
    Color foreground,
    Color background,
  }) visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(visual.icon, color: visual.foreground, size: 24),
    );
  }
}

/// Ringkasan total + info pemakaian data.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.expenseTotal,
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${CurrencyFormatter.formatCompact(total)} '
                  '${AppStrings.perMonth}',
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
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.expenseSummaryInfo,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseDialogResult {
  const _ExpenseDialogResult({required this.deleted, this.expense});

  final bool deleted;
  final RecurringExpense? expense;
}

/// Dialog tambah/ubah: kategori, nama, nominal + Simpan/Hapus.
class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({this.expense});

  final RecurringExpense? expense;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  late ExpenseCategory _category;
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _nameError;
  String? _amountError;

  bool get isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _category = expense?.category ?? ExpenseCategory.needs;
    _nameController = TextEditingController(text: expense?.name ?? '');
    _amountController = TextEditingController(
      text: expense != null && expense.monthlyAmount > 0
          ? RupiahInputFormatter.format(expense.monthlyAmount)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = RupiahInputFormatter.parse(_amountController.text);
    setState(() {
      _nameError = name.isEmpty ? AppStrings.expenseNameRequired : null;
      _amountError =
          amount <= 0 ? AppStrings.expenseAmountRequired : null;
    });
    if (_nameError != null || _amountError != null) return;

    final existing = widget.expense;
    Navigator.of(context).pop(
      _ExpenseDialogResult(
        deleted: false,
        expense: RecurringExpense(
          id: existing?.id ??
              'exp-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          category: _category,
          monthlyAmount: amount,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteExpenseTitle),
        content: Text(
          '“${expense.name}” akan dihapus dari daftar.',
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
            child: const Text(AppStrings.deleteExpenseConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(
        _ExpenseDialogResult(deleted: true, expense: expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(
        isEdit ? AppStrings.editExpenseTitle : AppStrings.addExpenseTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.expenseCategory, style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ExpenseCategory.values)
                  _CategoryChip(
                    label: _categoryLabel(category),
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              label: AppStrings.expenseName,
              hint: AppStrings.expenseNameHint,
            ),
            if (_nameError != null) ...[
              const SizedBox(height: 6),
              _DialogError(text: _nameError!),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _amountController,
              label: AppStrings.expenseAmount,
              hint: '0',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
            ),
            if (_amountError != null) ...[
              const SizedBox(height: 6),
              _DialogError(text: _amountError!),
            ],
          ],
        ),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.deleteExpense),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.text});

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

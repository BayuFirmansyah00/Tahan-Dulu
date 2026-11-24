import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

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
({String? asset, IconData icon, Color foreground, Color background}) _visualOf(
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

String _placeholderForCategory(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.needs:
      return 'Belanja bulanan';
    case ExpenseCategory.transport:
      return 'Bensin motor';
    case ExpenseCategory.bills:
      return 'Listrik rumah';
    case ExpenseCategory.shopping:
      return 'Kebutuhan pribadi';
    case ExpenseCategory.others:
      return 'Nama pengeluaran';
  }
}

/// Tahap 4 — Pengeluaran rutin (Opsional):
/// Pengguna dapat mencatat tagihan/kebutuhan bulanan, atau memilih "Atur Nanti".
/// Sukses simpan / Atur Nanti -> tahap 5 (/onboarding/goals).
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(expensesControllerProvider.notifier).loadExisting();
      }
    });
  }

  Future<void> _continue() async {
    final ok = await ref.read(expensesControllerProvider.notifier).save();
    if (ok && mounted) {
      context.push(AppRoutes.onboardingGoals);
    }
  }

  void _skip() {
    context.push(AppRoutes.onboardingGoals);
  }

  Future<void> _openSheet([RecurringExpense? expense]) async {
    final result = await showGlassSheet<_ExpenseSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExpenseBottomSheet(expense: expense),
    );
    if (result == null || !mounted) return;
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

  Future<void> _deleteExpense(RecurringExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteExpenseTitle),
        content: Text('Hapus pengeluaran "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.deleteExpenseConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(expensesControllerProvider.notifier).removeExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: GlassBackdrop(child: SafeArea(
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
                        // Progress bar (4 dari 5 = 80%)
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
                                child: LinearProgressIndicator(
                                  value: 0.8,
                                  minHeight: 8,
                                  backgroundColor: context.palette.primaryContainer,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.palette.primary,
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
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tampilan Berdasarkan Keberadaan Data
                        if (state.expenses.isEmpty) ...[
                          // Empty State Modern Minimalis (Tanpa Error Merah)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 32,
                            ),
                            decoration: Glass.panel(context, radius: BorderRadius.circular(20)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: context.palette.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 32,
                                    color: context.palette.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppStrings.emptyExpensesTitle,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: context.palette.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.emptyExpensesSubtitle,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: context.palette.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () => _openSheet(),
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text(AppStrings.addExpenseAction),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.palette.primary,
                                    side: BorderSide(color: context.palette.primary),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Total Card Informatif
                          _TotalCard(total: state.total),
                          const SizedBox(height: 20),

                          // Daftar Pengeluaran Rutin
                          for (final expense in state.expenses) ...[
                            _ExpenseCard(
                              expense: expense,
                              onTap: () => _openSheet(expense),
                              onDelete: () => _deleteExpense(expense),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),

                          // Tombol Tambah Pengeluaran Lain
                          OutlinedButton.icon(
                            onPressed: () => _openSheet(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addAnotherExpenseAction),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.palette.primary,
                              side: BorderSide(color: context.palette.primary),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Tombol Navigasi Bawah (Responsif & SafeArea)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.expenses.isNotEmpty) ...[
                        AppButton(
                          label: AppStrings.continueButton,
                          isLoading: state.isSaving,
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 12),
                        AppOutlineButton(
                          label: AppStrings.setupLater,
                          onPressed: state.isSaving ? null : _skip,
                        ),
                      ] else ...[
                        AppButton(
                          label: AppStrings.setupLater,
                          onPressed: state.isSaving ? null : _skip,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

/// Card pengeluaran: icon kategori, nama, nominal, dan aksi edit/hapus.
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  final RecurringExpense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = _visualOf(expense.category);
    final asset = visual.asset;

    return Container(
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (asset != null)
                  Image.asset(
                    asset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _FallbackTile(visual: visual),
                  )
                else
                  _FallbackTile(visual: visual),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: visual.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _categoryLabel(expense.category),
                              style: textTheme.labelSmall?.copyWith(
                                color: visual.foreground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${CurrencyFormatter.formatCompact(expense.monthlyAmount)} ${AppStrings.perMonth}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.palette.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: context.palette.onSurfaceVariant,
                  tooltip: AppStrings.editExpenseTitle,
                  onPressed: onTap,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: AppStrings.deleteExpense,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile outline fallback bila tidak ada/gagal aset kategori.
class _FallbackTile extends StatelessWidget {
  const _FallbackTile({required this.visual});

  final ({String? asset, IconData icon, Color foreground, Color background})
  visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(visual.icon, color: visual.foreground, size: 22),
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
                    color: context.palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: context.palette.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.expenseSummaryInfo,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceVariant,
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

class _ExpenseSheetResult {
  const _ExpenseSheetResult({required this.deleted, this.expense});

  final bool deleted;
  final RecurringExpense? expense;
}

/// Modal bottom sheet modern untuk menambah / mengedit pengeluaran rutin.
class _ExpenseBottomSheet extends StatefulWidget {
  const _ExpenseBottomSheet({this.expense});

  final RecurringExpense? expense;

  @override
  State<_ExpenseBottomSheet> createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<_ExpenseBottomSheet> {
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

  void _onCategoryChanged(ExpenseCategory cat) {
    setState(() {
      _category = cat;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = RupiahInputFormatter.parse(_amountController.text);

    setState(() {
      _nameError = name.isEmpty ? AppStrings.expenseNameRequired : null;
      _amountError = amount <= 0 ? AppStrings.expenseAmountRequired : null;
    });

    if (_nameError != null || _amountError != null) return;

    final existing = widget.expense;
    Navigator.of(context).pop(
      _ExpenseSheetResult(
        deleted: false,
        expense: RecurringExpense(
          id: existing?.id ?? 'exp-${DateTime.now().millisecondsSinceEpoch}',
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
        content: Text('Hapus pengeluaran "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.deleteExpenseConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(
        _ExpenseSheetResult(deleted: true, expense: expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isNameFilled = _nameController.text.trim().isNotEmpty;
    final amount = RupiahInputFormatter.parse(_amountController.text);
    final isValid = isNameFilled && amount > 0;

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? AppStrings.editExpenseSheetTitle
                                  : AppStrings.addExpenseSheetTitle,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.palette.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.expenseSheetSubtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: context.palette.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isEdit)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: AppStrings.deleteExpense,
                          onPressed: _delete,
                        ),
                    ],
                  ),
                ),
                const Divider(),

                // Form Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pilihan Kategori
                      Text(
                        AppStrings.expenseCategory,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in ExpenseCategory.values)
                            ChoiceChip(
                              label: Text(_categoryLabel(cat)),
                              avatar: Icon(
                                _visualOf(cat).icon,
                                size: 16,
                                color: _category == cat
                                    ? Colors.white
                                    : context.palette.onSurfaceVariant,
                              ),
                              selected: _category == cat,
                              onSelected: (_) => _onCategoryChanged(cat),
                              selectedColor: context.palette.primary,
                              labelStyle: TextStyle(
                                color: _category == cat
                                    ? Colors.white
                                    : context.palette.onSurface,
                                fontWeight: _category == cat
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              backgroundColor: context.palette.surfaceContainerHighest,
                              side: BorderSide(
                                color: _category == cat
                                    ? context.palette.primary
                                    : context.palette.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Nama Pengeluaran
                      AppTextField(
                        controller: _nameController,
                        label: AppStrings.expenseName,
                        hint: _placeholderForCategory(_category),
                        validator: (_) => _nameError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Nominal Bulanan
                      AppTextField(
                        controller: _amountController,
                        label: AppStrings.expenseAmountLabel,
                        hint: '0',
                        prefixText: 'Rp ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        validator: (_) => _amountError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Aksi
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(AppStrings.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AppButton(
                              label: AppStrings.saveExpenseAction,
                              onPressed: isValid ? _save : null,
                            ),
                          ),
                        ],
                      ),
                    ],
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

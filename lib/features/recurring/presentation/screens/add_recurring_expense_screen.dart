import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/recurring_controller.dart';

/// Form tambah pengeluaran rutin / tagihan: judul, kategori, nominal,
/// frekuensi, tanggal jatuh tempo, dan instrumen (opsional).
class AddRecurringExpenseScreen extends ConsumerStatefulWidget {
  const AddRecurringExpenseScreen({super.key});

  @override
  ConsumerState<AddRecurringExpenseScreen> createState() =>
      _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState
    extends ConsumerState<AddRecurringExpenseScreen> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _nextDueDateController = TextEditingController();
  String _frequency = 'monthly';
  int? _instrumentId;
  List<FinancialAccount> _instruments = [];
  bool _loadingInstruments = true;
  bool _attempted = false;
  bool _saving = false;

  final List<String> _frequencies = const ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _loadInstruments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _nextDueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInstruments() async {
    final list = await ref.read(accountRepositoryProvider).getAccounts();
    if (!mounted) return;
    setState(() {
      _instruments = list;
      _loadingInstruments = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      _nextDueDateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    final title = _titleController.text;
    final category = _categoryController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final nextDueDate = _nextDueDateController.text;

    if (title.trim().isEmpty) {
      setState(() => _attempted = true);
      return;
    }
    if (category.trim().isEmpty) {
      setState(() => _attempted = true);
      return;
    }
    if (amount <= 0) {
      setState(() => _attempted = true);
      return;
    }
    if (nextDueDate.isEmpty) {
      setState(() => _attempted = true);
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await ref.read(recurringControllerProvider).addRecurringExpense(
            title: title,
            category: category,
            amount: amount,
            frequency: _frequency,
            nextDueDate: nextDueDate,
            instrumentId: _instrumentId,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
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
    final textTheme = Theme.of(context).textTheme;
    final showError = _attempted;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addRecurringExpenseTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.recurringExpenseTitle,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _titleController,
                    label: AppStrings.recurringExpenseName,
                    hint: AppStrings.recurringExpenseNameHint,
                  ),
                  if (showError && _titleController.text.trim().isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.recurringExpenseNameRequired,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _categoryController,
                    label: AppStrings.recurringExpenseCategory,
                    hint: AppStrings.recurringExpenseCategoryHint,
                  ),
                  if (showError && _categoryController.text.trim().isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.recurringExpenseCategoryRequired,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amountController,
                    label: AppStrings.recurringExpenseAmount,
                    hint: '0',
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                  ),
                  if (showError &&
                      (double.tryParse(_amountController.text) ?? 0) <= 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.recurringExpenseAmountRequired,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.recurringExpenseFrequency,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    items: _frequencies
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.recurringExpenseNextDueDate,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _nextDueDateController,
                    label: AppStrings.recurringExpenseNextDueDateLabel,
                    hint: 'YYYY-MM-DD',
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                  if (showError && _nextDueDateController.text.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.recurringExpenseNextDueDateRequired,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.recurringExpenseInstrument,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_loadingInstruments)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (_instruments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppStrings.recurringExpenseInstrumentEmpty,
                        style: textTheme.bodyMedium,
                      ),
                    )
                  else
                    DropdownButtonFormField<int?>(
                      initialValue: _instrumentId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(AppStrings.recurringExpenseInstrumentNone),
                        ),
                        ..._instruments.map((acc) => DropdownMenuItem<int?>(
                              value: int.tryParse(acc.id),
                              child: Text(
                                '${acc.name} (${acc.institutionName ?? '-'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (v) => setState(() => _instrumentId = v),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: AppButton(
          label: AppStrings.saveRecurringExpense,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }
}

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
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/models/financial_instrument.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../providers/transactions_controller.dart';
import '../utils/transaction_categories.dart';

AccountType _toAccountType(InstrumentType type) {
  switch (type) {
    case InstrumentType.bank:
      return AccountType.bank;
    case InstrumentType.digitalBank:
      return AccountType.digitalBank;
    case InstrumentType.ewallet:
      return AccountType.ewallet;
  }
}

String _accountTypeLabel(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return AppStrings.typeBank;
    case AccountType.digitalBank:
      return AppStrings.typeDigitalBank;
    case AccountType.ewallet:
      return AppStrings.typeEWallet;
  }
}

/// "BCA — Bank": nama akun + institusi bila ada dan berbeda, jika tidak
/// label jenis. Memudahkan bedakan beberapa rekening sejenis.
String _accountOptionLabel(FinancialAccount account) {
  final institution = account.institutionName?.trim() ?? '';
  final suffix = institution.isNotEmpty && institution != account.name
      ? institution
      : _accountTypeLabel(account.type);
  return '${account.name} — $suffix';
}

/// Form input manual: jenis, nominal, kategori, akun, tanggal, catatan.
/// [initialType] preset jenis dari shortcut dashboard (opsional).
/// "Periksa Transaksi" validasi dulu lalu ke layar review (draf utuh).
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.initialType});

  final TransactionType? initialType;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _feeController;
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    // Preset dari shortcut dashboard diterapkan setelah mount agar tidak
    // memodifikasi provider di dalam widget lifecycle.
    if (widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(transactionFormProvider.notifier)
            .setType(widget.initialType!);
      });
    }
    final draft = ref.read(transactionFormProvider);
    _amountController = TextEditingController(
      text: draft.amount > 0
          ? RupiahInputFormatter.format(draft.amount)
          : '',
    );
    _noteController = TextEditingController(text: draft.note);
    _feeController = TextEditingController(
      text: draft.fee > 0 ? RupiahInputFormatter.format(draft.fee) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime current) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) {
      ref.read(transactionFormProvider.notifier).setDate(picked);
    }
  }

  void _review(Set<String> accountIds, bool hasAccounts) {
    final draft = ref.read(transactionFormProvider);
    if (!hasAccounts ||
        !draft.isComplete(accountIds) ||
        !draft.isNetValid) {
      setState(() => _attempted = true);
      return;
    }
    context.push(AppRoutes.transactionReview);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.maybeWhen(
      data: (items) => items,
      orElse: () {
        final data =
            ref.watch(onboardingRepositoryProvider).getOnboardingData();
        return (data?.financialInstruments ?? const [])
            .map((e) => FinancialAccount(
                  id: e.id,
                  name: e.name,
                  type: _toAccountType(e.type),
                  balance: e.initialBalance,
                  institutionName: e.institutionName,
                ))
            .toList();
      },
    );
    final ids = {for (final e in accounts) e.id};
    final showAmountError = _attempted && !draft.isAmountValid;
    final showAccountError =
        _attempted && accounts.isNotEmpty && !draft.isAccountValid(ids);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addTransaction)),
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
                          AppStrings.formType,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TypeChip(
                                label: AppStrings.typeExpense,
                                type: TransactionType.expense,
                                selected: draft.type ==
                                    TransactionType.expense,
                                onTap: () => notifier.setType(
                                  TransactionType.expense,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TypeChip(
                                label: AppStrings.typeIncome,
                                type: TransactionType.income,
                                selected: draft.type ==
                                    TransactionType.income,
                                onTap: () => notifier.setType(
                                  TransactionType.income,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _amountController,
                          label: AppStrings.amountLabel,
                          hint: AppStrings.amountHint,
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: notifier.setAmountText,
                        ),
                        if (showAmountError) ...[
                          const SizedBox(height: 6),
                          _FieldError(text: AppStrings.amountRequired),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.categoryLabel,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final category
                                in categoriesFor(draft.type))
                              _CategoryTile(
                                category: category,
                                selected: draft.category == category,
                                onTap: () =>
                                    notifier.setCategory(category),
                              ),
                          ],
                        ),
                        if (_attempted && !draft.isCategoryValid) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                            text: AppStrings.categoryRequired,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.accountLabel,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (accounts.isEmpty)
                          _NoAccountBanner()
                        else
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: ids.contains(draft.accountId)
                                ? draft.accountId
                                : null,
                            hint:
                                const Text(AppStrings.accountHint),
                            items: [
                              for (final e in accounts)
                                DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    _accountOptionLabel(e),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: notifier.setAccount,
                          ),
                        if (showAccountError) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                            text: AppStrings.accountRequired,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.dateLabel,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _DateBox(
                          date: draft.date ?? DateTime.now(),
                          onTap: () =>
                              _pickDate(draft.date ?? DateTime.now()),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _noteController,
                          label: AppStrings.noteLabel,
                          hint: AppStrings.noteHint,
                          onChanged: notifier.setNote,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _feeController,
                          label: AppStrings.feeLabel,
                          hint: AppStrings.feeHint,
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: notifier.setFeeText,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.txFeeHelper,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_attempted && !draft.isNetValid) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                            text: AppStrings.feeExceedsIncome,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _TotalPreview(draft: draft),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.reviewAction,
                    onPressed: () =>
                        _review(ids, accounts.isNotEmpty),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final TransactionType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TransactionTypeIcon(type: type, size: 22),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CategoryIcon.forCategory(category, size: 44),
                if (selected)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              categoryLabel(category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                DateFormatter.dayMonthYear(date),
                style: Theme.of(context).textTheme.bodyLarge,
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

class _NoAccountBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.noAccountTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.noAccountHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Ringkasan total live: nominal ± biaya (R7). Selalu konsisten dengan
/// yang disimpan karena memakai getter draf yang sama.
class _TotalPreview extends StatelessWidget {
  const _TotalPreview({required this.draft});

  final TransactionDraft draft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = draft.type == TransactionType.income;
    final label =
        isIncome ? AppStrings.feeTotalIn : AppStrings.feeTotalOut;
    final color = isIncome ? AppColors.primary : AppColors.error;
    final sign = isIncome ? '+' : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textTheme.titleMedium),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$sign${CurrencyFormatter.formatCompact(draft.netAmount)}',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
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

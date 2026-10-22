import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/financial_instrument.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../providers/transactions_controller.dart';
import '../utils/transaction_categories.dart';

/// Review sebelum simpan: ringkasan draf + Edit (pop, input utuh).
/// Guard: draf tak lengkap -> kembali ke form.
class TransactionReviewScreen extends ConsumerStatefulWidget {
  const TransactionReviewScreen({super.key});

  @override
  ConsumerState<TransactionReviewScreen> createState() =>
      _TransactionReviewScreenState();
}

class _TransactionReviewScreenState
    extends ConsumerState<TransactionReviewScreen> {
  bool _submitting = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data =
          ref.read(onboardingRepositoryProvider).getOnboardingData();
      final instruments =
          data?.financialInstruments ?? const <FinancialInstrument>[];
      final ids = {for (final e in instruments) e.id};
      if (!ref.read(transactionFormProvider).isComplete(ids)) {
        if (mounted) context.go(AppRoutes.transactionAdd);
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _submitting = true;
      _saveFailed = false;
    });
    try {
      final ok =
          await ref.read(transactionFormProvider.notifier).save();
      if (!mounted) return;
      if (ok) {
        context.push(AppRoutes.transactionSuccess);
      } else {
        setState(() => _saveFailed = true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transactionFormProvider);
    final textTheme = Theme.of(context).textTheme;
    final data =
        ref.watch(onboardingRepositoryProvider).getOnboardingData();
    final accounts = {
      for (final e in data?.financialInstruments ?? const []) e.id: e.name,
    };
    final isIncome = draft.type == TransactionType.income;
    final amountColor =
        isIncome ? AppColors.primary : AppColors.error;
    final sign = isIncome ? '+' : '-';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reviewTitle)),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.reviewSubtitle,
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$sign${CurrencyFormatter.formatCompact(draft.netAmount)}',
                          style: textTheme.displayLarge?.copyWith(
                            color: amountColor,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Row(
                          label: AppStrings.amountLabel,
                          value: CurrencyFormatter.formatCompact(
                            draft.amount,
                          ),
                        ),
                        if (draft.fee > 0) ...[
                          _Row(
                            label: AppStrings.reviewFee,
                            value: CurrencyFormatter.formatCompact(
                              draft.fee,
                            ),
                          ),
                          _Row(
                            label: isIncome
                                ? AppStrings.feeTotalIn
                                : AppStrings.feeTotalOut,
                            value:
                                '$sign${CurrencyFormatter.formatCompact(draft.netAmount)}',
                          ),
                        ],
                        _Row(
                          label: AppStrings.reviewName,
                          value: draft.category == null
                              ? '-'
                              : categoryLabel(draft.category!),
                        ),
                        _Row(
                          label: AppStrings.reviewCategory,
                          value: draft.category == null
                              ? '-'
                              : categoryLabel(draft.category!),
                        ),
                        _Row(
                          label: isIncome
                              ? AppStrings.reviewReceiveIn
                              : AppStrings.reviewPayFrom,
                          value: accounts[draft.accountId] ?? '-',
                        ),
                        _Row(
                          label: AppStrings.reviewDate,
                          value: draft.date == null
                              ? '-'
                              : DateFormatter.dayMonthYear(draft.date!),
                        ),
                        _Row(
                          label: AppStrings.reviewSource,
                          value: AppStrings.reviewSourceManual,
                        ),
                        if (draft.note.trim().isNotEmpty)
                          _Row(
                            label: AppStrings.reviewNote,
                            value: draft.note.trim(),
                          ),
                        if (_saveFailed) ...[
                          const SizedBox(height: 12),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: AppOutlineButton(
                          label: AppStrings.editAction,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: AppStrings.saveTransaction,
                          isLoading: _submitting,
                          onPressed: _submitting ? null : _save,
                        ),
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

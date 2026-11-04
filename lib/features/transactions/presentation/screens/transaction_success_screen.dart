import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../providers/transactions_controller.dart';

/// Sukses simpan: ringkasan transaksi tersimpan + navigasi lanjutan.
/// Guard: tanpa data tersimpan -> kembali ke riwayat.
class TransactionSuccessScreen extends ConsumerStatefulWidget {
  const TransactionSuccessScreen({super.key});

  @override
  ConsumerState<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState
    extends ConsumerState<TransactionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(transactionFormProvider.notifier).lastSaved == null) {
        if (mounted) context.go(AppRoutes.transactions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        ref.watch(transactionFormProvider.notifier).lastSaved;
    final textTheme = Theme.of(context).textTheme;
    if (saved == null) return const Scaffold(body: SizedBox.shrink());

    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.maybeWhen(
      data: (items) => {for (final a in items) a.id: a.name},
      orElse: () {
        final data =
            ref.watch(onboardingRepositoryProvider).getOnboardingData();
        return {
          for (final e in data?.financialInstruments ?? const []) e.id: e.name,
        };
      },
    );
    final isIncome = saved.type == TransactionType.income;
    final amountColor =
        isIncome ? AppColors.primary : AppColors.error;
    final sign = isIncome ? '+' : '-';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const AppImageIcon(
                    assetPath: AppAssets.statusSuccess,
                    size: 88,
                    fallbackIcon: Icons.check_circle,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.successTitle,
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$sign${CurrencyFormatter.formatCompact(saved.amount)}',
                    style: textTheme.displayLarge?.copyWith(
                      color: amountColor,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Row(
                    label: AppStrings.reviewName,
                    value: saved.title,
                  ),
                  _Row(
                    label: AppStrings.reviewCategory,
                    value: saved.category ?? '-',
                  ),
                  _Row(
                    label: isIncome
                        ? AppStrings.reviewReceiveIn
                        : AppStrings.reviewPayFrom,
                    value: accounts[saved.accountId] ?? '-',
                  ),
                  _Row(
                    label: AppStrings.reviewDate,
                    value: DateFormatter.dayMonthYear(saved.date),
                  ),
                  if (saved.fee > 0)
                    _Row(
                      label: AppStrings.reviewFee,
                      value: CurrencyFormatter.formatCompact(saved.fee),
                    ),
                  if (saved.note != null && saved.note!.isNotEmpty)
                    _Row(
                      label: AppStrings.reviewNote,
                      value: saved.note!,
                    ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: AppStrings.seeTransactions,
                    onPressed: () => context.go(AppRoutes.transactions),
                  ),
                  const SizedBox(height: 12),
                  AppOutlineButton(
                    label: AppStrings.backToHome,
                    onPressed: () => context.go(AppRoutes.dashboard),
                  ),
                ],
              ),
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

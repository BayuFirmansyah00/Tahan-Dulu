import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../utils/account_ui.dart';

/// Detail akun: identitas, saldo saat ini (engine), transaksi terkait.
/// Transfer belum didukung model -> tombol memberi info tahap berikut.
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState
    extends ConsumerState<AccountDetailScreen> {
  bool _obscured = false;

  void _onNav(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.transactions);
      case 2:
        context.push(AppRoutes.transactions);
      case 3:
        context.push(AppRoutes.goals);
      case 4:
        context.push(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: SafeArea(
        child: _Body(
          accountId: widget.accountId,
          obscured: _obscured,
          onToggleObscure: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.accountId,
    required this.obscured,
    required this.onToggleObscure,
  });

  final String accountId;
  final bool obscured;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(accountsOverviewProvider);
    final transactions = ref.watch(transactionsProvider);

    if (overview is AsyncLoading || transactions is AsyncLoading) {
      return const AppLoading();
    }
    final overviewError =
        overview is AsyncError ? overview : null;
    final transactionsError =
        transactions is AsyncError ? transactions : null;
    if (overviewError != null) {
      return AppErrorState(
        onRetry: () => ref.invalidate(accountsOverviewProvider),
      );
    }
    if (transactionsError != null) {
      return AppErrorState(
        onRetry: () => ref.invalidate(transactionsProvider),
      );
    }
    final matches = overview.value?.where(
          (e) => e.account.id == accountId,
        ) ??
        const [];
    if (matches.isEmpty) {
      return const Center(child: Text(AppStrings.accountNotFound));
    }
    final item = matches.first;
    final txs = transactions.value
            ?.where((t) => t.accountId == accountId)
            .toList() ??
        const [];
    final textTheme = Theme.of(context).textTheme;
    final account = item.account;
    final visual = accountVisual(account.type);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      visual.icon,
                      color: visual.foreground,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: textTheme.headlineMedium),
                      Text(
                        accountTypeLabel(account.type),
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.primary,
                    onPressed: () => context.push(
                      '${AppRoutes.accounts}/$accountId/edit',
                    ),
                  ),
                ],
              ),
              if (account.institutionName != null &&
                  account.institutionName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  account.institutionName!,
                  style: textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.currentBalanceLabel,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                obscured
                    ? 'Rp••••••'
                    : CurrencyFormatter.formatCompact(item.currentBalance),
                style: textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              Text(
                AppStrings.recordedBalanceHint,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: AppStrings.transferAction,
                      icon: Icons.arrow_outward,
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text(AppStrings.transferComingSoon),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppOutlineButton(
                      label: AppStrings.editAccountTitle,
                      icon: Icons.edit_outlined,
                      onPressed: () => context.push(
                        '${AppRoutes.accounts}/$accountId/edit',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.recentTransactionsTitle,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '${AppRoutes.transactions}?account=$accountId',
                      ),
                      child: Text(
                        AppStrings.seeAllAction,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppStrings.emptyAccountTransactions,
                    style: textTheme.bodyMedium,
                  ),
                )
              else
                for (final t in txs.take(5))
                  _TxRow(transaction: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.transaction});

  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.primary : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: textTheme.titleMedium),
                Text(
                  DateFormatter.dayMonthYear(transaction.date),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}'
            '${CurrencyFormatter.formatCompact(transaction.amount)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

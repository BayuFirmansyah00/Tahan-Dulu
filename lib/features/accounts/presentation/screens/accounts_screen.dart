import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../utils/account_ui.dart';

/// Daftar akun: total hero, daftar, tambah, promo.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _obscured = false;

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

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(accountsOverviewProvider);
    final total = ref.watch(accountsTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.accountsTitle),
        actions: [
          IconButton(
            icon: const AppImageIcon(
              assetPath: AppAssets.statusInfo,
              size: 22,
              fallbackIcon: Icons.info_outline,
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.recordedBalanceHint)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: overview.when(
              data: (items) => _List(
                total: total,
                items: items,
                obscured: _obscured,
                onToggleObscure: () => setState(() => _obscured = !_obscured),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(accountsOverviewProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.total,
    required this.items,
    required this.obscured,
    required this.onToggleObscure,
  });

  final AsyncValue<double> total;
  final List<AccountOverview> items;
  final bool obscured;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalAdminFee = items
        .where((i) => i.account.adminFeeEnabled)
        .fold<double>(0.0, (sum, i) => sum + i.account.monthlyAdminFee);

    final spendableTotal = items
        .where((i) => i.account.type != AccountType.legacyCash)
        .fold<double>(0.0, (sum, i) => sum + i.currentBalance);

    final cashLegacyTotal = items
        .where((i) => i.account.type == AccountType.legacyCash)
        .fold<double>(0.0, (sum, i) => sum + i.currentBalance);

    final hasCashLegacy = items.any((i) => i.account.type == AccountType.legacyCash);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.accountsSubtitle, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          _TotalHero(
            total: total,
            obscured: obscured,
            onToggleObscure: onToggleObscure,
            spendableTotal: spendableTotal,
            cashLegacyTotal: cashLegacyTotal,
            hasCashLegacy: hasCashLegacy,
          ),
          if (totalAdminFee > 0) ...[
            const SizedBox(height: 12),
            _AdminFeeSummaryBanner(totalFee: totalAdminFee),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.accountsListTitle,
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (items.where((i) => i.account.type != AccountType.legacyCash).length >= 2) ...[
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.accountTransfer),
                      icon: const AppImageIcon(
                        assetPath: AppAssets.txTransfer,
                        size: 18,
                        fallbackIcon: Icons.swap_horiz_rounded,
                      ),
                      label: const Text(
                        AppStrings.transferAction,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.accountAdd),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      AppStrings.addAccount,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            _EmptyList()
          else
            for (final item in items) ...[
              _AccountCard(item: item),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 6),
          const _PromoCard(),
        ],
      ),
    );
  }
}

class _TotalHero extends StatelessWidget {
  const _TotalHero({
    required this.total,
    required this.obscured,
    required this.onToggleObscure,
    this.spendableTotal,
    this.cashLegacyTotal,
    this.hasCashLegacy = false,
  });

  final AsyncValue<double> total;
  final bool obscured;
  final VoidCallback onToggleObscure;
  final double? spendableTotal;
  final double? cashLegacyTotal;
  final bool hasCashLegacy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCashLegacy ? 'Total Aset Tercatat' : AppStrings.totalBalanceLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    total.when(
                      data: (value) => Text(
                        obscured
                            ? 'Rp••••••'
                            : CurrencyFormatter.formatCompact(value),
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      error: (_, _) => Text(
                        '-',
                        style: textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      AppStrings.recordedBalanceHint,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white,
                ),
                onPressed: onToggleObscure,
              ),
            ],
          ),
          if (hasCashLegacy && (cashLegacyTotal ?? 0) > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Siap Pakai: ${obscured ? 'Rp•••' : CurrencyFormatter.formatCompact(spendableTotal ?? 0)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uang Tunai: ${obscured ? 'Rp•••' : CurrencyFormatter.formatCompact(cashLegacyTotal ?? 0)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.item});

  final AccountOverview item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLegacy = item.account.type == AccountType.legacyCash;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.accounts}/${item.account.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLegacy ? const Color(0xFFFFEEBA) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            AccountProviderIcon(
              type: item.account.type,
              institutionName: item.account.institutionName,
              bankName: item.account.bankName,
              bankSlug: item.account.bankSlug,
              bankLogoUrl: item.account.bankLogoUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.account.name, style: textTheme.titleMedium),
                      ),
                      if (isLegacy) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFEEBA)),
                          ),
                          child: Text(
                            'Akun Lama',
                            style: textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF856404),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    isLegacy
                        ? 'Uang Tunai — Akun Lama'
                        : (item.account.bankName ?? accountTypeLabel(item.account.type)),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isLegacy ? const Color(0xFF856404) : null,
                      fontWeight: isLegacy ? FontWeight.w600 : null,
                    ),
                  ),
                  if (isLegacy) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Akun ini dipertahankan untuk menjaga saldo dan riwayat pencatatan sebelumnya. Akun Uang Tunai baru tidak lagi didukung.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (item.account.type == AccountType.bank ||
                      item.account.type == AccountType.digitalBank) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.account.adminFeeEnabled &&
                              item.account.monthlyAdminFee > 0
                          ? 'Biaya admin: ${CurrencyFormatter.formatCompact(item.account.monthlyAdminFee)}/bln (tgl ${item.account.adminFeeDay})'
                          : 'Bebas biaya admin',
                      style: textTheme.bodySmall?.copyWith(
                        color: item.account.adminFeeEnabled &&
                                item.account.monthlyAdminFee > 0
                            ? AppColors.textSecondary
                            : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatCompact(item.currentBalance),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const AppImageIcon(
              assetPath: AppAssets.navForward,
              size: 20,
              fallbackIcon: Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppEmptyState(
          title: AppStrings.emptyAccounts,
          subtitle: AppStrings.emptyAccountsHint,
          assetPath: AppAssets.txWallet,
          icon: Icons.account_balance_wallet_outlined,
        ),
        AppButton(
          label: AppStrings.addAccount,
          icon: Icons.add,
          onPressed: () => context.push(AppRoutes.accountAdd),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: AppImageIcon(
                assetPath: AppAssets.dashChart,
                size: 24,
                fallbackIcon: Icons.show_chart_outlined,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.promoTitle, style: textTheme.titleMedium),
                Text(AppStrings.promoSubtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
          const AppImageIcon(
            assetPath: AppAssets.navForward,
            size: 20,
            fallbackIcon: Icons.chevron_right,
          ),
        ],
      ),
    );
  }
}

class _AdminFeeSummaryBanner extends StatelessWidget {
  const _AdminFeeSummaryBanner({required this.totalFee});

  final double totalFee;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimasi Biaya Admin: ${CurrencyFormatter.formatCompact(totalFee)} / bln',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perkiraan total biaya administrasi dari rekening aktif. Nilai ini tidak otomatis memotong saldo.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

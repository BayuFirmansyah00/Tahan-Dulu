import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
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
            icon: const Icon(Icons.info_outline),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.recordedBalanceHint),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: _onNav,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: overview.when(
              data: (items) => _List(
                total: total,
                items: items,
                obscured: _obscured,
                onToggleObscure: () =>
                    setState(() => _obscured = !_obscured),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(accountsOverviewProvider)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.accountsSubtitle,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _TotalHero(
            total: total,
            obscured: obscured,
            onToggleObscure: onToggleObscure,
          ),
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
                  if (items.length >= 2) ...[
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.accountTransfer),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
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
  });

  final AsyncValue<double> total;
  final bool obscured;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.totalBalanceLabel,
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
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.item});

  final AccountOverview item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.accounts}/${item.account.id}',
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
                  Text(item.account.name, style: textTheme.titleMedium),
                  Text(
                    item.account.bankName ?? accountTypeLabel(item.account.type),
                    style: textTheme.bodyMedium,
                  ),
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

class _EmptyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppEmptyState(
          title: AppStrings.emptyAccounts,
          subtitle: AppStrings.emptyAccountsHint,
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
            child: const Icon(
              Icons.show_chart_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.promoTitle,
                  style: textTheme.titleMedium,
                ),
                Text(
                  AppStrings.promoSubtitle,
                  style: textTheme.bodyMedium,
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
    );
  }
}

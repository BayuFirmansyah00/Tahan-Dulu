import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_account.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/investment_controller.dart';
import '../widgets/investment_detail_sheet.dart';

/// Daftar portofolio investasi dengan opsi tambah baru.
class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
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
    final items = ref.watch(investmentsProvider);
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Scaffold(
      extendBody: useDarkGlass,
      extendBodyBehindAppBar: useDarkGlass,
      appBar: const AppAdaptiveAppBar(title: Text(AppStrings.investmentsTitle)),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: GlassBackdrop(child: SafeArea(
        bottom: !useDarkGlass,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: items.when(
              data: (list) => _List(items: list),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(investmentsProvider),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<FinancialAccount> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, useDarkGlass ? 100 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.investmentsSubtitle,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.investmentsListTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppAdaptiveOutlinedButton(
                  height: 38,
                  borderRadius: 19,
                  onPressed: () => context.push(AppRoutes.investmentAdd),
                  icon: const Icon(Icons.add, size: 18),
                  label: AppStrings.addInvestment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            _EmptyList()
          else
            for (final item in items) ...[
              _InvestmentCard(item: item),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({required this.item});

  final FinancialAccount item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => InvestmentDetailSheet.show(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: context.palette.primary,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: textTheme.titleMedium),
                  if (item.institutionName != null &&
                      item.institutionName!.isNotEmpty)
                    Text(
                      item.institutionName!,
                      style: textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatCompact(item.balance),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: context.palette.onSurfaceVariant,
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
          title: AppStrings.emptyInvestments,
          subtitle: AppStrings.emptyInvestmentsHint,
          icon: Icons.trending_up_outlined,
        ),
        AppButton(
          label: AppStrings.addInvestment,
          icon: Icons.add,
          onPressed: () {},
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/dashboard_data.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../onboarding/presentation/widgets/onboarding_invitation_popup.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../transactions/presentation/providers/transactions_controller.dart';
import '../widgets/dashboard_bottom_nav.dart';

/// Home Dashboard: hero aman harian, saldo, goals, TahanDulu, ringkasan.
/// Data dari onboarding + kalkulasi murni (bukan hardcode di widget).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    // Hangatkan cache ilustrasi agar hero/banner/piggy tampil utuh
    // tanpa pop-in (dan deterministik pada golden test).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final asset in [
        AppAssets.safeBudgetHero,
        AppAssets.tahanDuluBanner,
        AppAssets.goalsPiggy,
      ]) {
        precacheImage(AssetImage(asset), context).then(
          (_) {},
          onError: (_) {},
        );
      }
    });
  }

  void _onNav(int index, BuildContext context) {
    switch (index) {
      case 0:
        break;
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

  /// Shortcut pencatatan: reset draf lalu buka form dengan jenis terpilih.
  /// Hanya untuk jenis yang didukung form manual (pemasukan/pengeluaran).
  void _record(BuildContext context, TransactionType type) {
    ref.read(transactionFormProvider.notifier).reset();
    final value = type == TransactionType.income ? 'income' : 'expense';
    context.push('${AppRoutes.transactionAdd}?type=$value');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dashboardDataProvider);
    final recent = ref.watch(transactionsProvider).maybeWhen(
          data: (items) => items.take(3).toList(),
          orElse: () => const <AppTransaction>[],
        );

    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Scaffold(
      backgroundColor: context.canvasColor,
      extendBody: useDarkGlass,
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 0,
        onTap: (i) => _onNav(i, context),
      ),
      body: GlassBackdrop(child: SafeArea(
        bottom: !useDarkGlass,
        child: data.when(
          data: (d) => Stack(
            children: [
              _Body(
                data: d,
                recent: recent,
                obscured: _obscured,
                onToggleObscure: () =>
                    setState(() => _obscured = !_obscured),
                onNav: (i) => _onNav(i, context),
                onRecord: (t) => _record(context, t),
                onRefresh: () async {
                  ref.invalidate(dashboardDataProvider);
                  ref.invalidate(accountsProvider);
                  ref.invalidate(transactionsProvider);
                  ref.invalidate(recentTransactionsProvider);
                  ref.invalidate(currentBudgetProvider);
                  ref.invalidate(goalsProvider);
                  ref.invalidate(recurringExpensesProvider);
                },
              ),
              const OnboardingInvitationPopup(),
            ],
          ),
          loading: () => const AppLoading(),
          error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(dashboardDataProvider)),
        ),
      )),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.recent,
    required this.obscured,
    required this.onToggleObscure,
    required this.onNav,
    required this.onRecord,
    required this.onRefresh,
  });

  final DashboardData data;
  final List<AppTransaction> recent;
  final bool obscured;
  final VoidCallback onToggleObscure;
  final ValueChanged<int> onNav;
  final ValueChanged<TransactionType> onRecord;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            key: const PageStorageKey('dashboard_scroll_view'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              GlassDesignTokens.isDarkGlass(context) ? 100 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              _Header(data: data),
              const SizedBox(height: 12),
              if (data.isBridgeMode) ...[
                _BridgeModeBanner(data: data),
                const SizedBox(height: 12),
              ],
              GestureDetector(
                onTap: () => context.push(AppRoutes.reports),
                child: _HeroCard(data: data),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push(AppRoutes.accounts),
                child: _BalanceCard(
                  data: data,
                  obscured: obscured,
                  onToggleObscure: onToggleObscure,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      imageAsset: AppAssets.txArrowUp,
                      foreground: context.palette.primary,
                      background: context.palette.primaryContainer,
                      label: AppStrings.typeIncome,
                      onTap: () =>
                          onRecord(TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShortcutTile(
                      imageAsset: AppAssets.txArrowDown,
                      foreground: context.palette.error,
                      background: context.palette.errorContainer,
                      label: AppStrings.typeExpense,
                      onTap: () =>
                          onRecord(TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShortcutTile(
                      imageAsset: AppAssets.dashChart,
                      foreground: context.palette.secondary,
                      background: context.palette.secondaryContainer,
                      label: AppStrings.shortcutReport,
                      onTap: () => context.push(AppRoutes.reports),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionRow(
                title: AppStrings.goalsSection,
                action: AppStrings.dashboardSeeAll,
                onTap: () => context.push(AppRoutes.goals),
              ),
              const SizedBox(height: 8),
              for (final goal in data.goals) ...[
                _GoalRow(goal: goal),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
              _TahanDuluCard(data: data),
              const SizedBox(height: 16),
              _SectionRow(
                title: AppStrings.recentTransactionsTitle,
                action: AppStrings.seeAllAction,
                onTap: () => context.push(AppRoutes.transactions),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const AppEmptyState(
                  title: AppStrings.emptyTransactions,
                  subtitle: AppStrings.emptyTransactionsHint,
                  icon: Icons.receipt_long_outlined,
                )
              else
                for (final item in recent) ...[
                  _RecentTxRow(item: item),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 6),
              _SectionRow(
                title: AppStrings.monthlySummary,
                action: AppStrings.dashboardSeeReport,
                onTap: () => context.push(AppRoutes.reports),
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.arrow_downward,
                imageAsset: AppAssets.txArrowDown,
                foreground: context.palette.error,
                background: context.palette.errorContainer,
                label: AppStrings.expense,
                value:
                    CurrencyFormatter.formatCompact(data.actualMonthExpense),
                valueColor: context.palette.error,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.arrow_upward,
                imageAsset: AppAssets.txArrowUp,
                foreground: context.palette.primary,
                background: context.palette.primaryContainer,
                label: AppStrings.income,
                value:
                    CurrencyFormatter.formatCompact(data.actualMonthIncome),
                valueColor: context.palette.primary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final firstName = data.user.name.split(' ').first;
    final showInApp = ref.watch(showInAppNotificationsProvider);
    return Row(
      children: [
        AppAvatar(
          name: firstName,
          avatarUrl: data.user.avatarUrl,
          radius: 22,
          backgroundColor: context.palette.primaryContainer,
          foregroundColor: context.palette.primary,
          textStyle: textTheme.titleLarge?.copyWith(
            color: context.palette.primary,
            fontWeight: FontWeight.w800,
          ),
          onTap: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.dashboardGreeting,
                style: textTheme.labelMedium?.copyWith(
                  color: context.palette.onSurfaceVariant,
                ),
              ),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                AppStrings.dashboardSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GlassDesignTokens.isDarkGlass(context)
            ? Stack(
                children: [
                  AppAdaptiveIconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: AppStrings.notificationsTitle,
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  if (data.hasUnread && showInApp)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.palette.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.outlineVariant),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      tooltip: AppStrings.notificationsTitle,
                      color: context.palette.onSurface,
                      onPressed: () => context.push(AppRoutes.notifications),
                    ),
                    if (data.hasUnread && showInApp)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.palette.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        const SizedBox(width: 4),
        AppAdaptiveIconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: AppStrings.profileMenuApp,
          iconColor: context.palette.onSurfaceVariant,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xff254958), Color(0xff1d5d5a), Color(0xff32685d)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(flex: 7),
                  Expanded(
                    flex: 3,
                    child: Image.asset(
                      AppAssets.safeBudgetHero,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppStrings.safeTodayTitle,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (!data.hasActiveBudget) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.palette.surface.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Estimasi',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.formatCompact(
                              data.safeDaily,
                            ),
                            maxLines: 1,
                            style: textTheme.displayLarge?.copyWith(
                              color: data.isDeficit ||
                                      data.isTodayOverspent ||
                                      data.safeDaily < 0
                                  ? const Color(0xFFFFD2D2)
                                  : Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (data.isDeficit ||
                            data.isTodayOverspent ||
                            data.safeDaily < 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.safeDaily < 0
                                  ? AppStrings.todayDeficitBadge
                                  : AppStrings.todayOverspentBadge,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.safeEstimateHint,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.surface.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${AppStrings.remainingBudgetLabel} '
                                '${CurrencyFormatter.formatCompact(data.remainingFlexible)} >',
                                style: textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (data.daysRemaining > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: context.palette.surface.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${data.daysRemaining} hari lagi',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BridgeModeBanner extends StatelessWidget {
  const _BridgeModeBanner({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timelapse_rounded,
              color: context.palette.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.palette.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Masa Penyesuaian Anggaran',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Batas Transisi: ${CurrencyFormatter.formatCompact(data.periodBudgetCeiling ?? 0)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.palette.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batas anggaran disesuaikan khusus untuk masa transisi hingga siklus baru dimulai.',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.data,
    required this.obscured,
    required this.onToggleObscure,
  });

  final DashboardData data;
  final bool obscured;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!data.hasAccounts) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: Glass.panel(context, radius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.palette.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: context.palette.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada akun keuangan',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tambahkan rekening atau e-wallet untuk mulai mencatat saldo',
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.palette.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tambah',
                style: textTheme.labelSmall?.copyWith(
                  color: context.palette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Image.asset(
                  AppAssets.dashWallet,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.palette.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: context.palette.secondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.totalBalanceTitle,
                      style: textTheme.labelMedium?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      obscured
                          ? 'Rp••••••'
                          : CurrencyFormatter.formatCompact(data.totalBalance),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppStrings.balanceRecordedHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: obscured
                    ? AppStrings.showBalance
                    : AppStrings.hideBalance,
                color: context.palette.onSurfaceVariant,
                onPressed: onToggleObscure,
              ),
            ],
          ),
          if (data.hasCashLegacy) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.canvasColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.palette.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Siap Pakai: ${obscured ? 'Rp•••' : CurrencyFormatter.formatCompact(data.spendableBalance)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.warningFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tunai Lama: ${obscured ? 'Rp•••' : CurrencyFormatter.formatCompact(data.cashLegacyBalance)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: context.warningInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akun tunai lama dipertahankan. Rekonsiliasi ke rekening agar saldo tunai siap ditransaksikan.',
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceVariant,
                      fontSize: 10,
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

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.imageAsset,
    required this.foreground,
    required this.background,
    required this.label,
    required this.onTap,
  });

  final String imageAsset;
  final Color foreground;
  final Color background;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imageAsset,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Hari ini, 12:30" / "Kemarin, 18:20" / "1 Okt 2026, 08:00".
String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final hm = DateFormatter.hourMinute(date);
  if (DateFormatter.isSameDay(date, now)) {
    return '${AppStrings.recentToday}, $hm';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (DateFormatter.isSameDay(date, yesterday)) {
    return '${AppStrings.recentYesterday}, $hm';
  }
  return '${DateFormatter.dayMonthYear(date)}, $hm';
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = goal.progress.clamp(0.0, 1.0);
    final percent = '${(goal.progress * 100).round()}%';
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.goals}/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              _GoalThumb(goal: goal),
              const SizedBox(width: 12),              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.formatCompact(goal.currentAmount)} '
                      '/ ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    percent,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.palette.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: context.palette.primaryContainer,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          context.palette.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Thumbnail target via pemetaan ikon bersama.
class _GoalThumb extends StatelessWidget {
  const _GoalThumb({required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    return CategoryIcon.forGoal(goal.category, size: 52);
  }
}

class _TahanDuluCard extends StatelessWidget {
  const _TahanDuluCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = data.pendingCount == 0
        ? AppStrings.tahanDuluEmpty
        : '${data.pendingCount} ${AppStrings.pendingSuffix}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: context.palette.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.tahanDuluTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.tahanDuluBannerHint,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                AppAdaptiveElevatedButton(
                  backgroundColor: context.palette.tertiary,
                  foregroundColor: context.palette.onTertiary,
                  height: 40,
                  borderRadius: 20,
                  label: AppStrings.tahanDuluSee,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: () => context.push(AppRoutes.tahanDulu),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Image.asset(
              AppAssets.tahanDuluBanner,
              height: 200,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                alignment: Alignment.center,
                child: Icon(
                  Icons.shopping_cart_outlined,
                  color: context.warningInk,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({required this.item});

  final AppTransaction item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? context.palette.primary : context.palette.error;
    final sign = isIncome ? '+' : '-';
    return GestureDetector(
      onTap: () => context.push(AppRoutes.transactions),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CategoryIcon.forLabel(item.category, item.type, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.palette.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${item.category ?? (isIncome ? AppStrings.typeIncome : AppStrings.typeExpense)} \u2022 ${_relativeTime(item.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$sign${CurrencyFormatter.formatCompact(item.amount)}',
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
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    this.imageAsset,
    required this.foreground,
    required this.background,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String? imageAsset;
  final Color foreground;
  final Color background;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Row(
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset!,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: foreground, size: 18),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: textTheme.bodyLarge),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Analisis Pembelian: ringkasan + budget + kondisi + CTA simulasi.
/// Semua angka dari agregat aktual; estimasi berlabel jelas.
///
/// Tahap 46: ringkasan 3D, kartu budget cream, status dampak
/// hijau/amber/coral sesuai threshold lama, CTA kuning.
/// Threshold risiko dan rumus tidak diubah.
class TahanDuluAnalysisScreen extends ConsumerWidget {
  const TahanDuluAnalysisScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(purchaseAnalysisProvider(itemId));
    final textTheme = Theme.of(context).textTheme;

    return TahanDuluScaffold(
      title: AppStrings.reviewFirstTitle,
      bottomButton: AppButton(
        label: AppStrings.simulateImpactAction,
        backgroundColor: context.palette.tertiaryContainer,
        foregroundColor: context.palette.onSurface,
        onPressed: () =>
            context.push('${AppRoutes.tahanDulu}/$itemId/simulate'),
      ),
      child: analysis.when(
        data: (a) {
          if (a == null) {
            return const Center(child: Text(AppStrings.accountNotFound));
          }
          final percent = a.share == null ? null : (a.share! * 100).round();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.reviewFirstSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: context.palette.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (a.isBridgeMode) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.palette.secondaryContainer),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: context.palette.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.bridgeModeNotice ??
                                'Periode Transisi (Bridge Mode) aktif dengan plafon anggaran transisi.',
                            style: textTheme.bodySmall?.copyWith(
                              color: context.palette.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _RecommendationBanner(analysis: a),
                const SizedBox(height: 12),
                TdCard(
                  child: Row(
                    children: [
                      TdCategoryIcon(category: a.item.category, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.item.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: context.palette.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(a.item.price),
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                color: context.palette.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.tertiaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                productCategoryLabel(a.item.category),
                                style: textTheme.labelSmall?.copyWith(
                                  color: context.palette.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.tertiaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.palette.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const AppImageIcon(
                                      assetPath: AppAssets.txWallet,
                                      size: 18,
                                      fallbackIcon:
                                          Icons.account_balance_wallet_outlined,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        AppStrings.flexibleBudgetLabel,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: context.palette.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(a.flexible),
                                  style: textTheme.titleLarge?.copyWith(
                                    color: context.palette.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: context.palette.outlineVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const AppImageIcon(
                                      assetPath: AppAssets.instBank,
                                      size: 18,
                                      fallbackIcon: Icons.account_balance_outlined,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        a.hasCashLegacy ? 'Saldo Siap Pakai' : 'Total Saldo Rekening',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: context.palette.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.hasAccounts
                                      ? CurrencyFormatter.formatCompact(
                                          a.hasCashLegacy ? a.spendableBalance : a.totalLiquidBalance,
                                        )
                                      : 'Belum Ada',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: a.hasAccounts
                                        ? context.palette.onSurface
                                        : context.palette.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (percent != null) ...[
                        Text(
                          '${AppStrings.usesBudgetPrefix} $percent% '
                          '${AppStrings.budgetSuffixNote}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BurdenBar(share: a.share!),
                      ] else
                        Text(
                          AppStrings.safeEstimateDisclaimer,
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                      if (a.monthlyAdminFees > 0 || a.recurringExpenses > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.palette.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_note_outlined,
                                size: 16,
                                color: context.palette.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Kewajiban terjadwal: '
                                  '${a.monthlyAdminFees > 0 ? "Admin (${CurrencyFormatter.formatCompact(a.monthlyAdminFees)}) " : ""}'
                                  '${a.recurringExpenses > 0 ? "Rutin (${CurrencyFormatter.formatCompact(a.recurringExpenses)}) " : ""}'
                                  'tercatat terpisah & tidak memotong saldo langsung.',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: context.palette.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (a.hasCashLegacy &&
                          a.cashLegacyBalance > 0 &&
                          !a.balanceSufficient &&
                          a.totalLiquidBalance >= a.item.price) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.warningFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.warningFill),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: context.warningInk,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Saldo mencukupi di total aset, namun ${CurrencyFormatter.formatCompact(a.cashLegacyBalance)} berada di akun Uang Tunai lama. Rekonsiliasi ke rekening bank/e-wallet untuk siap transaksi.',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: context.warningInk,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SafeRow(safeDaily: a.safeDaily, remaining: a.flexible),
              ],
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          onRetry: () => ref.invalidate(purchaseAnalysisProvider(itemId)),
        ),
      ),
    );
  }
}

/// Banner rekomendasi keputusan pembelian terpadu (Fase 4C).
class _RecommendationBanner extends StatelessWidget {
  const _RecommendationBanner({required this.analysis});

  final PurchaseAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;
    final String assetPath;
    final IconData icon;

    if (analysis.isReady) {
      bg = context.palette.primaryContainer;
      border = context.palette.primary.withValues(alpha: 0.35);
      textColor = context.palette.primary;
      assetPath = AppAssets.statusSuccess;
      icon = Icons.check_circle_outline;
    } else if (analysis.isPostpone) {
      bg = context.palette.errorContainer;
      border = context.palette.error.withValues(alpha: 0.35);
      textColor = context.palette.error;
      assetPath = AppAssets.statusError;
      icon = Icons.error_outline;
    } else {
      bg = context.warningFill;
      border = context.warningInk.withValues(alpha: 0.35);
      textColor = context.warningInk;
      assetPath = AppAssets.statusWarning;
      icon = Icons.warning_amber_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImageIcon(
            assetPath: assetPath,
            size: 24,
            fallbackIcon: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.recommendationTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.recommendationReason.isNotEmpty
                      ? analysis.recommendationReason
                      : (analysis.isReady
                          ? 'Budget dan saldo mencukupi untuk pembelian ini.'
                          : 'Pertimbangkan kembali sebelum memutuskan membeli.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurface,
                        height: 1.3,
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

/// Bar kondisi: hijau <30%, amber <70%, merah sisanya + alasan.
/// Threshold lama dipertahankan — hanya styling diselaraskan.
class _BurdenBar extends StatelessWidget {
  const _BurdenBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (share < 0.3) {
      color = context.palette.primary;
    } else if (share < 0.7) {
      color = context.warningInk;
    } else {
      color = context.palette.error;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: share.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: const Color(0xFFF3EDDA),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _SafeRow extends StatelessWidget {
  const _SafeRow({required this.safeDaily, required this.remaining});

  final double safeDaily;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.afterBuyTitle,
            style: textTheme.titleMedium?.copyWith(
              color: context.palette.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const AppImageIcon(
                      assetPath: AppAssets.instBank,
                      size: 18,
                      fallbackIcon: Icons.payments_outlined,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.safeTodayShort,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  CurrencyFormatter.formatCompact(safeDaily),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.palette.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const AppImageIcon(
                      assetPath: AppAssets.tdPieChart,
                      size: 18,
                      fallbackIcon: Icons.pie_chart_outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.remainingBudgetAfter,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  CurrencyFormatter.formatCompact(remaining),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.palette.onSurface,
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

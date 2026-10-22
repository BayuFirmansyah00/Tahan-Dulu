import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
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
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
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
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
                ),
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
                                color: TdColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(a.item.price),
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                color: TdColors.navy,
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
                                color: TdColors.highlight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                productCategoryLabel(a.item.category),
                                style: textTheme.labelSmall?.copyWith(
                                  color: TdColors.navy,
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
                    color: TdColors.creamCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TdColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: TdColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.flexibleBudgetLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                color: TdColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatCompact(a.flexible),
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          color: TdColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (percent != null) ...[
                        Text(
                          '${AppStrings.usesBudgetPrefix} $percent% '
                          '${AppStrings.budgetSuffixNote}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: TdColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BurdenBar(share: a.share!),
                      ] else
                        Text(
                          AppStrings.safeEstimateDisclaimer,
                          style: textTheme.bodyMedium?.copyWith(
                            color: TdColors.slate,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (percent != null) ...[
                  _ImpactBanner(share: a.share!),
                  const SizedBox(height: 12),
                ],
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

/// Bar kondisi: hijau <30%, amber <70%, merah sisanya + alasan.
/// Threshold lama dipertahankan — hanya styling diselaraskan.
class _BurdenBar extends StatelessWidget {
  const _BurdenBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (share < 0.3) {
      color = TdColors.success;
    } else if (share < 0.7) {
      color = TdColors.warning;
    } else {
      color = TdColors.danger;
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

/// Banner status dampak dengan hierarki jelas.
class _ImpactBanner extends StatelessWidget {
  const _ImpactBanner({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;
    if (share < 0.3) {
      bg = TdColors.successBg;
      fg = TdColors.success;
      icon = Icons.check_circle_outline;
      label = 'Ringan untuk budget fleksibelmu.';
    } else if (share < 0.7) {
      bg = TdColors.warningBg;
      fg = TdColors.warning;
      icon = Icons.warning_amber_outlined;
      label = 'Cukup besar — pikir matang sebelum lanjut.';
    } else {
      bg = TdColors.dangerBg;
      fg = TdColors.danger;
      icon = Icons.error_outline;
      label = 'Berat untuk budget fleksibelmu.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.safeEstimateDisclaimer,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: TdColors.slate),
                ),
              ],
            ),
          ),
        ],
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
              color: TdColors.navy,
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
                    const Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: TdColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.safeTodayShort,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TdColors.slate,
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
                    color: TdColors.navy,
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
                    const Icon(
                      Icons.pie_chart_outline,
                      size: 18,
                      color: TdColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.remainingBudgetAfter,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TdColors.slate,
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
                    color: TdColors.navy,
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

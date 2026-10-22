import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/finance_math.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Simulasi "Kalau saya beli?": kini vs sesudah (read-only).
/// Tidak menulis transaksi/saldo; murni estimasi tampilan.
///
/// Tahap 46: kartu putih border tipis aksen cream, perubahan nominal
/// disorot jelas tanpa cat merah seluruh halaman, CTA kuning.
/// Rumus simulasi tidak diubah.
class TahanDuluSimulateScreen extends ConsumerWidget {
  const TahanDuluSimulateScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(purchaseAnalysisProvider(itemId));
    final textTheme = Theme.of(context).textTheme;

    return TahanDuluScaffold(
      title: AppStrings.tahanDuluSimulateTitle,
      bottomButton: AppButton(
        label: AppStrings.waitDurationLabel,
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
        onPressed: () => context.push('${AppRoutes.tahanDulu}/$itemId/wait'),
      ),
      child: analysis.when(
        data: (a) {
          if (a == null) {
            return const Center(child: Text(AppStrings.accountNotFound));
          }
          final afterFlexible = a.flexible - a.item.price;
          final afterSafe = safeDailySpending(remaining: afterFlexible);
          final flexDown = afterFlexible < a.flexible;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: TdHeroImage(
                    asset: TdHeaderArt.simulate,
                    fallbackAsset:
                        'assets/illustrations/illustration_perbandingan.png',
                    height: 120,
                    width: 210,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.simulateSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.currentStateTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _StateCard(
                  flexible: a.flexible,
                  goalCurrent: a.goalCurrent,
                  goalName: a.goalName,
                  safeDaily: a.safeDaily,
                  delayDays: null,
                  highlightDelta: false,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.afterBuyStateTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _StateCard(
                  flexible: afterFlexible,
                  goalCurrent: a.goalCurrent,
                  goalName: a.goalName,
                  safeDaily: afterSafe,
                  delayDays: a.delayDays,
                  highlightDelta: true,
                  risky: flexDown && afterFlexible < 0,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TdColors.creamCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TdColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: TdColors.slate,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.safeEstimateDisclaimer,
                          style: textTheme.bodyMedium?.copyWith(
                            color: TdColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.flexible,
    required this.goalCurrent,
    required this.goalName,
    required this.safeDaily,
    required this.delayDays,
    required this.highlightDelta,
    this.risky = false,
  });

  final double flexible;
  final double? goalCurrent;
  final String? goalName;
  final double safeDaily;
  final int? delayDays;
  final bool highlightDelta;
  final bool risky;

  @override
  Widget build(BuildContext context) {
    return TdCard(
      color: highlightDelta ? TdColors.creamCard : TdColors.card,
      child: Column(
        children: [
          _Row(
            label: AppStrings.flexibleBudgetLabel,
            value: CurrencyFormatter.formatCompact(flexible),
            icon: Icons.account_balance_wallet_outlined,
            emphasize: highlightDelta,
            alert: risky,
          ),
          if (goalName != null)
            _Row(
              label: '${AppStrings.goalImpactLabel} ($goalName!)',
              value: goalCurrent == null
                  ? '-'
                  : CurrencyFormatter.formatCompact(goalCurrent!),
              icon: Icons.flag_outlined,
            ),
          _Row(
            label: AppStrings.dailyBudgetLabel,
            value: CurrencyFormatter.formatCompact(safeDaily),
            icon: Icons.payments_outlined,
            emphasize: highlightDelta,
            alert: risky,
          ),
          if (delayDays != null)
            _Row(
              label: AppStrings.nextBudgetLabel,
              value:
                  '${AppStrings.delayEstimatePrefix}$delayDays ${AppStrings.daySuffix}',
              icon: Icons.schedule_outlined,
              emphasize: true,
              alert: risky,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
    this.alert = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 18, color: TdColors.slate),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
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
            child: Container(
              padding: emphasize
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
                  : EdgeInsets.zero,
              decoration: emphasize
                  ? BoxDecoration(
                      color: alert ? TdColors.dangerBg : TdColors.highlight,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: alert ? TdColors.danger : TdColors.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

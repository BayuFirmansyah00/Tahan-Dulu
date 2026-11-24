import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/budget_controller.dart';

/// Halaman 3 Onboarding — Atur Anggaran Bulanan (50/5/30/15).
/// Menetapkan alokasi anggaran awal pengguna tanpa membuat transaksi atau
/// mengubah saldo rekening.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(budgetControllerProvider.notifier).loadExisting();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetControllerProvider);
    final controller = ref.read(budgetControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // App Bar / Back Button & Step Indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.palette.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: context.palette.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tahap 3 dari 5: anggaran bulanan.
                          Row(
                            children: [
                              Text(
                                AppStrings.onboardingStep3,
                                style: textTheme.labelSmall?.copyWith(
                                  color: context.palette.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: 0.6,
                                    minHeight: 8,
                                    backgroundColor: isDark
                                        ? context
                                              .palette
                                              .surfaceContainerHighest
                                        : const Color(0xFFDCFCE7),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF16A34A),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Atur Anggaran Bulanan',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bagi penghasilanmu ke dalam 4 pos alokasi keuangan sesuai rekomendasi TahanDulu.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: context.palette.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Kartu ringkasan penghasilan acuan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        context.palette.surfaceContainerHighest,
                                        context.palette.surface,
                                      ]
                                    : const [Color(0xFFF0FDF4), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? context.palette.outlineVariant
                                    : const Color(0xFFDCFCE7),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF16A34A,
                                  ).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Penghasilan Utama Bulanan',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .palette
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            CurrencyFormatter.format(
                                              state.monthlyIncome.toDouble(),
                                            ),
                                            style: textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                  fontSize: 22,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Image.asset(
                                          AppAssets.ob3dWallet,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.contain,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).maybePop();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? context
                                                          .palette
                                                          .surfaceContainerHighest
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDark
                                                      ? context.palette.outline
                                                      : const Color(0xFFE2E8F0),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 14,
                                                color: context
                                                    .palette
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? context.palette.surface.withValues(
                                            alpha: 0.5,
                                          )
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? context.palette.outlineVariant
                                                .withValues(alpha: 0.4)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: context.palette.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Alokasi ini adalah batas rencana anggaran belanja dan tujuan keuangan, bukan transaksi otomatis.',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: context
                                                .palette
                                                .onSurfaceVariant,
                                            fontSize: 11,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4 Kategori Alokasi
                          _CategoryAllocationCard(
                            title: 'Kebutuhan Pokok',
                            description:
                                'Makan, transportasi, sewa, tagihan listrik & air, dan kebutuhan primer.',
                            percentage: state.kebutuhanPokok,
                            amount: state.amountKebutuhanPokok,
                            assetPath: AppAssets.ob3dNeeds,
                            accentColor: const Color(0xFF16A34A),
                            badgeBgColor: const Color(0xFFDCFCE7),
                            badgeTextColor: const Color(0xFF16A34A),
                            onChanged: controller.updateKebutuhanPokok,
                          ),
                          const SizedBox(height: 14),

                          _CategoryAllocationCard(
                            title: 'Pengeluaran Bebas',
                            description:
                                'Hiburan, rekreasi, belanja keinginan, dan nongkrong fleksibel.',
                            percentage: state.pengeluaranBebas,
                            amount: state.amountPengeluaranBebas,
                            assetPath: AppAssets.ob3dFlexible,
                            accentColor: const Color(0xFFF59E0B),
                            badgeBgColor: const Color(0xFFFEF3C7),
                            badgeTextColor: const Color(0xFFD97706),
                            onChanged: controller.updatePengeluaranBebas,
                          ),
                          const SizedBox(height: 14),

                          _CategoryAllocationCard(
                            title: 'Investasi dan Tabungan',
                            description:
                                'Akumulasi masa depan, reksadana, saham, dan tabungan jangka panjang.',
                            percentage: state.investasiTabungan,
                            amount: state.amountInvestasiTabungan,
                            assetPath: AppAssets.ob3dInvestment,
                            accentColor: const Color(0xFF3B82F6),
                            badgeBgColor: const Color(0xFFDBEAFE),
                            badgeTextColor: const Color(0xFF2563EB),
                            onChanged: controller.updateInvestasiTabungan,
                          ),
                          const SizedBox(height: 14),

                          _CategoryAllocationCard(
                            title: 'Dana Darurat',
                            description:
                                'Cadangan likuid untuk kondisi mendesak dan pengeluaran tak terduga.',
                            percentage: state.danaDarurat,
                            amount: state.amountDanaDarurat,
                            assetPath: AppAssets.ob3dEmergency,
                            accentColor: const Color(0xFF10B981),
                            badgeBgColor: const Color(0xFFD1FAE5),
                            badgeTextColor: const Color(0xFF059669),
                            onChanged: controller.updateDanaDarurat,
                          ),
                          const SizedBox(height: 20),

                          // Ringkasan Status Total Persentase & Sisa
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: state.isExceeding100
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.08)
                                  : (isDark
                                        ? context.palette.surface
                                        : const Color(0xFFF9FAFB)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: state.isExceeding100
                                    ? Theme.of(context).colorScheme.error
                                    : (isDark
                                          ? context.palette.outlineVariant
                                          : const Color(0xFFE2E8F0)),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AppAssets.ob3dTotalAllocation,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Total Alokasi',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: context
                                                            .palette
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                '${state.totalPercentage.toStringAsFixed(0)}% / 100%',
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                      color:
                                                          state.isExceeding100
                                                          ? Theme.of(
                                                              context,
                                                            ).colorScheme.error
                                                          : (state.totalPercentage ==
                                                                    100.0
                                                                ? const Color(
                                                                    0xFF16A34A,
                                                                  )
                                                                : context
                                                                      .palette
                                                                      .onSurface),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Total Nominal Dialokasikan',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .palette
                                                      .onSurfaceVariant,
                                                  fontSize: 11.5,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.format(
                                              state.totalAllocatedAmount
                                                  .toDouble(),
                                            ),
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.remainingPercentage > 0 &&
                                    !state.isExceeding100) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sisa Belum Dialokasikan:',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFFB45309),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '${state.remainingPercentage.toStringAsFixed(0)}% (${CurrencyFormatter.format(state.remainingAmount.toDouble())})',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFFB45309),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (state.isExceeding100) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Total alokasi melebihi 100%. Kurangi persentase kategori lain.',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tombol Reset ke Rekomendasi
                          OutlinedButton.icon(
                            onPressed: controller.resetToDefault,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(
                              'Reset ke Rekomendasi (50/5/30/15)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16A34A),
                              side: const BorderSide(
                                color: Color(0xFF16A34A),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Bottom Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: AppButton(
                      label: 'Lanjut →',
                      isLoading: state.isSaving,
                      onPressed: state.isValid && !state.isSaving
                          ? () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await controller.saveBudget();
                              if (ok) {
                                if (context.mounted) {
                                  context.push(AppRoutes.onboardingExpenses);
                                }
                              } else {
                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ref
                                                .read(budgetControllerProvider)
                                                .errorMessage ??
                                            AppStrings.saveFailed,
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
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

class _CategoryAllocationCard extends StatelessWidget {
  const _CategoryAllocationCard({
    required this.title,
    required this.description,
    required this.percentage,
    required this.amount,
    required this.assetPath,
    required this.accentColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.onChanged,
  });

  final String title;
  final String description;
  final double percentage;
  final int amount;
  final String assetPath;
  final Color accentColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? context.palette.outlineVariant
              : const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? accentColor.withValues(alpha: 0.2)
                                : badgeBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? accentColor : badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nominal Alokasi:',
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount.toDouble()),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: isDark
                  ? accentColor.withValues(alpha: 0.18)
                  : const Color(0xFFE2E8F0),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 9,
                elevation: 2,
              ),
            ),
            child: Slider(
              value: percentage.clamp(0.0, 100.0),
              min: 0,
              max: 100,
              divisions: 20, // step 5%
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

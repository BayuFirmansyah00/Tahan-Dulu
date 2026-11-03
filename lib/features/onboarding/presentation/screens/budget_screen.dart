import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/budget_controller.dart';

/// Halaman 3 Onboarding — Atur Anggaran Bulanan (50/5/30/15).
/// Menetapkan alokasi anggaran awal pengguna tanpa membuat transaksi atau
/// mengubah saldo rekening.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetControllerProvider);
    final controller = ref.read(budgetControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bar 3 dari 3
                        Row(
                          children: [
                            Text(
                              '3 dari 3',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 1.0,
                                  minHeight: 8,
                                  backgroundColor: AppColors.primarySoft,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Atur Anggaran Bulanan',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bagi penghasilanmu ke dalam 4 pos alokasi keuangan sesuai rekomendasi TahanDulu.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Kartu ringkasan penghasilan acuan
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Penghasilan Utama Bulanan',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  state.monthlyIncome.toDouble(),
                                ),
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Alokasi ini adalah batas rencana anggaran belanja dan tujuan keuangan, bukan transaksi otomatis.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
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
                          icon: Icons.home_outlined,
                          accentColor: AppColors.primary,
                          onChanged: controller.updateKebutuhanPokok,
                        ),
                        const SizedBox(height: 12),

                        _CategoryAllocationCard(
                          title: 'Pengeluaran Bebas',
                          description:
                              'Hiburan, rekreasi, belanja keinginan, dan nongkrong fleksibel.',
                          percentage: state.pengeluaranBebas,
                          amount: state.amountPengeluaranBebas,
                          icon: Icons.coffee_outlined,
                          accentColor: const Color(0xFFF59E0B),
                          onChanged: controller.updatePengeluaranBebas,
                        ),
                        const SizedBox(height: 12),

                        _CategoryAllocationCard(
                          title: 'Investasi dan Tabungan',
                          description:
                              'Akumulasi masa depan, reksadana, saham, dan tabungan jangka panjang.',
                          percentage: state.investasiTabungan,
                          amount: state.amountInvestasiTabungan,
                          icon: Icons.trending_up_outlined,
                          accentColor: const Color(0xFF3B82F6),
                          onChanged: controller.updateInvestasiTabungan,
                        ),
                        const SizedBox(height: 12),

                        _CategoryAllocationCard(
                          title: 'Dana Darurat',
                          description:
                              'Cadangan likuid untuk kondisi mendesak dan pengeluaran tak terduga.',
                          percentage: state.danaDarurat,
                          amount: state.amountDanaDarurat,
                          icon: Icons.shield_outlined,
                          accentColor: const Color(0xFF10B981),
                          onChanged: controller.updateDanaDarurat,
                        ),
                        const SizedBox(height: 20),

                        // Ringkasan Status Total Persentase & Sisa
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: state.isExceeding100
                                ? Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: state.isExceeding100
                                  ? Theme.of(context).colorScheme.error
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Alokasi:',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${state.totalPercentage.toStringAsFixed(0)}% / 100%',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: state.isExceeding100
                                          ? Theme.of(context).colorScheme.error
                                          : (state.totalPercentage == 100.0
                                              ? AppColors.primary
                                              : AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total Nominal Dialokasikan:',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      state.totalAllocatedAmount.toDouble(),
                                    ),
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (state.remainingPercentage > 0 &&
                                  !state.isExceeding100) ...[
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Sisa Belum Dialokasikan:',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${state.remainingPercentage.toStringAsFixed(0)}% (${CurrencyFormatter.format(state.remainingAmount.toDouble())})',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (state.isExceeding100) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Total alokasi melebihi 100%. Kurangi persentase kategori lain.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: controller.resetToDefault,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    'Reset ke Rekomendasi (50/5/30/15)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: 'Selesaikan & Masuk Dashboard',
                    isLoading: state.isSaving,
                    onPressed: state.isValid && !state.isSaving
                        ? () async {
                            final router = GoRouter.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await controller.saveBudget();
                            if (ok) {
                              router.go(AppRoutes.dashboard);
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.errorMessage ??
                                        AppStrings.saveFailed,
                                  ),
                                ),
                              );
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
    );
  }
}

class _CategoryAllocationCard extends StatelessWidget {
  const _CategoryAllocationCard({
    required this.title,
    required this.description,
    required this.percentage,
    required this.amount,
    required this.icon,
    required this.accentColor,
    required this.onChanged,
  });

  final String title;
  final String description;
  final double percentage;
  final int amount;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nominal Alokasi:',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.format(amount.toDouble()),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.15),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: percentage,
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

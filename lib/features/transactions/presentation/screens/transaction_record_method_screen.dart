import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/transactions_controller.dart';

/// Halaman pemilihan metode pencatatan transaksi TahanDulu:
/// 1. Input Manual
/// 2. Input Suara
/// 3. Scan Struk
///
/// Seluruh metode merupakan gerbang masuk yang terintegrasi dengan
/// sistem transaksi TahanDulu dan backend Laravel.
class TransactionRecordMethodScreen extends ConsumerWidget {
  const TransactionRecordMethodScreen({super.key});

  void _onManualSelected(BuildContext context, WidgetRef ref) {
    ref.read(transactionFormProvider.notifier).reset();
    context.push(AppRoutes.transactionAdd);
  }

  void _onVoiceSelected(BuildContext context) {
    context.push(AppRoutes.transactionVoice);
  }

  void _onScanSelected(BuildContext context) {
    context.push(AppRoutes.transactionScan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Pilih Metode Catat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bagaimana kamu ingin mencatat transaksi?',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih salah satu metode di bawah ini untuk mencatat keuanganmu secara cepat, akurat, dan terkontrol.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Input Manual
                  _MethodCard(
                    title: 'Input Manual',
                    description:
                        'Catat pemasukan atau pengeluaran secara langsung dengan formulir lengkap.',
                    icon: Icons.edit_note_rounded,
                    iconColor: AppColors.primary,
                    iconBackground: AppColors.primarySoft,
                    badgeText: 'Standar',
                    onTap: () => _onManualSelected(context, ref),
                  ),
                  const SizedBox(height: 16),

                  // 2. Input Suara
                  _MethodCard(
                    title: 'Input Suara',
                    description:
                        'Sebutkan transaksi dan biarkan aplikasi membantu mengisi detailnya secara otomatis.',
                    icon: Icons.mic_none_rounded,
                    iconColor: AppColors.secondary,
                    iconBackground: AppColors.secondarySoft,
                    badgeText: 'Cepat',
                    onTap: () => _onVoiceSelected(context),
                  ),
                  const SizedBox(height: 16),

                  // 3. Scan Struk
                  _MethodCard(
                    title: 'Scan Struk',
                    description:
                        'Pindai struk belanja untuk mengisi detail transaksi pengeluaran secara instan.',
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.accentPurple,
                    iconBackground: AppColors.accentPurpleSoft,
                    badgeText: 'Otomatis',
                    onTap: () => _onScanSelected(context),
                  ),
                  const SizedBox(height: 32),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Semua metode akan memuat data ke formulir transaksi agar kamu dapat memeriksa dan mengoreksi seluruh detail sebelum disimpan.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
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
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
    this.badgeText,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      large: true,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          badgeText!,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}


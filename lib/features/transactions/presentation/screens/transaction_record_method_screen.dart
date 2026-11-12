import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../providers/transactions_controller.dart';

/// Halaman pemilihan metode pencatatan transaksi TahanDulu:
/// 1. Input Manual (Aksen Biru Pastel)
/// 2. Input Suara (Aksen Ungu Pastel)
/// 3. Scan Struk (Aksen Oranye Pastel)
///
/// Tampilan modern, minimalis, clean, dan premium dengan ilustrasi
/// dan ikon 3D transparan sesuai identitas fintech TAHAN DULU.
class TransactionRecordMethodScreen extends ConsumerWidget {
  const TransactionRecordMethodScreen({super.key});

  void _onManualSelected(BuildContext context, WidgetRef ref) {
    ref.read(transactionFormProvider.notifier).reset();
    context.push(AppRoutes.transactionAdd);
  }

  void _onVoiceSelected(BuildContext context, WidgetRef ref) {
    ref.read(transactionFormProvider.notifier).reset();
    context.push(AppRoutes.transactionVoice);
  }

  void _onScanSelected(BuildContext context, WidgetRef ref) {
    ref.read(transactionFormProvider.notifier).reset();
    context.push(AppRoutes.transactionScan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(onPressed: () => context.pop()),
        title: Text(
          'Pilih Metode Catat',
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF102A43),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Hero Section ---
                  _HeroSection(textTheme: textTheme),
                  const SizedBox(height: 18),

                  // --- Pilihan Metode ---
                  // 1. Input Manual
                  _MethodCard(
                    title: 'Input Manual',
                    subtitle: 'Catat transaksi secara langsung',
                    assetPath: AppAssets.txMethodManual,
                    accentColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFEFF6FF),
                    onTap: () => _onManualSelected(context, ref),
                  ),
                  const SizedBox(height: 12),

                  // 2. Input Suara
                  _MethodCard(
                    title: 'Input Suara',
                    subtitle: 'Cukup ucapkan transaksimu',
                    assetPath: AppAssets.txMethodVoice,
                    accentColor: const Color(0xFF8B5CF6),
                    iconBgColor: const Color(0xFFF5F3FF),
                    onTap: () => _onVoiceSelected(context, ref),
                  ),
                  const SizedBox(height: 12),

                  // 3. Scan Struk
                  _MethodCard(
                    title: 'Scan Struk',
                    subtitle: 'Pindai struk secara otomatis',
                    assetPath: AppAssets.txMethodScan,
                    accentColor: const Color(0xFFF59E0B),
                    iconBgColor: const Color(0xFFFFFBEB),
                    onTap: () => _onScanSelected(context, ref),
                  ),
                  const SizedBox(height: 18),

                  // --- Info Box Keamanan ---
                  _InfoBox(textTheme: textTheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero banner yang compact dan responsif dengan ilustrasi di sisi kanan.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Catat Transaksi',
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Lebih Mudah',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih cara mencatat yang paling nyaman buatmu.',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                AppAssets.txHero,
                fit: BoxFit.contain,
                height: 105,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan metode dengan visual 3D, background pastel lembut, dan border halus.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.accentColor,
    required this.iconBgColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EDF3), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  assetPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF102A43),
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF718096),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE8EDF3),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kotak informasi kompak dengan ikon keamanan di bagian bawah.
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.0),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.txSecurity,
            width: 26,
            height: 26,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Semua transaksi bisa diperiksa dan diedit sebelum disimpan.',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF166534),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_method_tile.dart';
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

    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Scaffold(
      extendBodyBehindAppBar: useDarkGlass,
      backgroundColor: context.canvasColor,
      appBar: AppAdaptiveAppBar(
        backgroundColor: context.canvasColor,
        leading: AppBackButton(onPressed: () => context.pop()),
        title: Text(
          'Pilih Metode Catat',
          style: textTheme.titleMedium?.copyWith(
            color: context.palette.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: GlassBackdrop(child: SafeArea(
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
                  AppMethodTile(
                    title: 'Input Manual',
                    subtitle: 'Catat transaksi secara langsung',
                    assetPath: AppAssets.txMethodManual,
                    accent: const Color(0xFF3B82F6),
                    onTap: () => _onManualSelected(context, ref),
                  ),
                  const SizedBox(height: 12),

                  // 2. Input Suara
                  AppMethodTile(
                    title: 'Input Suara',
                    subtitle: 'Cukup ucapkan transaksimu',
                    assetPath: AppAssets.txMethodVoice,
                    accent: context.palette.tertiary,
                    onTap: () => _onVoiceSelected(context, ref),
                  ),
                  const SizedBox(height: 12),

                  // 3. Scan Struk
                  AppMethodTile(
                    title: 'Scan Struk',
                    subtitle: 'Pindai struk secara otomatis',
                    assetPath: AppAssets.txMethodScan,
                    accent: const Color(0xFFF59E0B),
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
      )),
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.palette.onSurface.withValues(alpha: 0.03),
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
                    color: context.palette.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Lebih Mudah',
                  style: textTheme.titleLarge?.copyWith(
                    color: context.palette.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih cara mencatat yang paling nyaman buatmu.',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
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

/// Kotak informasi kompak dengan ikon keamanan di bagian bawah.
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.primaryContainer, width: 1.0),
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
                color: context.palette.primary,
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

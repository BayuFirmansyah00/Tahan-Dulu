import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_method_tile.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/tahandulu_controller.dart';
import '../widgets/tahandulu_widgets.dart';

/// Halaman Tambah Barang TahanDulu.
///
/// Menyediakan pilihan metode penambahan barang:
/// 1. Masukkan manual — mengisi detail barang sendiri melalui formulir.
/// 2. Masukkan link produk — menempel tautan barang dari toko online.
/// 3. Upload foto — menambahkan barang melalui foto (segera hadir).
class TahanDuluAddScreen extends ConsumerWidget {
  const TahanDuluAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);
    return Scaffold(
      backgroundColor: context.canvasColor,
      extendBodyBehindAppBar: useDarkGlass,
      appBar: AppAdaptiveAppBar(
        backgroundColor: useDarkGlass ? null : context.canvasColor,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          'Tambah Barang',
          style: TextStyle(
            color: useDarkGlass ? Colors.white : context.palette.onSurface,
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
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
                  const _AddHeroSection(),
                  const SizedBox(height: 20),

                  // --- Pilihan Metode Tambah Barang ---
                  // Card 1: Masukkan Manual
                  AppMethodTile(
                    title: AppStrings.methodManual,
                    subtitle: 'Isi detail barang sendiri',
                    assetPath: AppAssets.tambahBarangManual,
                    accent: context.warningInk,
                    onTap: () {
                      ref.read(tahanDuluControllerProvider.notifier).reset();
                      context.push(AppRoutes.tahanDuluForm);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Card 2: Masukkan Link Produk
                  AppMethodTile(
                    title: AppStrings.methodLink,
                    subtitle: 'Tempel tautan barang dari toko online',
                    assetPath: AppAssets.tambahBarangLink,
                    accent: context.palette.primary,
                    onTap: () {
                      ref.read(tahanDuluControllerProvider.notifier).reset();
                      context.push(AppRoutes.tahanDuluLink);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Card 3: Upload Foto
                  AppMethodTile(
                    title: AppStrings.methodPhoto,
                    subtitle: 'Tambahkan barang melalui foto',
                    assetPath: AppAssets.tambahBarangFoto,
                    accent: context.palette.tertiary,
                    onTap: () => _showImageSourcePicker(context, ref),
                  ),
                  const SizedBox(height: 20),

                  // --- Catatan Informasi ---
                  const _InfoReminderCard(),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }

  Future<void> _showImageSourcePicker(BuildContext context, WidgetRef ref) async {
    final source = await showGlassSheet<ImageSource>(
      context: context,
      scrollContent: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Sumber Foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gunakan kamera atau pilih foto produk dari galeri HP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.palette.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: context.palette.secondary),
                ),
                title: Text(
                  'Ambil Foto (Kamera)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.palette.onSurface),
                ),
                subtitle: const Text('Buka kamera untuk memotret barang langsung'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: context.palette.outlineVariant),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.palette.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: context.palette.tertiary),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.palette.onSurface),
                ),
                subtitle: const Text('Ambil foto dari galeri perangkat'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: context.palette.outlineVariant),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        final notifier = ref.read(tahanDuluControllerProvider.notifier);
        notifier.reset();

        // Pindai gambar dengan OCR untuk mendeteksi informasi nama produk, harga, atau marketplace
        final ocr = ref.read(productOcrServiceProvider);
        final ocrResult = await ocr.scanProductImage(picked.path);

        if (ocrResult.hasDetectedInfo) {
          notifier.prefillDraft(
            itemName: ocrResult.itemName,
            price: ocrResult.price,
            marketplace: ocrResult.marketplace,
            imageRef: picked.path,
            extractionNotice: 'Informasi produk berhasil dideteksi dari gambar.',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Informasi produk berhasil dideteksi dari gambar!'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          notifier.setImageRef(picked.path);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto produk berhasil dipilih. Silakan lengkapi nama dan harga barang.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        if (context.mounted) {
          context.push(AppRoutes.tahanDuluForm);
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto. Silakan coba lagi.')),
        );
      }
    }
  }
}

/// Hero section modern dan compact dengan ilustrasi 3D tas Tahan Dulu di sebelah kanan.
class _AddHeroSection extends StatelessWidget {
  const _AddHeroSection();

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
            blurRadius: 12,
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
                  'Tambah barang impianmu',
                  style: TextStyle(
                    color: context.palette.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Simpan barang yang ingin dibeli dan lihat dampaknya pada keuanganmu.',
                  style: TextStyle(
                    color: context.palette.onSurfaceVariant,
                    fontSize: 12.5,
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
                AppAssets.tambahBarangHero,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  height: 110,
                  width: 110,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: context.palette.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Catatan informasi edukatif sederhana di bagian bawah.
class _InfoReminderCard extends StatelessWidget {
  const _InfoReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.warningFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.warningFill, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.tambahBarangInfo,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.info_outline_rounded,
              size: 24,
              color: context.warningInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tahan Dulu membantu melihat dampak pembelian terhadap kondisi keuanganmu, bukan memberikan saran finansial.',
              style: TextStyle(
                color: context.warningInk,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_icons.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: const Text(
          'Tambah Barang',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
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
                  const _AddHeroSection(),
                  const SizedBox(height: 20),

                  // --- Pilihan Metode Tambah Barang ---
                  // Card 1: Masukkan Manual
                  _MethodSelectionCard(
                    title: AppStrings.methodManual,
                    subtitle: 'Isi detail barang sendiri',
                    assetPath: AppAssets.tambahBarangManual,
                    tileBg: const Color(0xFFFFF5DB),
                    tileBorder: const Color(0xFFFDE68A),
                    splashColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    onTap: () {
                      ref.read(tahanDuluControllerProvider.notifier).reset();
                      context.push(AppRoutes.tahanDuluForm);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Card 2: Masukkan Link Produk
                  _MethodSelectionCard(
                    title: AppStrings.methodLink,
                    subtitle: 'Tempel tautan barang dari toko online',
                    assetPath: AppAssets.tambahBarangLink,
                    tileBg: const Color(0xFFEAF8F1),
                    tileBorder: const Color(0xFFDCFCE7),
                    splashColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                    onTap: () {
                      ref.read(tahanDuluControllerProvider.notifier).reset();
                      context.push(AppRoutes.tahanDuluLink);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Card 3: Upload Foto
                  _MethodSelectionCard(
                    title: AppStrings.methodPhoto,
                    subtitle: 'Tambahkan barang melalui foto',
                    assetPath: AppAssets.tambahBarangFoto,
                    tileBg: const Color(0xFFF2ECFF),
                    tileBorder: const Color(0xFFDDD6FE),
                    splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
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
      ),
    );
  }

  Future<void> _showImageSourcePicker(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gunakan kamera atau pilih foto produk dari galeri HP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text(
                  'Ambil Foto (Kamera)',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF102A43)),
                ),
                subtitle: const Text('Buka kamera untuk memotret barang langsung'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE8EDF3)),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF9333EA)),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF102A43)),
                ),
                subtitle: const Text('Ambil foto dari galeri perangkat'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE8EDF3)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambah barang impianmu',
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Simpan barang yang ingin dibeli dan lihat dampaknya pada keuanganmu.',
                  style: TextStyle(
                    color: Color(0xFF718096),
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
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 110,
                  width: 110,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Color(0xFF10B981),
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

/// Kartu pilihan metode dengan container ikon pastel lembut, judul, subtitle, dan chevron.
class _MethodSelectionCard extends StatelessWidget {
  const _MethodSelectionCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.tileBg,
    required this.tileBorder,
    required this.onTap,
    this.splashColor,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final Color tileBg;
  final Color tileBorder;
  final VoidCallback onTap;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: splashColor ?? const Color(0xFF102A43).withValues(alpha: 0.06),
        highlightColor: const Color(0xFF102A43).withValues(alpha: 0.03),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EDF3), width: 1.2),
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
              // Container ikon 3D dengan latar warna pastel lembut
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tileBorder, width: 1.0),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  assetPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 32,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Teks: Judul, status/badge, subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF102A43),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron kanan
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ],
          ),
        ),
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
        color: const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.tambahBarangInfo,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.info_outline_rounded,
              size: 24,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tahan Dulu membantu melihat dampak pembelian terhadap kondisi keuanganmu, bukan memberikan saran finansial.',
              style: TextStyle(
                color: Color(0xFF78350F),
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

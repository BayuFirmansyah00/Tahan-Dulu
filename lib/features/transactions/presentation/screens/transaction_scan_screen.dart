import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../domain/receipt_parser.dart';
import '../providers/native_input_providers.dart';
import '../providers/transactions_controller.dart';

/// Halaman Scan Struk TahanDulu.
///
/// Menyediakan alur ekstraksi informasi struk belanja:
/// - Pilihan kamera atau galeri foto asli perangkat (image_picker)
/// - Menampilkan preview gambar struk yang dipilih
/// - Deteksi teks OCR on-device (Google ML Kit)
/// - Ekstraksi nama toko, tanggal, dan total pembayaran akhir (ReceiptParser)
/// - Memastikan total akhir diprioritaskan di atas subtotal
/// - Memastikan kategori dan akun dipilih manual oleh pengguna
/// - Mengarahkan ke formulir transaksi sebelum konfirmasi dan penyimpanan
class TransactionScanScreen extends ConsumerStatefulWidget {
  const TransactionScanScreen({super.key});

  /// Sampel struk untuk pengujian parser OCR (dipertahankan untuk test suite)
  static const String sampleIndomaret = '''INDOMARET POINT
JL. SUDIRMAN NO. 45 JAKARTA
TGL: 02/11/2026 14:30
-----------------------------
ROTI COKELAT        12.000
AIR MINERAL 600ML    4.000
KOPI BOTOL           9.000
-----------------------------
SUBTOTAL            25.000
DISKON                   0
TOTAL               25.000
TUNAI               50.000
KEMBALIAN           25.000
TERIMA KASIH''';

  static const String sampleSuperindo = '''SUPERINDO SUPERMARKET
TANGGAL: 2026-10-30
-----------------------------
APEL FUJI 1KG       35.000
SUSU UHT 1L         20.000
-----------------------------
SUBTOTAL            55.000
ONGKOS PACKING      10.000
GRAND TOTAL         65.000
BCA DEBIT           65.000''';

  @override
  ConsumerState<TransactionScanScreen> createState() =>
      _TransactionScanScreenState();
}

class _TransactionScanScreenState extends ConsumerState<TransactionScanScreen> {
  final _parser = const ReceiptParser();
  late final TextEditingController _receiptTextController;
  ReceiptOcrService? _ocrService;

  String? _imagePath;
  bool _isProcessingOcr = false;
  String? _errorMessage;
  ParsedReceipt? _parsedReceipt;
  bool _isEditingText = false;

  @override
  void initState() {
    super.initState();
    _receiptTextController = TextEditingController();
    _ocrService = ref.read(receiptOcrServiceProvider);
  }

  @override
  void dispose() {
    _receiptTextController.dispose();
    if (_imagePath != null) {
      _ocrService?.deleteTempImage(_imagePath);
    }
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final ocrService = ref.read(receiptOcrServiceProvider);
      final path = await ocrService.pickImageFromCamera();
      if (path == null) {
        // Pengguna membatalkan pengambilan foto
        return;
      }
      await _processImageFile(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengakses kamera: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final ocrService = ref.read(receiptOcrServiceProvider);
      final path = await ocrService.pickImageFromGallery();
      if (path == null) {
        // Pengguna membatalkan pemilihan galeri
        return;
      }
      await _processImageFile(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal membuka galeri foto: $e';
      });
    }
  }

  Future<void> _processImageFile(String path) async {
    final oldPath = _imagePath;
    if (oldPath != null && oldPath != path) {
      ref.read(receiptOcrServiceProvider).deleteTempImage(oldPath);
    }

    setState(() {
      _imagePath = path;
      _isProcessingOcr = true;
      _errorMessage = null;
    });

    try {
      final ocrService = ref.read(receiptOcrServiceProvider);
      final text = await ocrService.recognizeText(path);

      if (!mounted) return;

      if (text.trim().isEmpty) {
        setState(() {
          _isProcessingOcr = false;
          _errorMessage =
              'Teks struk tidak terbaca atau buram. Pastikan pencahayaan cukup dan foto struk tidak terpotong, lalu coba lagi.';
          _receiptTextController.text = '';
          _parsedReceipt = null;
        });
        return;
      }

      setState(() {
        _receiptTextController.text = text;
        _isProcessingOcr = false;
      });
      _extractReceipt(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingOcr = false;
        _errorMessage = 'Gagal membaca struk dengan OCR: $e';
      });
    }
  }

  /// Programmatic helper untuk pengujian
  void loadSampleReceipt(String sample) {
    setState(() {
      _imagePath = null;
      _errorMessage = null;
      _receiptTextController.text = sample;
    });
    _extractReceipt(sample);
  }

  void _extractReceipt(String text) {
    final parsed = _parser.parse(text);
    setState(() {
      _parsedReceipt = parsed;
    });
  }

  void _confirmAndNavigateToForm() {
    final receipt = _parsedReceipt;
    if (receipt == null) return;

    final notifier = ref.read(transactionFormProvider.notifier);

    // Susun catatan dari rincian item belanja yang terbaca (tanpa menduplikasi merchant)
    final noteParts = <String>[];
    if (receipt.items.isNotEmpty) {
      final itemSummary = receipt.items.map((i) => i.name).take(3).join(', ');
      noteParts.add('Item: $itemSummary');
    }
    if (receipt.time != null && receipt.time!.isNotEmpty) {
      noteParts.add('Waktu: ${receipt.time}');
    }

    String? notice;
    if (receipt.hasMultipleTotals) {
      notice = 'Struk memiliki beberapa kemungkinan nominal. Harap pastikan total akhir pembayaran.';
    } else if (receipt.total <= 0) {
      notice = 'Nominal struk belum terdeteksi. Silakan masukkan nominal pembayaran secara manual.';
    }

    notifier.prefillFromScan(
      amount: receipt.total,
      date: receipt.date,
      title: (receipt.hasMerchant && receipt.merchantName!.trim().isNotEmpty)
          ? receipt.merchantName!.trim()
          : null,
      note: noteParts.isNotEmpty ? noteParts.join(' - ') : null,
      notice: notice,
    );

    // Arahkan ke formulir transaksi manual untuk verifikasi akun & kategori
    context.push(AppRoutes.transactionAdd);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: AppBackButton(onPressed: () => context.pop()),
        title: const Text(
          'Scan Struk',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
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
                  const _ScanHeroSection(),
                  const SizedBox(height: 20),

                  // Error Banner bila OCR / picker gagal
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Loading indicator saat memproses OCR
                  if (_isProcessingOcr) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EDF3)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Membaca Teks Struk...',
                                  style: TextStyle(
                                    color: Color(0xFF102A43),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Menjalankan Google ML Kit OCR on-device',
                                  style: TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Image Preview jika ada gambar yang dipilih
                  if (_imagePath != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EDF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Foto Struk Terpilih',
                                  style: TextStyle(
                                    color: Color(0xFF102A43),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isProcessingOcr
                                    ? null
                                    : () {
                                        setState(() {
                                          _imagePath = null;
                                          _parsedReceipt = null;
                                          _receiptTextController.clear();
                                        });
                                      },
                                child: const Text('Hapus Foto'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: File(_imagePath!).existsSync()
                                  ? Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFFF7F9FC),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image,
                                            color: Color(0xFF718096),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Berkas: ${_imagePath!.split(Platform.pathSeparator).last}',
                                              style: const TextStyle(
                                                color: Color(0xFF718096),
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Section: Pilihan Sumber Struk ---
                  const Text(
                    'Pilih sumber struk',
                    style: TextStyle(
                      color: Color(0xFF102A43),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Card Kamera
                      Expanded(
                        child: _ActionCard(
                          title: 'Kamera',
                          subtitle: 'Ambil foto struk',
                          assetPath: AppAssets.scanCamera3d,
                          accentColor: const Color(0xFF10B981),
                          bgColor: const Color(0xFFEAF8F1),
                          borderColor: const Color(0xFFDCFCE7),
                          onTap: _isProcessingOcr ? null : _captureFromCamera,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card Galeri
                      Expanded(
                        child: _ActionCard(
                          title: 'Galeri',
                          subtitle: 'Pilih dari galeri',
                          assetPath: AppAssets.scanGallery3d,
                          accentColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFFEDF4FF),
                          borderColor: const Color(0xFFDBEAFE),
                          onTap: _isProcessingOcr ? null : _pickFromGallery,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Section: Cara Kerja ---
                  const Text(
                    'Cara Kerja',
                    style: TextStyle(
                      color: Color(0xFF102A43),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _HowItWorksCard(),
                  const SizedBox(height: 16),

                  // Area Teks OCR (Dapat disunting jika ada kata yang salah terdeteksi)
                  if (_receiptTextController.text.isNotEmpty) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Teks Hasil OCR Struk',
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: _isEditingText
                                    ? const Icon(Icons.check, size: 20)
                                    : const Icon(Icons.edit_outlined, size: 20),
                                tooltip: _isEditingText ? 'Simpan' : 'Sunting',
                                onPressed: () {
                                  if (_isEditingText) {
                                    _extractReceipt(
                                      _receiptTextController.text,
                                    );
                                    setState(() {
                                      _isEditingText = false;
                                    });
                                  } else {
                                    setState(() {
                                      _isEditingText = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isEditingText)
                            TextField(
                              controller: _receiptTextController,
                              maxLines: 8,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Tempel atau ubah teks struk di sini...',
                                border: OutlineInputBorder(),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE8EDF3),
                                ),
                              ),
                              child: Text(
                                _receiptTextController.text,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Hasil Ekstraksi Struk
                  if (_parsedReceipt != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Struk yang Dikenali',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ReceiptRow(
                            label: 'Nama Toko / Merchant',
                            value: _parsedReceipt!.merchantName ??
                                'Belum terbaca (isi di form)',
                            isHighlight: true,
                          ),
                          const Divider(height: 16),
                          _ReceiptRow(
                            label: 'Tanggal Transaksi',
                            value: _parsedReceipt!.date != null
                                ? DateFormatter.dayMonthYear(
                                    _parsedReceipt!.date!,
                                  )
                                : 'Hari ini (dapat diubah di form)',
                          ),
                          if (_parsedReceipt!.time != null) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Waktu / Jam Transaksi',
                              value: _parsedReceipt!.time!,
                            ),
                          ],
                          if (_parsedReceipt!.subtotal != null) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Subtotal Terbaca',
                              value: CurrencyFormatter.format(
                                _parsedReceipt!.subtotal!,
                              ),
                            ),
                          ],
                          if (_parsedReceipt!.discount != null &&
                              _parsedReceipt!.discount! > 0) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Diskon Terbaca',
                              value:
                                  '- ${CurrencyFormatter.format(_parsedReceipt!.discount!)}',
                              highlightColor: AppColors.success,
                            ),
                          ],
                          if (_parsedReceipt!.tax != null &&
                              _parsedReceipt!.tax! > 0) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Pajak / PPN Terbaca',
                              value: CurrencyFormatter.format(
                                _parsedReceipt!.tax!,
                              ),
                            ),
                          ],
                          if (_parsedReceipt!.serviceFee != null &&
                              _parsedReceipt!.serviceFee! > 0) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Biaya Layanan Terbaca',
                              value: CurrencyFormatter.format(
                                _parsedReceipt!.serviceFee!,
                              ),
                            ),
                          ],
                          const Divider(height: 16),
                          _ReceiptRow(
                            label: 'Total Akhir Pembayaran',
                            value: _parsedReceipt!.total > 0
                                ? CurrencyFormatter.format(
                                    _parsedReceipt!.total,
                                  )
                                : 'Belum terbaca (isi manual)',
                            isHighlight: true,
                            highlightColor: AppColors.primary,
                          ),
                          if (_parsedReceipt!.hasMultipleTotals) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Terdapat beberapa kandidat total pada struk. Periksa kembali total akhir di form.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF92400E),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_parsedReceipt!.items.isNotEmpty) ...[
                            const Divider(height: 16),
                            Text(
                              'Item Belanja Terbaca (${_parsedReceipt!.items.length}):',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ..._parsedReceipt!.items.map(
                              (item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• ${item.name}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(item.price),
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Action Button
                    AppButton(
                      label: 'Gunakan Data Struk di Form',
                      assetPath: AppAssets.navForward,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _confirmAndNavigateToForm,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // --- Section: Informasi Privasi ---
                  const _PrivacyInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero section yang compact dan modern dengan ilustrasi 3D scan struk di sisi kanan.
class _ScanHeroSection extends StatelessWidget {
  const _ScanHeroSection();

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
                  'Catat dari struk,',
                  style: TextStyle(
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                Text(
                  'lebih praktis.',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Foto struk belanja dan biarkan aplikasi membaca transaksimu secara otomatis.',
                  style: TextStyle(
                    color: Color(0xFF718096),
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
                AppAssets.scanReceiptHero,
                fit: BoxFit.contain,
                height: 110,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu aksi sumber struk (Kamera & Galeri) dengan ikon 3D dan panah kecil.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withValues(alpha: 0.15),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: Container(
          constraints: const BoxConstraints(minHeight: 160, maxHeight: 185),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  assetPath,
                  width: 74,
                  height: 74,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF102A43),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu section Cara Kerja menampilkan 3 langkah secara horizontal simetris.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStep(
            asset: AppAssets.scanStepCamera,
            label: 'Ambil foto',
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Color(0xFFCBD5E1),
          ),
          _buildStep(
            asset: AppAssets.scanStepRead,
            label: 'Baca data',
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Color(0xFFCBD5E1),
          ),
          _buildStep(
            asset: AppAssets.scanStepReview,
            label: 'Periksa hasil',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String asset, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          asset,
          width: 38,
          height: 38,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Informasi privasi kompak di bagian bawah.
class _PrivacyInfoCard extends StatelessWidget {
  const _PrivacyInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.0),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.scanShieldCheck,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Struk diproses di perangkat. Hasil dapat diperiksa sebelum disimpan.',
              style: TextStyle(
                color: Color(0xFF166534),
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: isHighlight
                  ? (highlightColor ?? AppColors.textPrimary)
                  : AppColors.textPrimary,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/transaction_model.dart';
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

  @override
  ConsumerState<TransactionScanScreen> createState() =>
      _TransactionScanScreenState();
}

class _TransactionScanScreenState extends ConsumerState<TransactionScanScreen> {
  final _parser = const ReceiptParser();
  late final TextEditingController _receiptTextController;

  String? _imagePath;
  bool _isProcessingOcr = false;
  String? _errorMessage;
  ParsedReceipt? _parsedReceipt;
  bool _isEditingText = false;

  static const String _sampleIndomaret = '''INDOMARET POINT
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

  static const String _sampleSuperindo = '''SUPERINDO SUPERMARKET
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
  void initState() {
    super.initState();
    _receiptTextController = TextEditingController();
  }

  @override
  void dispose() {
    _receiptTextController.dispose();
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

  void _loadSampleReceipt(String sample) {
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

    // Struk belanja selalu dikategorikan sebagai pengeluaran
    notifier.setType(TransactionType.expense);

    if (receipt.total > 0) {
      notifier.setAmount(receipt.total);
    }

    if (receipt.date != null) {
      notifier.setDate(receipt.date!);
    }

    // Susun catatan dari merchant dan rincian item belanja yang terbaca
    final noteParts = <String>[];
    if (receipt.hasMerchant) {
      noteParts.add(receipt.merchantName!);
    }
    if (receipt.items.isNotEmpty) {
      final itemSummary = receipt.items.map((i) => i.name).take(3).join(', ');
      noteParts.add('Item: $itemSummary');
    }
    if (noteParts.isNotEmpty) {
      notifier.setNote(noteParts.join(' - '));
    }

    // Arahkan ke formulir transaksi manual untuk verifikasi akun & kategori
    context.push(AppRoutes.transactionAdd);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Scan Struk'),
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
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pindai Struk Belanja',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ambil foto struk belanja atau pilih dari galeri untuk mengekstrak nominal, toko, dan tanggal secara otomatis.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error Banner bila OCR / picker gagal
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pilihan Kamera atau Galeri
                  Row(
                    children: [
                      Expanded(
                        child: _ScanOptionCard(
                          icon: Icons.camera_alt_rounded,
                          title: 'Kamera',
                          subtitle: 'Ambil foto fisik',
                          color: AppColors.primary,
                          onTap: _isProcessingOcr ? null : _captureFromCamera,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScanOptionCard(
                          icon: Icons.photo_library_rounded,
                          title: 'Galeri',
                          subtitle: 'Pilih dari berkas',
                          color: AppColors.secondary,
                          onTap: _isProcessingOcr ? null : _pickFromGallery,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Image Preview jika ada gambar yang dipilih
                  if (_imagePath != null) ...[
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image_outlined,
                                      size: 18,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Foto Struk Terpilih',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: File(_imagePath!).existsSync()
                                  ? Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.backgroundWarm,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Berkas terpilih: ${_imagePath!.split(Platform.pathSeparator).last}',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
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

                  // Loading indicator saat memproses OCR
                  if (_isProcessingOcr) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Membaca Teks Struk...',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Menjalankan Google ML Kit OCR on-device',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
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

                  // Atau uji dengan contoh teks struk
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.text_snippet_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Uji Contoh Teks Struk',
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih contoh struk belanja di bawah ini untuk menguji keakuratan parser tanpa kamera:',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.receipt, size: 16),
                              label: const Text('Contoh Indomaret'),
                              onPressed: () =>
                                  _loadSampleReceipt(_sampleIndomaret),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.shopping_bag_outlined,
                                  size: 16),
                              label: const Text('Contoh Superindo'),
                              onPressed: () =>
                                  _loadSampleReceipt(_sampleSuperindo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                                icon: Icon(
                                  _isEditingText
                                      ? Icons.check
                                      : Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                onPressed: () {
                                  if (_isEditingText) {
                                    _extractReceipt(
                                        _receiptTextController.text);
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
                                hintText: 'Tempel atau ubah teks struk di sini...',
                                border: OutlineInputBorder(),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundWarm,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
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
                                    _parsedReceipt!.date!)
                                : 'Hari ini (dapat diubah di form)',
                          ),
                          if (_parsedReceipt!.subtotal != null) ...[
                            const Divider(height: 16),
                            _ReceiptRow(
                              label: 'Subtotal Terbaca',
                              value: CurrencyFormatter.format(
                                  _parsedReceipt!.subtotal!),
                            ),
                          ],
                          const Divider(height: 16),
                          _ReceiptRow(
                            label: 'Total Akhir Pembayaran',
                            value: _parsedReceipt!.total > 0
                                ? CurrencyFormatter.format(
                                    _parsedReceipt!.total)
                                : 'Belum terbaca (isi manual)',
                            isHighlight: true,
                            highlightColor: AppColors.primary,
                          ),
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
                                padding: const EdgeInsets.symmetric(vertical: 2),
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
                    const SizedBox(height: 24),

                    // Confirm Action Button
                    AppButton(
                      label: 'Gunakan Data Struk di Form',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _confirmAndNavigateToForm,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Catatan Keamanan Transaksi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: AppRadius.card,
                    ),
                    child: Text(
                      'Catatan: Pemrosesan gambar struk dilakukan secara lokal di perangkat Anda (on-device ML Kit). Data struk dimasukkan ke form untuk diverifikasi akun dan kategorinya sebelum disimpan ke sistem.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 11,
                      ),
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

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
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

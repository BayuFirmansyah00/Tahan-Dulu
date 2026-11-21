import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Link produk: URL disimpan sebagai referensi (tanpa klaim scraping).
///
/// Tahap 46: ilustrasi header_link_produk, field prefix ikon link +
/// tombol paste, contoh link, validasi dekat field, CTA kuning yang
/// tetap terjangkau saat keyboard terbuka (bottomButton scaffold).
class TahanDuluLinkScreen extends ConsumerStatefulWidget {
  const TahanDuluLinkScreen({super.key});

  @override
  ConsumerState<TahanDuluLinkScreen> createState() =>
      _TahanDuluLinkScreenState();
}

class _TahanDuluLinkScreenState extends ConsumerState<TahanDuluLinkScreen> {
  final _urlController = TextEditingController();
  bool _attempted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final url = _urlController.text.trim();
    if (!isValidProductUrl(url)) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(purchaseDecisionRepositoryProvider);
      final metadata = await repo.extractMetadata(url);

      if (!mounted) return;

      final isExtracted = metadata['extracted'] == true;
      final status = (metadata['status'] as String?) ?? (isExtracted ? 'complete' : 'failed');
      final title = metadata['title'] as String?;
      final price = (metadata['price'] as num?)?.toDouble();
      final originalPrice = (metadata['original_price'] as num?)?.toDouble();
      final isDiscount = metadata['is_discount'] == true;
      final imageUrl = metadata['image_url'] as String?;
      final marketplace = metadata['marketplace'] as String?;
      final storeName = metadata['store_name'] as String?;
      final description = metadata['description'] as String?;
      final canonicalUrl = (metadata['canonical_url'] as String?) ?? url;
      final priceRequiresConfirmation = metadata['price_requires_confirmation'] == true;

      ref.read(tahanDuluControllerProvider.notifier).reset(canonicalUrl);

      String? notice;
      if (status == 'complete') {
        final source = storeName ?? marketplace ?? 'toko online';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Informasi produk berhasil dimuat dari $source!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (status == 'partial') {
        if (priceRequiresConfirmation) {
          notice = 'Produk memiliki varian / rentang harga. Silakan tentukan harga pilihan kamu.';
        } else if (price == null || price <= 0) {
          notice = 'Harga produk tidak dapat dimuat otomatis. Silakan isi harga barang.';
        } else if (imageUrl == null || imageUrl.isEmpty) {
          notice = 'Foto produk tidak ditemukan di website. Kamu dapat menambahkan foto secara manual.';
        } else {
          notice = 'Sebagian informasi produk berhasil dimuat. Silakan periksa kembali.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Info produk tidak dapat dimuat otomatis dari link ini. Silakan lengkapi di formulir.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (isExtracted && (title != null || price != null || imageUrl != null)) {
        ref.read(tahanDuluControllerProvider.notifier).prefillDraft(
          itemName: title,
          price: price,
          originalPrice: originalPrice,
          isDiscount: isDiscount,
          marketplace: marketplace,
          productUrl: canonicalUrl,
          imageRef: imageUrl,
          note: description,
          priceRequiresConfirmation: priceRequiresConfirmation,
          extractionNotice: notice,
        );
      }

      context.push(AppRoutes.tahanDuluForm);
    } catch (_) {
      if (!mounted) return;
      ref.read(tahanDuluControllerProvider.notifier).reset(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Koneksi metadata gagal. Silakan isi detail produk secara manual.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      context.push(AppRoutes.tahanDuluForm);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _urlController.text = text;
    if (_attempted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showError =
        _attempted && !isValidProductUrl(_urlController.text.trim());

    return TahanDuluScaffold(
      title: AppStrings.methodLink,
      bottomButton: AppButton(
        label: _isLoading ? 'Memuat info...' : AppStrings.continueAction,
        isLoading: _isLoading,
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
        onPressed: _isLoading ? null : _next,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: TdHeroImage(
                asset: TdHeaderArt.link,
                fallbackAsset:
                    'assets/illustrations/illustration_link_produk.png',
                height: 150,
                width: 230,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tempel link produk',
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                color: TdColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.methodLinkDesc,
              style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.productUrlLabel,
              style: textTheme.titleMedium?.copyWith(
                color: TdColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _urlController,
              hint: AppStrings.productUrlHint,
              prefixIcon: Icons.link_outlined,
              keyboardType: TextInputType.url,
              suffixIcon: IconButton(
                tooltip: 'Tempel',
                icon: const Icon(Icons.content_paste_outlined),
                onPressed: _paste,
              ),
              onChanged: (_) {
                if (_attempted) setState(() {});
              },
            ),
            if (showError) ...[
              const SizedBox(height: 6),
              Text(
                AppStrings.productUrlInvalid,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Contoh link:',
              style: textTheme.titleSmall?.copyWith(
                color: TdColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final example in const [
              'https://tokopedia.com/...',
              'https://shopee.co.id/...',
              'https://www.lazada.co.id/...',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: TdColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
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
      ),
    );
  }
}

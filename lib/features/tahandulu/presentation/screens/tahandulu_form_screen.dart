import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Informasi Produk: nama, harga, kategori, link, catatan.
///
/// Tahap 46: ringkasan produk (bila dari link), grid kategori 3D,
/// field berlabel jelas, CTA kuning. Formatter Rupiah, validasi,
/// dan state draf tidak diubah.
class TahanDuluFormScreen extends ConsumerStatefulWidget {
  const TahanDuluFormScreen({super.key});

  @override
  ConsumerState<TahanDuluFormScreen> createState() =>
      _TahanDuluFormScreenState();
}

class _TahanDuluFormScreenState extends ConsumerState<TahanDuluFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _urlController;
  late final TextEditingController _noteController;
  bool _attempted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(tahanDuluControllerProvider);
    _nameController = TextEditingController(text: draft.itemName);
    _priceController = TextEditingController(
      text: draft.price > 0 ? RupiahInputFormatter.format(draft.price) : '',
    );
    _urlController = TextEditingController(text: draft.productUrl);
    _noteController = TextEditingController(text: draft.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        ref.read(tahanDuluControllerProvider.notifier).setImageRef(picked.path);

        // Jika nama atau harga masih kosong, coba pindai teks dengan OCR
        if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
          final ocr = ref.read(productOcrServiceProvider);
          final ocrResult = await ocr.scanProductImage(picked.path);
          if (ocrResult.hasDetectedInfo) {
            if (_nameController.text.trim().isEmpty && ocrResult.itemName != null) {
              _nameController.text = ocrResult.itemName!;
              ref.read(tahanDuluControllerProvider.notifier).setName(ocrResult.itemName!);
            }
            if (_priceController.text.trim().isEmpty && ocrResult.price != null && ocrResult.price! > 0) {
              _priceController.text = RupiahInputFormatter.format(ocrResult.price!);
              ref.read(tahanDuluControllerProvider.notifier).setPrice(ocrResult.price!);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detail produk otomatis terdeteksi dari foto!'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto.')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
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
                'Foto Produk',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('Ambil Foto Baru (Kamera)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF9333EA)),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (ref.read(tahanDuluControllerProvider).imageRef != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  title: const Text('Hapus Foto', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(tahanDuluControllerProvider.notifier).setImageRef(null);
                  },
                ),
              ],
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    final notifier = ref.read(tahanDuluControllerProvider.notifier);
    notifier.setName(_nameController.text);
    notifier.setPriceText(_priceController.text);
    notifier.setUrl(_urlController.text);
    notifier.setNote(_noteController.text);
    if (!ref.read(tahanDuluControllerProvider).isComplete) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await notifier.saveDraft();
      if (!mounted) return;
      if (saved != null) {
        context.push('${AppRoutes.tahanDulu}/${saved.id}');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(tahanDuluControllerProvider);
    final notifier = ref.read(tahanDuluControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final showNameError = _attempted && !draft.isNameValid;
    final showPriceError = _attempted && !draft.isPriceValid;
    final showUrlError = _attempted && !draft.isUrlValid;

    return TahanDuluScaffold(
      title: AppStrings.addItemTitle,
      bottomButton: AppButton(
        label: AppStrings.analyzeAction,
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
        isLoading: _saving,
        onPressed: _saving ? null : _analyze,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Foto Produk (jika ada foto dari Link atau Kamera/Galeri)
            if (draft.imageRef != null && draft.imageRef!.isNotEmpty) ...[
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TdColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProductImage(
                        imageRef: draft.imageRef,
                        category: draft.category,
                        height: 160,
                        borderRadius: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Ganti Foto',
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF102A43)),
                            onPressed: _showPhotoOptions,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Hapus Foto',
                            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(tahanDuluControllerProvider.notifier).setImageRef(null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 20, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Tambah Foto Produk (Opsional)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Banner Informasi Ekstraksi (Marketplace, Rentang Harga, atau Diskon)
            if (draft.marketplace != null || draft.extractionNotice != null || draft.priceRequiresConfirmation || (draft.isDiscount && draft.originalPrice != null)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: draft.priceRequiresConfirmation
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: draft.priceRequiresConfirmation
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      draft.priceRequiresConfirmation
                          ? Icons.info_outline
                          : Icons.verified_outlined,
                      size: 20,
                      color: draft.priceRequiresConfirmation
                          ? const Color(0xFFD97706)
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (draft.marketplace != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                draft.marketplace!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF102A43),
                                ),
                              ),
                            ),
                          if (draft.extractionNotice != null)
                            Text(
                              draft.extractionNotice!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: draft.priceRequiresConfirmation
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF1E40AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (draft.isDiscount && draft.originalPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Harga Asli: Rp ${RupiahInputFormatter.format(draft.originalPrice!)} (Diskon Terdeteksi)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            AppTextField(
              controller: _nameController,
              label: AppStrings.productNameLabel,
              hint: AppStrings.productNameHint,
            ),
            if (showNameError) ...[
              const SizedBox(height: 6),
              _FieldError(text: AppStrings.productNameRequired),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _priceController,
              label: AppStrings.productPriceLabel,
              hint: '0',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
            ),
            if (showPriceError) ...[
              const SizedBox(height: 6),
              _FieldError(text: AppStrings.productPriceRequired),
            ],
            const SizedBox(height: 16),
            Text(
              AppStrings.productCategoryLabel,
              style: textTheme.titleMedium?.copyWith(
                color: TdColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.7,
              ),
              itemCount: ProductCategory.values.length,
              itemBuilder: (context, index) {
                final category = ProductCategory.values[index];
                return _CategoryTile(
                  category: category,
                  selected: draft.category == category,
                  onTap: () => notifier.setCategory(category),
                );
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _urlController,
              label: '${AppStrings.productUrlLabel} (opsional)',
              hint: AppStrings.productUrlHint,
              prefixIcon: Icons.link_outlined,
              keyboardType: TextInputType.url,
            ),
            if (showUrlError) ...[
              const SizedBox(height: 6),
              _FieldError(text: AppStrings.productUrlInvalid),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _noteController,
              label: AppStrings.productNoteLabel,
              hint: AppStrings.productNoteHint,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TdColors.highlight : TdColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TdColors.primary : TdColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            TdCategoryIcon(category: category, size: 36),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                productCategoryLabel(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? TdColors.navy : TdColors.slate,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

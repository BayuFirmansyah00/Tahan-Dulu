import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

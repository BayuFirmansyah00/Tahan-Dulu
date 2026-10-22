import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _next() {
    final url = _urlController.text.trim();
    if (!isValidProductUrl(url)) {
      setState(() => _attempted = true);
      return;
    }
    ref.read(tahanDuluControllerProvider.notifier).reset(url);
    context.push(AppRoutes.tahanDuluForm);
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
        label: AppStrings.continueAction,
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
        onPressed: _next,
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

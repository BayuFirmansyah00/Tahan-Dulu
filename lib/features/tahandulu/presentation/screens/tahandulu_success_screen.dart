import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Pembelian dikonfirmasi: keputusan tersimpan, TANPA transaksi otomatis.
/// CTA mengarah ke alur Transaksi agar saldo tercatat tepat satu kali.
///
/// Tahap 46: aksen kuning + ikon sukses lembut. Alur tidak diubah.
class TahanDuluSuccessScreen extends ConsumerWidget {
  const TahanDuluSuccessScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(considerationsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasColor,
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: items.when(
              data: (all) {
                final matches = all.where((e) => e.id == itemId);
                if (matches.isEmpty) {
                  return const Center(child: Text(AppStrings.accountNotFound));
                }
                final item = matches.first;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: context.palette.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: AppImageIcon(
                            assetPath: AppAssets.tdSuccess,
                            size: 52,
                            fallbackIcon: Icons.check,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.successBuyTitle,
                        style: textTheme.headlineMedium?.copyWith(
                          color: context.palette.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.successBuySubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TdCard(
                        child: Row(
                          children: [
                            ProductImage(
                              imageRef: item.imageRef,
                              category: item.category,
                              height: 52,
                              width: 52,
                              borderRadius: 12,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: context.palette.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatCompact(item.price),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: context.palette.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${productCategoryLabel(item.category)}'
                                    ' • ${DateFormatter.dayMonthYear(DateTime.now())}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: context.palette.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.productUrl != null && isValidProductUrl(item.productUrl!)) ...[
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.linkProduk,
                          style: textTheme.titleMedium?.copyWith(
                            color: context.palette.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.palette.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.palette.outlineVariant),
                                ),
                                child: Text(
                                  item.productUrl!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: context.palette.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: context.palette.tertiaryContainer,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: AppStrings.bukaLinkProduk,
                                icon: Icon(
                                  Icons.open_in_new,
                                  size: 20,
                                  color: context.palette.onSurface,
                                ),
                                onPressed: () async {
                                  final url = Uri.parse(item.productUrl!);
                                  bool launched = false;
                                  if (await canLaunchUrl(url)) {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                  if (!context.mounted) return;
                                  if (!launched) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(AppStrings.urlOpenFailed),
                                        backgroundColor: TdColors.danger,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        label: AppStrings.seeTransactionsAction,
                        backgroundColor: context.palette.tertiaryContainer,
                        foregroundColor: context.palette.onSurface,
                        onPressed: () => context.go(AppRoutes.transactions),
                      ),
                      const SizedBox(height: 12),
                      AppOutlineButton(
                        label: AppStrings.backToHome,
                        onPressed: () => context.go(AppRoutes.dashboard),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(considerationsProvider),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

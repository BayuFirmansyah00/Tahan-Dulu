import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      backgroundColor: TdColors.background,
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
      ),
      body: SafeArea(
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
                        decoration: const BoxDecoration(
                          color: TdColors.primary,
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
                          color: TdColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.successBuySubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TdColors.slate,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TdCard(
                        child: Row(
                          children: [
                            TdCategoryIcon(category: item.category, size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: TdColors.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatCompact(item.price),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: TdColors.navy,
                                    ),
                                  ),
                                  Text(
                                    '${productCategoryLabel(item.category)}'
                                    ' • ${DateFormatter.dayMonthYear(DateTime.now())}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: TdColors.slate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: AppStrings.seeTransactionsAction,
                        backgroundColor: TdColors.primary,
                        foregroundColor: TdColors.navy,
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
      ),
    );
  }
}

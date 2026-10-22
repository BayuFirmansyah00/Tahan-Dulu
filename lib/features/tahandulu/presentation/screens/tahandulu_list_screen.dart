import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/finance_math.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Daftar TahanDulu: hero + tab Menunggu/Wishlist/Selesai + kartu.
///
/// Tahap 46: hero kuning lembut + ilustrasi header_tahandulu,
/// kartu produk memakai ikon kategori 3D, CTA kuning.
/// Data, filter, route, dan validasi tidak diubah.
class TahanDuluListScreen extends ConsumerStatefulWidget {
  const TahanDuluListScreen({super.key});

  @override
  ConsumerState<TahanDuluListScreen> createState() =>
      _TahanDuluListScreenState();
}

class _TahanDuluListScreenState extends ConsumerState<TahanDuluListScreen> {
  int _tab = 0;

  List<PurchaseConsideration> _filtered(List<PurchaseConsideration> items) {
    switch (_tab) {
      case 0:
        return items
            .where((e) => e.status == ConsiderationStatus.considering)
            .toList();
      case 1:
        return items
            .where((e) => e.status == ConsiderationStatus.wishlist)
            .toList();
      case 2:
        return items.where((e) => e.isFinal).toList();
    }
    return items;
  }

  void _openItem(PurchaseConsideration item) {
    final now = DateTime.now();
    if (item.isWaitingAt(now)) {
      context.push('${AppRoutes.tahanDulu}/${item.id}/wait');
    } else {
      context.push('${AppRoutes.tahanDulu}/${item.id}/decide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(considerationsProvider);
    final dashboard = ref.watch(dashboardDataProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: TdColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.tahanDuluPageTitle),
        backgroundColor: TdColors.background,
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: items.when(
              data: (all) {
                final waiting = all
                    .where((e) => e.status == ConsiderationStatus.considering)
                    .length;
                final wishlist = all
                    .where((e) => e.status == ConsiderationStatus.wishlist)
                    .length;
                final done = all.where((e) => e.isFinal).length;
                final filtered = _filtered(all);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        waiting: waiting,
                        onSee: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.tahanDuluPageSubtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TdColors.slate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Tab(
                              label: '${AppStrings.tabWaiting} ($waiting)',
                              selected: _tab == 0,
                              onTap: () => setState(() => _tab = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Tab(
                              label: '${AppStrings.tabWishlist} ($wishlist)',
                              selected: _tab == 1,
                              onTap: () => setState(() => _tab = 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Tab(
                              label: '${AppStrings.tabDone} ($done)',
                              selected: _tab == 2,
                              onTap: () => setState(() => _tab = 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const AppEmptyState(
                          title: AppStrings.emptyTahanDulu,
                          subtitle: AppStrings.emptyTahanDuluHint,
                          icon: Icons.pause_circle_outline,
                        )
                      else
                        for (final item in filtered) ...[
                          _ItemCard(
                            item: item,
                            flexible: (dashboard.value?.remainingFlexible ?? 0),
                            onTap: () => _openItem(item),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 12),
                      AppButton(
                        label: AppStrings.addItemAction,
                        icon: Icons.add,
                        backgroundColor: TdColors.primary,
                        foregroundColor: TdColors.navy,
                        onPressed: () {
                          ref
                              .read(tahanDuluControllerProvider.notifier)
                              .reset();
                          context.push(AppRoutes.tahanDuluAdd);
                        },
                      ),
                      const SizedBox(height: 12),
                      const _EduCard(),
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

/// Hero kuning lembut: ringkasan + ilustrasi kanan + CTA Lihat.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.waiting, required this.onSee});

  final int waiting;
  final VoidCallback onSee;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: TdColors.highlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TdColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$waiting ${AppStrings.pendingSuffix}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TdColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tahanDuluBannerHint,
                  style: textTheme.bodySmall?.copyWith(color: TdColors.slate),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onSee,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TdColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.tahanDuluSee,
                          style: textTheme.labelLarge?.copyWith(
                            color: TdColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: TdColors.navy,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const TdHeroImage(
            asset: TdHeaderArt.list,
            fallbackAsset:
                'assets/illustrations/illustration_tas_tahandulu.png',
            height: 132,
            width: 148,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? TdColors.primary : TdColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? TdColors.primary : TdColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? TdColors.navy : TdColors.slate,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.flexible,
    required this.onTap,
  });

  final PurchaseConsideration item;
  final double flexible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final visual = productVisual(item.category);
    final share = purchaseBudgetShare(price: item.price, flexible: flexible);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TdColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TdColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F102A43),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ProductImage(
              imageRef: item.imageRef,
              category: item.category,
              height: 64,
              width: 64,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: TdColors.navy,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCompact(item.price),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TdColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      productCategoryLabel(item.category),
                      style: textTheme.labelSmall?.copyWith(
                        color: visual.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: TdColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.waitEndsAt == null
                              ? productCategoryLabel(item.category)
                              : formatWaitShort(item.waitEndsAt!, now),
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: TdColors.slate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (share != null && share > 0)
                    Text(
                      '≈${(share * 100).round()}% budget fleksibel',
                      style: textTheme.labelSmall?.copyWith(
                        color: TdColors.slate,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: TdColors.slate),
          ],
        ),
      ),
    );
  }
}

class _EduCard extends StatelessWidget {
  const _EduCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TdColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TdColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: TdColors.highlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: TdColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tahanDuluEduTitle,
                  style: textTheme.titleMedium?.copyWith(color: TdColors.navy),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.tahanDuluEduBody,
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

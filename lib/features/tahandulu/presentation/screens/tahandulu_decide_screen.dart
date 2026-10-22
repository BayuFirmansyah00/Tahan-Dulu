import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Keputusan pembelian: 4 opsi + dampak. Status final dikunci visual.
/// "Beli" hanya menandai (tanpa transaksi otomatis); "Tidak jadi" konfirmasi.
///
/// Tahap 46: ringkasan 3D + kartu opsi konsisten kuning.
/// Alur keputusan dan status tidak diubah.
class TahanDuluDecideScreen extends ConsumerStatefulWidget {
  const TahanDuluDecideScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<TahanDuluDecideScreen> createState() =>
      _TahanDuluDecideScreenState();
}

class _TahanDuluDecideScreenState extends ConsumerState<TahanDuluDecideScreen> {
  bool _working = false;

  Future<void> _act(
    PurchaseConsideration item,
    Future<bool> Function() action,
    String route,
  ) async {
    setState(() => _working = true);
    try {
      final ok = await action();
      if (!mounted) return;
      if (ok) {
        context.go(route);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmCancel(PurchaseConsideration item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmCancelTitle),
        content: Text('“${item.itemName}” ${AppStrings.confirmCancelBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.decideCancel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final notifier = ref.read(tahanDuluControllerProvider.notifier);
    await _act(
      item,
      () => notifier.setStatus(item.id, ConsiderationStatus.cancelled),
      AppRoutes.tahanDulu,
    );
  }

  Future<void> _confirmBuy(PurchaseConsideration item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmBuyTitle),
        content: const Text(AppStrings.confirmBuyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.decideBuy),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final notifier = ref.read(tahanDuluControllerProvider.notifier);
    await _act(
      item,
      () => notifier.setStatus(item.id, ConsiderationStatus.bought),
      '${AppRoutes.tahanDulu}/${item.id}/success',
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(considerationsProvider);
    final textTheme = Theme.of(context).textTheme;

    return TahanDuluScaffold(
      title: AppStrings.decideTitle,
      child: items.when(
        data: (all) {
          final matches = all.where((e) => e.id == widget.itemId);
          if (matches.isEmpty) {
            return const Center(child: Text(AppStrings.accountNotFound));
          }
          final item = matches.first;
          final locked = item.isFinal;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.decideSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
                ),
                const SizedBox(height: 12),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              '${item.waitEndsAt == null ? '' : ' • ${formatWaitShort(item.waitEndsAt!, DateTime.now())}'}',
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
                if (locked) ...[
                  const SizedBox(height: 12),
                  _FinalBanner(item: item),
                ],
                const SizedBox(height: 16),
                _OptionCard(
                  icon: Icons.shopping_cart_outlined,
                  foreground: TdColors.navy,
                  background: TdColors.primary,
                  title: AppStrings.decideBuy,
                  subtitle: AppStrings.decideBuyDesc,
                  enabled: !locked && !_working,
                  onTap: () => _confirmBuy(item),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  icon: Icons.pause_circle_outline,
                  foreground: TdColors.warning,
                  background: TdColors.warningBg,
                  title: AppStrings.decideSnooze,
                  subtitle: AppStrings.decideSnoozeDesc,
                  enabled: !locked && !_working,
                  onTap: () =>
                      context.push('${AppRoutes.tahanDulu}/${item.id}/wait'),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  icon: Icons.favorite_outline,
                  foreground: const Color(0xFF8B5CF6),
                  background: const Color(0xFFEEE9FE),
                  title: AppStrings.decideWishlist,
                  subtitle: AppStrings.decideWishlistDesc,
                  enabled: !locked && !_working,
                  onTap: () => _act(
                    item,
                    () => ref
                        .read(tahanDuluControllerProvider.notifier)
                        .setStatus(item.id, ConsiderationStatus.wishlist),
                    AppRoutes.tahanDulu,
                  ),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  icon: Icons.close,
                  foreground: TdColors.danger,
                  background: TdColors.dangerBg,
                  title: AppStrings.decideCancel,
                  subtitle: AppStrings.decideCancelDesc,
                  enabled: !locked && !_working,
                  onTap: () => _confirmCancel(item),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.decideImpactTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.formatCompact(item.price)}'
                  ' • ${productCategoryLabel(item.category)}',
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
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
    );
  }
}

class _FinalBanner extends StatelessWidget {
  const _FinalBanner({required this.item});

  final PurchaseConsideration item;

  @override
  Widget build(BuildContext context) {
    final done = item.status == ConsiderationStatus.bought;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdColors.highlight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: TdColors.navy,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              done ? AppStrings.boughtBadge : AppStrings.cancelledBadge,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TdColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: foreground, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: TdColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
}

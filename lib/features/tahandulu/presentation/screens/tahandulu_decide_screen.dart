import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_account.dart';
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
    final message = '“${item.itemName}” ${AppStrings.confirmCancelBody}';
    final confirmed = GlassDesignTokens.isDarkGlass(context)
        ? await GlassDialog.show<bool>(
            context: context,
            title: AppStrings.confirmCancelTitle,
            message: message,
            settings: GlassDesignTokens.darkOverlaySettings(context),
            actions: [
              GlassDialogAction(
                label: AppStrings.cancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              GlassDialogAction(
                label: AppStrings.decideCancel,
                isDestructive: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        : await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppStrings.confirmCancelTitle),
              content: Text(message),
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
    final accounts = await ref
        .read(accountsProvider.future)
        .catchError((_) => <FinancialAccount>[]);
    if (!mounted) return;
    final activeAccounts = accounts
        .where((a) => a.type != AccountType.legacyCash)
        .toList();

    await showGlassSheet<void>(
      context: context,
      isScrollControlled: true,
      scrollContent: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Konfirmasi Pembelian',
                  style: Theme.of(bottomSheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.palette.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih bagaimana Anda ingin mencatat pembelian “${item.itemName}” (${CurrencyFormatter.formatCompact(item.price)}).',
                  style: Theme.of(bottomSheetContext)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _showAccountSelectionSheet(item, activeAccounts);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.palette.tertiaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.palette.tertiaryContainer),
                    ),
                    child: Row(
                      children: [
                        const AppImageIcon(
                          assetPath: AppAssets.tdActionBuy,
                          size: 28,
                          fallbackIcon: Icons.payments_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catat Pembelian & Potong Saldo',
                                style: Theme.of(bottomSheetContext)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.palette.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Catat transaksi pengeluaran dan potong saldo rekening yang dipilih.',
                                style: Theme.of(bottomSheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.palette.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: context.palette.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();
                    final notifier =
                        ref.read(tahanDuluControllerProvider.notifier);
                    await _act(
                      item,
                      () => notifier.setStatus(
                        item.id,
                        ConsiderationStatus.bought,
                      ),
                      '${AppRoutes.tahanDulu}/${item.id}/success',
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.canvasColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.palette.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const AppImageIcon(
                          assetPath: AppAssets.statusSuccess,
                          size: 28,
                          fallbackIcon: Icons.check_circle_outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tandai Dibeli Saja (Tanpa Transaksi)',
                                style: Theme.of(bottomSheetContext)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.palette.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hanya memperbarui status wishlist tanpa membuat transaksi atau mengubah saldo.',
                                style: Theme.of(bottomSheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.palette.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: context.palette.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAccountSelectionSheet(
    PurchaseConsideration item,
    List<FinancialAccount> accounts,
  ) async {
    if (accounts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada akun rekening aktif. Silakan tambahkan rekening terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    await showGlassSheet<void>(
      context: context,
      isScrollControlled: true,
      scrollContent: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Rekening Pembayaran',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.palette.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo akan dipotong sejumlah ${CurrencyFormatter.formatCompact(item.price)}',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      final accId = acc.id;
                      final isSufficient = acc.balance >= item.price;

                      return InkWell(
                        onTap: () async {
                          if (!isSufficient) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Saldo pada ${acc.name} (${CurrencyFormatter.formatCompact(acc.balance)}) tidak mencukupi untuk membayar ${CurrencyFormatter.formatCompact(item.price)}.',
                                ),
                                backgroundColor: TdColors.danger,
                              ),
                            );
                            return;
                          }
                          Navigator.of(sheetContext).pop();
                          final notifier =
                              ref.read(tahanDuluControllerProvider.notifier);
                          await _act(
                            item,
                            () => notifier.recordPurchase(
                              item.id,
                              accountId: accId,
                              information:
                                  'Pembelian Tahan Dulu: ${item.itemName}',
                            ),
                            '${AppRoutes.tahanDulu}/${item.id}/success',
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSufficient
                                  ? context.palette.outlineVariant
                                  : context.palette.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const AppImageIcon(
                                assetPath: AppAssets.instBank,
                                size: 24,
                                fallbackIcon: Icons.account_balance,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: context.palette.onSurface,
                                          ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Saldo: ${CurrencyFormatter.formatCompact(acc.balance)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: isSufficient
                                                    ? context.palette.onSurfaceVariant
                                                    : context.palette.error,
                                                fontWeight: isSufficient
                                                    ? FontWeight.normal
                                                    : FontWeight.w600,
                                              ),
                                        ),
                                        if (!isSufficient) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.palette.errorContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Saldo Kurang',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: context.palette.error,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: context.palette.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  style: textTheme.bodyMedium?.copyWith(color: context.palette.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TdCard(
                  child: Row(
                    children: [
                      ProductImage(
                        imageRef: item.imageRef,
                        category: item.category,
                        height: 56,
                        width: 56,
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
                              '${item.waitEndsAt == null ? '' : ' • ${formatWaitShort(item.waitEndsAt!, DateTime.now())}'}',
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
                              launched =
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
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
                if (locked) ...[
                  const SizedBox(height: 12),
                  _FinalBanner(item: item),
                ],
                const SizedBox(height: 16),
                _OptionCard(
                  assetPath: AppAssets.tdActionBuy,
                  icon: Icons.shopping_cart_outlined,
                  foreground: context.palette.onSurface,
                  background: context.palette.tertiaryContainer,
                  title: AppStrings.decideBuy,
                  subtitle: AppStrings.decideBuyDesc,
                  enabled: !locked && !_working,
                  onTap: () => _confirmBuy(item),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  assetPath: AppAssets.tdActionWait,
                  icon: Icons.pause_circle_outline,
                  foreground: context.warningInk,
                  background: context.warningFill,
                  title: AppStrings.decideSnooze,
                  subtitle: AppStrings.decideSnoozeDesc,
                  enabled: !locked && !_working,
                  onTap: () =>
                      context.push('${AppRoutes.tahanDulu}/${item.id}/wait'),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  assetPath: AppAssets.tdActionWishlist,
                  icon: Icons.favorite_outline,
                  foreground: context.palette.tertiary,
                  background: context.palette.tertiaryContainer,
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
                  assetPath: AppAssets.actionDelete,
                  icon: Icons.close,
                  foreground: context.palette.error,
                  background: context.palette.errorContainer,
                  title: AppStrings.decideCancel,
                  subtitle: AppStrings.decideCancelDesc,
                  enabled: !locked && !_working,
                  onTap: () => _confirmCancel(item),
                ),
                const SizedBox(height: 10),
                _OptionCard(
                  assetPath: AppAssets.actionEdit,
                  icon: Icons.edit_outlined,
                  foreground: context.palette.onSurface,
                  background: context.palette.secondaryContainer,
                  title: AppStrings.editBarang,
                  subtitle: AppStrings.editBarangDesc,
                  enabled: !locked && !_working,
                  onTap: () {
                    context.push(
                      '${AppRoutes.tahanDuluForm}?edit=${item.id}',
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.decideImpactTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: context.palette.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.formatCompact(item.price)}'
                  ' • ${productCategoryLabel(item.category)}',
                  style: textTheme.bodyMedium?.copyWith(color: context.palette.onSurfaceVariant),
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
        color: context.palette.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const AppImageIcon(
            assetPath: AppAssets.statusSuccess,
            size: 18,
            fallbackIcon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              done ? AppStrings.boughtBadge : AppStrings.cancelledBadge,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.palette.onSurface,
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
    this.icon,
    this.assetPath,
    required this.foreground,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData? icon;
  final String? assetPath;
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
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.outlineVariant),
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
                child: Center(
                  child: assetPath != null
                      ? AppImageIcon(
                          assetPath: assetPath!,
                          size: 22,
                          fallbackIcon: icon ?? Icons.category_outlined,
                        )
                      : Icon(icon, color: foreground, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: context.palette.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppImageIcon(
                assetPath: AppAssets.navForward,
                size: 20,
                fallbackIcon: Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

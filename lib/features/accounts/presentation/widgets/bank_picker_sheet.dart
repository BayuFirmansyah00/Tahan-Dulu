import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../data/models/api_bank.dart';
import '../../../../data/providers/app_providers.dart';
import 'bank_logo_badge.dart';

/// Modal bottom sheet untuk memilih bank dari katalog resmi backend.
class BankPickerSheet extends ConsumerStatefulWidget {
  const BankPickerSheet({
    super.key,
    this.selectedBankId,
    this.selectedBankSlug,
    this.categoryFilter,
    this.title = 'Pilih Bank',
    this.subtitle = 'Katalog bank resmi Indonesia',
  });

  final int? selectedBankId;
  final String? selectedBankSlug;
  final String? categoryFilter;
  final String title;
  final String subtitle;

  /// Helper statis untuk menampilkan modal sheet.
  static Future<ApiBank?> show(
    BuildContext context, {
    int? selectedBankId,
    String? selectedBankSlug,
    String? categoryFilter,
    String title = 'Pilih Bank',
    String subtitle = 'Katalog bank resmi Indonesia',
  }) {
    return showModalBottomSheet<ApiBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankPickerSheet(
        selectedBankId: selectedBankId,
        selectedBankSlug: selectedBankSlug,
        categoryFilter: categoryFilter,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  ConsumerState<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends ConsumerState<BankPickerSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _searchHint {
    if (widget.categoryFilter == 'bank') {
      return 'Cari nama atau kode bank (BCA, Mandiri, BSI, 014)...';
    }
    if (widget.categoryFilter == 'digitalBank') {
      return 'Cari bank digital (Jago, Jenius, SeaBank, Blu)...';
    }
    if (widget.categoryFilter == 'ewallet') {
      return 'Cari e-wallet (GoPay, OVO, DANA, ShopeePay)...';
    }
    return 'Cari nama atau kode penyedia...';
  }

  String get _emptyTitle {
    if (widget.categoryFilter == 'digitalBank') {
      return 'Bank digital tidak ditemukan';
    }
    if (widget.categoryFilter == 'ewallet') {
      return 'E-Wallet tidak ditemukan';
    }
    return 'Bank tidak ditemukan';
  }

  String get _emptySubtitle {
    if (widget.categoryFilter == 'ewallet') {
      return 'Coba cari dengan nama e-wallet seperti GoPay, OVO, DANA, atau ShopeePay.';
    }
    if (widget.categoryFilter == 'digitalBank') {
      return 'Coba cari dengan nama bank digital seperti Jago, Jenius, SeaBank, atau Blu.';
    }
    return 'Coba cari dengan nama lain atau kode bank.';
  }

  String get _footerText {
    if (widget.categoryFilter == 'ewallet') {
      return 'Katalog idn-finlogos • Merek dagang milik penerbit e-wallet bersangkutan';
    }
    if (widget.categoryFilter == 'digitalBank') {
      return 'Katalog idn-finlogos • Merek dagang milik bank digital bersangkutan';
    }
    return 'Katalog idn-finlogos • Merek dagang milik bank bersangkutan';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Mengambil seluruh katalog aktif (tanpa filter server terlebih dahulu)
    // agar filter pencarian lokal bekerja instan dan responsif.
    final banksAsync = ref.watch(banksProvider(null));

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Kolom Pencarian
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Konten Daftar Bank
            Expanded(
              child: banksAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(height: 12),
                      Text('Memuat katalog bank...'),
                    ],
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppImageIcon(
                          assetPath: AppAssets.statusError,
                          size: 40,
                          fallbackIcon: Icons.cloud_off,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat katalog bank',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan terhubung ke internet atau server backend aktif.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(banksProvider),
                          icon: const AppImageIcon(
                            assetPath: AppAssets.actionRefresh,
                            size: 18,
                            fallbackIcon: Icons.refresh,
                          ),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (allBanks) {
                  final activeBanks =
                      allBanks.where((b) => b.isActive).toList();
                  final byCategory = widget.categoryFilter == null
                      ? activeBanks
                      : activeBanks.where((b) {
                          if (widget.categoryFilter == 'bank') {
                            return b.category == 'bank' ||
                                b.category == 'bank-logo';
                          }
                          return b.category == widget.categoryFilter;
                        }).toList();

                  final filtered = _searchQuery.isEmpty
                      ? byCategory
                      : byCategory
                            .where((b) => b.matchesSearch(_searchQuery))
                            .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _emptyTitle,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emptySubtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Text(
                          _searchQuery.isEmpty
                              ? '${filtered.length} pilihan tersedia'
                              : '${filtered.length} hasil ditemukan',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              indent: 64,
                              color: AppColors.divider,
                            ),
                            itemBuilder: (context, index) {
                              final bank = filtered[index];
                              final isSelected =
                                  (widget.selectedBankId != null &&
                                      widget.selectedBankId == bank.id) ||
                                  (widget.selectedBankSlug != null &&
                                      widget.selectedBankSlug == bank.slug);

                              final aliasText = bank.aliases.isNotEmpty
                                  ? bank.aliases.join(' • ')
                                  : bank.slug.toUpperCase();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                leading: BankLogoBadge(
                                  bankName: bank.name,
                                  bankSlug: bank.slug,
                                  bankLogoUrl: bank.logoUrl,
                                  size: 42,
                                ),
                                title: Text(
                                  bank.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  aliasText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const AppImageIcon(
                                        assetPath: AppAssets.statusSuccess,
                                        size: 20,
                                        fallbackIcon: Icons.check_circle,
                                      )
                                    : null,
                                onTap: () => Navigator.of(context).pop(bank),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Footer info lisensi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.backgroundWarm,
              child: Row(
                children: [
                  const AppImageIcon(
                    assetPath: AppAssets.statusInfo,
                    size: 14,
                    fallbackIcon: Icons.info_outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _footerText,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
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

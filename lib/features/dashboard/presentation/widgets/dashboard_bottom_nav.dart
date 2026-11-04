import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';

/// Bottom navigation premium TahanDulu sesuai referensi:
/// pill putih, Home aktif (mint + dot), struk + badge Rp, tombol Catat
/// lingkaran emerald terangkat, target-panah, profil outline.
///
/// Lima tab saja: 0 dashboard, 1 transaksi, 2 catat (tombol tengah),
/// 3 goals, 4 profil. Tab Akun dan Laporan dihapus dari nav bawah
/// (fitur tetap diakses lewat kartu dashboard dan route masing-masing).
/// `currentIndex` null (layar tanpa tab) berarti tidak ada tab aktif.
/// Sinkronisasi aktif mengikuti halaman aktual berdasarkan
/// `currentIndex` yang dideklarasikan tiap layar (terverifikasi benar
/// untuk semua route: 0 dashboard, 1 transaksi, 3 goals, 4 profil).
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key, this.currentIndex, required this.onTap});

  /// Tab aktif. Null bila layar ini tak punya tab (mis. Akun).
  final int? currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F2440),
                        blurRadius: 18,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _TabSlot(
                        active: currentIndex == 0,
                        onTap: () => onTap(0),
                        child: _TabContent(
                          assetPath: AppAssets.navHome,
                          label: AppStrings.navHome,
                          active: currentIndex == 0,
                        ),
                      ),
                      _TabSlot(
                        active: currentIndex == 1,
                        onTap: () => onTap(1),
                        child: _TabContent(
                          assetPath: AppAssets.navTransaction,
                          label: AppStrings.navTransactions,
                          active: currentIndex == 1,
                          badge: true,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      _TabSlot(
                        active: currentIndex == 3,
                        onTap: () => onTap(3),
                        child: _TabContent(
                          assetPath: AppAssets.navTarget,
                          label: AppStrings.navGoals,
                          active: currentIndex == 3,
                        ),
                      ),
                      _TabSlot(
                        active: currentIndex == 4,
                        onTap: () => onTap(4),
                        child: _TabContent(
                          assetPath: AppAssets.navProfile,
                          label: AppStrings.navProfile,
                          active: currentIndex == 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(child: _RecordButton(onTap: () => onTap(2))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slot sentuh satu tab (tinggi penuh pill, >=48px).
class _TabSlot extends StatelessWidget {
  const _TabSlot({
    required this.active,
    required this.onTap,
    required this.child,
  });

  final bool active;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(height: 70, alignment: Alignment.center, child: child),
      ),
    );
  }
}

/// Isi tab: ikon + label + latar mint animasi + dot indikator.
class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.assetPath,
    required this.label,
    required this.active,
    this.badge = false,
  });

  final String assetPath;
  final String label;
  final bool active;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AppImageIcon(
                  assetPath: assetPath,
                  size: 24,
                  opacity: active ? 1.0 : 0.65,
                  semanticLabel: label,
                ),
                if (badge)
                  Positioned(
                    right: -8,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'Rp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(top: 3),
            width: active ? 26 : 0,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol Catat: lingkaran emerald terangkat + label.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('record_button'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: AppImageIcon(
                  key: Key('record_button_icon'),
                  assetPath: AppAssets.actionAddMoney,
                  size: 32,
                  semanticLabel: AppStrings.navRecord,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            AppStrings.navRecord,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

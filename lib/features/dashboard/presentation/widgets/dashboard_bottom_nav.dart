import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom navigation premium TahanDulu sesuai referensi:
/// pill putih, Home aktif (mint + dot), struk + badge Rp, tombol Catat
/// lingkaran emerald terangkat, target-panah, profil outline.
///
/// API publik, urutan menu, label, dan pemetaan indeks tidak berubah
/// sehingga route, handler per layar, dan test yang ada tetap berlaku.
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
                          icon: currentIndex == 0
                              ? Icons.home
                              : Icons.home_outlined,
                          label: AppStrings.navHome,
                          active: currentIndex == 0,
                        ),
                      ),
                      _TabSlot(
                        active: currentIndex == 1,
                        onTap: () => onTap(1),
                        child: _TabContent(
                          icon: Icons.receipt_long_outlined,
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
                          icon: Icons.track_changes_outlined,
                          label: AppStrings.navGoals,
                          active: currentIndex == 3,
                          arrow: true,
                        ),
                      ),
                      _TabSlot(
                        active: currentIndex == 4,
                        onTap: () => onTap(4),
                        child: _TabContent(
                          icon: currentIndex == 4
                              ? Icons.person
                              : Icons.person_outline,
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
    required this.icon,
    required this.label,
    required this.active,
    this.badge = false,
    this.arrow = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool badge;
  final bool arrow;

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
                _AnimatedIcon(icon: icon, color: color),
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
                if (arrow)
                  const Positioned(
                    right: -4,
                    top: -2,
                    child: Icon(
                      Icons.north_east,
                      size: 11,
                      color: AppColors.primary,
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

/// Ikon dengan transisi warna halus saat aktif/nonaktif.
class _AnimatedIcon extends StatelessWidget {
  const _AnimatedIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Icon(icon, color: value, size: 25),
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
              child: const Icon(Icons.add, color: Colors.white, size: 30),
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

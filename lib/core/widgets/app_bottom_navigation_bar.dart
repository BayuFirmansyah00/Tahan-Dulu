import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../routing/app_routes.dart';

/// Navigation bar global TAHAN DULU dengan konsep Floating Rounded Navigation Bar.
///
/// Menyediakan lima menu tersusun simetris:
/// 0: Beranda — ikon rumah 3D transparan
/// 1: Transaksi — ikon dua panah 3D transparan
/// 2: Catat (+) — primary action button lingkaran hijau elevated dengan simbol plus putih
/// 3: Tujuan — ikon target 3D transparan
/// 4: Profil — ikon pengguna 3D transparan
///
/// Karakteristik desain:
/// - Floating bar putih dengan rounded corners (26 dp) dan margin horizontal (14 dp)
/// - Shadow halus natural dengan border tipis #E8EDF3
/// - Tombol Catat (+) terangkat (elevated) dengan shadow emerald yang lembut
/// - Active state otomatis mengikuti route halaman aktif (atau index eksplisit via [currentIndex])
/// - Animasi transisi active state halus (scale 1.06, soft mint pill #EAF8F1, dan indicator bar)
/// - Menghindari overflow dan auto-hide saat virtual keyboard terbuka
class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    this.currentIndex,
    this.onTap,
  });

  /// Index menu aktif (0: Beranda, 1: Transaksi, 2: Catat, 3: Tujuan, 4: Profil).
  /// Bila bernilai null, akan dideteksi secara otomatis dari route lokasi saat ini.
  final int? currentIndex;

  /// Callback kustom saat menu ditekan.
  /// Bila bernilai null, akan menjalankan navigasi default global.
  final ValueChanged<int>? onTap;

  /// Helper untuk mendeteksi index tab berdasarkan URI route aktif GoRouter.
  static int? resolveIndexFromLocation(String location) {
    if (location == AppRoutes.dashboard || location == '/') return 0;
    if (location.startsWith(AppRoutes.transactionRecordMethod)) return 2;
    if (location.startsWith(AppRoutes.transactions)) return 1;
    if (location.startsWith(AppRoutes.goals)) return 3;
    if (location.startsWith(AppRoutes.settings) ||
        location.startsWith(AppRoutes.profileApp) ||
        location.startsWith(AppRoutes.profileEdit) ||
        location.startsWith(AppRoutes.profileSecurity) ||
        location.startsWith(AppRoutes.profilePrivacy) ||
        location.startsWith(AppRoutes.profileHelp) ||
        location.startsWith(AppRoutes.profileAbout)) {
      return 4;
    }
    return null;
  }

  int? _resolveCurrentIndex(BuildContext context) {
    if (currentIndex != null) return currentIndex;
    try {
      final location = GoRouterState.of(context).uri.toString();
      return resolveIndexFromLocation(location);
    } catch (_) {
      return null;
    }
  }

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    final activeIndex = _resolveCurrentIndex(context);
    // Bila menekan menu yang sudah aktif (kecuali tombol Catat), tidak perlu navigasi ulang
    if (activeIndex == index && index != 2) {
      return;
    }

    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.push(AppRoutes.transactions);
        break;
      case 2:
        context.push(AppRoutes.transactionRecordMethod);
        break;
      case 3:
        context.push(AppRoutes.goals);
        break;
      case 4:
        context.push(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sembunyikan navbar saat virtual keyboard muncul agar tidak menutupi input field
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    final activeIndex = _resolveCurrentIndex(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Floating Rounded Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFFE8EDF3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102A43).withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF102A43).withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Tab 0: Beranda
                      _NavSlot(
                        active: activeIndex == 0,
                        onTap: () => _handleTap(context, 0),
                        child: _NavContent(
                          assetPath: AppAssets.nav3dHome,
                          fallbackIcon: Icons.home_rounded,
                          label: AppStrings.navHome,
                          active: activeIndex == 0,
                        ),
                      ),
                      // Tab 1: Transaksi
                      _NavSlot(
                        active: activeIndex == 1,
                        onTap: () => _handleTap(context, 1),
                        child: _NavContent(
                          assetPath: AppAssets.nav3dTransaction,
                          fallbackIcon: Icons.swap_horiz_rounded,
                          label: AppStrings.navTransactions,
                          active: activeIndex == 1,
                        ),
                      ),
                      // Ruang simetris tengah untuk tombol Catat (+)
                      const Expanded(child: SizedBox()),
                      // Tab 3: Tujuan
                      _NavSlot(
                        active: activeIndex == 3,
                        onTap: () => _handleTap(context, 3),
                        child: _NavContent(
                          assetPath: AppAssets.nav3dGoal,
                          fallbackIcon: Icons.track_changes_rounded,
                          label: AppStrings.navGoals,
                          active: activeIndex == 3,
                        ),
                      ),
                      // Tab 4: Profil
                      _NavSlot(
                        active: activeIndex == 4,
                        onTap: () => _handleTap(context, 4),
                        child: _NavContent(
                          assetPath: AppAssets.nav3dProfile,
                          fallbackIcon: Icons.person_rounded,
                          label: AppStrings.navProfile,
                          active: activeIndex == 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tombol Catat (+) Floating Elevated di Tengah
              Positioned(
                top: 0,
                bottom: 0,
                child: Center(
                  child: _FloatingRecordButton(
                    onTap: () => _handleTap(context, 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slot satu tab dengan area sentuh nyaman (tinggi 68 dp, feedback ripple halus).
class _NavSlot extends StatelessWidget {
  const _NavSlot({
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: const Color(0xFF10B981).withValues(alpha: 0.12),
          highlightColor: const Color(0xFF10B981).withValues(alpha: 0.05),
          child: Container(
            height: 68,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Konten ikon 3D + label + indikator animasi active state.
class _NavContent extends StatelessWidget {
  const _NavContent({
    required this.assetPath,
    required this.fallbackIcon,
    required this.label,
    required this.active,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF8F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: active ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: 28,
              width: 28,
              child: Image.asset(
                assetPath,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                opacity: AlwaysStoppedAnimation(active ? 1.0 : 0.65),
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: 24,
                  color: active
                      ? const Color(0xFF10B981)
                      : const Color(0xFF718096),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: active ? const Color(0xFF10B981) : const Color(0xFF718096),
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: active ? 20 : 0,
            height: 3.5,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol Catat (+): lingkaran hijau elevated dengan ikon plus putih dan shadow emerald.
class _FloatingRecordButton extends StatefulWidget {
  const _FloatingRecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FloatingRecordButton> createState() => _FloatingRecordButtonState();
}

class _FloatingRecordButtonState extends State<_FloatingRecordButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('record_button'),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _pressed ? 0.93 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981),
                border: Border.all(color: Colors.white, width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  AppAssets.nav3dRecord,
                  key: const Key('record_button_icon'),
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            AppStrings.navRecord,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

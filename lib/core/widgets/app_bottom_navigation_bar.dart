import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../constants/glass_design_tokens.dart';
import '../routing/app_routes.dart';
import '../theme/glass.dart';

/// Navigasi utama Tahan Dulu dengan permukaan Liquid Glass mengambang.
///
/// Menghubungkan 5 tab utama (Beranda, Transaksi, Catat, Tujuan, Profil)
/// dengan indikator pill teranimasi halus, aset ikon 3D terpadu,
/// dan integrasi penuh dengan GoRouter.
class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key, this.currentIndex, this.onTap});

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

  static const _items = [
    (AppStrings.navHome, AppAssets.nav3dHome, Icons.home_rounded),
    (
      AppStrings.navTransactions,
      AppAssets.nav3dTransaction,
      Icons.swap_horiz_rounded,
    ),
    (AppStrings.navRecord, AppAssets.nav3dRecord, Icons.add_rounded),
    (AppStrings.navGoals, AppAssets.nav3dGoal, Icons.track_changes_rounded),
    (AppStrings.navProfile, AppAssets.nav3dProfile, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final selected = _resolveCurrentIndex(context);
    final scheme = context.palette;
    final height = 43 + MediaQuery.textScalerOf(context).scale(11) * 1.5;

    final navContent = SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / _items.length;
          return Stack(
            children: [
              if (selected != null &&
                  selected >= 0 &&
                  selected < _items.length)
                AnimatedPositionedDirectional(
                  duration: GlassDesignTokens.motionDuration(context),
                  curve: GlassDesignTokens.curve,
                  start: selected * width,
                  width: width,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: GlassDesignTokens.radiusCapsule,
                      color: scheme.primaryContainer,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: .26),
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in _items.indexed)
                    Expanded(
                      child: Semantics(
                        selected: index == selected,
                        button: true,
                        label: item.$1,
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            key: index == 2
                                ? const Key('record_button')
                                : null,
                            borderRadius:
                                GlassDesignTokens.radiusCapsule,
                            onTap: () => _handleTap(context, index),
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    item.$2,
                                    key: index == 2
                                        ? const Key(
                                            'record_button_icon',
                                          )
                                        : null,
                                    width: index == 2 ? 31 : 25,
                                    height: 31,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Icon(
                                      item.$3,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.$1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.3,
                                        fontWeight: index == selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: index == selected
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 5, 10, 8),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: Glass.panel(
              context,
              radius: GlassDesignTokens.radiusCapsule,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: navContent,
            ),
          ),
        ),
      ),
    );
  }
}

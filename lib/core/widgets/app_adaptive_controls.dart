import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' hide GlassQuality;

import '../constants/glass_design_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/glass.dart';

/// Sakelar adaptif: Light Mode memakai Material [Switch] asli,
/// Dark Mode memakai [GlassSwitch] resmi dari `liquid_glass_widgets`.
class AppAdaptiveSwitch extends StatelessWidget {
  const AppAdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return Switch(
        value: value,
        activeTrackColor: activeTrackColor,
        onChanged: onChanged,
      );
    }

    return GlassSwitch(
      useOwnLayer: true,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      settings: GlassDesignTokens.darkPlatterSettings(context),
    );
  }
}

/// Baris pengaturan dengan sakelar adaptif [AppAdaptiveSwitch].
class AppAdaptiveSwitchTile extends StatelessWidget {
  const AppAdaptiveSwitchTile({
    super.key,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.contentPadding,
  });

  final Widget? secondary;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return SwitchListTile(
        secondary: secondary,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        contentPadding: contentPadding,
      );
    }

    return ListTile(
      leading: secondary,
      title: title,
      subtitle: subtitle,
      contentPadding: contentPadding,
      trailing: AppAdaptiveSwitch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

/// Chip filter adaptif: Light Mode memakai kapsul border asli,
/// Dark Mode memakai [GlassChip] resmi dari `liquid_glass_widgets`.
class AppAdaptiveFilterChip extends StatelessWidget {
  const AppAdaptiveFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? context.palette.primary
                  : context.palette.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? context.palette.onPrimary
                          : context.palette.onSurface,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return GlassChip(
      useOwnLayer: true,
      label: label,
      icon: icon,
      selected: selected,
      selectedColor: AppColors.primary,
      onTap: onTap,
      settings: GlassDesignTokens.darkPlatterSettings(context),
      labelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

/// Tombol ikon adaptif untuk header/app bar/kartu:
/// Light Mode memakai [IconButton] asli, Dark Mode memakai [GlassIconButton] resmi.
class AppAdaptiveIconButton extends StatelessWidget {
  const AppAdaptiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 20,
    this.iconColor,
    this.tintColor,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
        color: iconColor,
      );
    }

    final btn = GlassIconButton(
      useOwnLayer: true,
      icon: icon,
      onPressed: onPressed,
      size: size,
      iconSize: iconSize,
      iconColor: iconColor ?? Colors.white,
      shape: GlassIconButtonShape.circle,
      style: GlassButtonStyle.transparent,
      tintColor: tintColor ?? const Color(0x16FFFFFF),
      settings: GlassDesignTokens.darkPlatterSettings(context),
      semanticLabel: tooltip,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// Item menu adaptif untuk [AppAdaptiveMenuButton].
class AppMenuOption<T> {
  const AppMenuOption({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool isDestructive;
}

/// Menu dropdown adaptif: Light Mode memakai [PopupMenuButton] asli,
/// Dark Mode memakai [GlassPullDownButton] + [GlassMenuItem] resmi.
class AppAdaptiveMenuButton<T> extends StatelessWidget {
  const AppAdaptiveMenuButton({
    super.key,
    required this.options,
    required this.onSelected,
    this.icon,
    this.tooltip,
  });

  final List<AppMenuOption<T>> options;
  final ValueChanged<T> onSelected;
  final Widget? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return PopupMenuButton<T>(
        tooltip: tooltip,
        icon: icon ??
            Icon(
              Icons.more_vert,
              size: 20,
              color: context.palette.onSurfaceVariant,
            ),
        onSelected: onSelected,
        itemBuilder: (ctx) => [
          for (final opt in options)
            PopupMenuItem<T>(
              value: opt.value,
              child: opt.icon == null
                  ? Text(
                      opt.label,
                      style: opt.isDestructive
                          ? TextStyle(color: context.palette.error)
                          : null,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 18,
                          color:
                              opt.isDestructive ? context.palette.error : null,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            opt.label,
                            style: opt.isDestructive
                                ? TextStyle(color: context.palette.error)
                                : null,
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      );
    }

    return GlassPullDownButton(
      icon: icon ?? const Icon(Icons.more_vert, size: 20, color: Colors.white),
      semanticLabel: tooltip ?? 'Menu opsi',
      buttonWidth: 44,
      buttonHeight: 44,
      menuWidth: 268,
      menuBorderRadius: 24,
      settings: GlassDesignTokens.darkOverlaySettings(context),
      items: [
        for (final opt in options)
          GlassMenuItem(
            title: opt.label,
            icon: opt.icon != null ? Icon(opt.icon, size: 18) : null,
            isDestructive: opt.isDestructive,
            onTap: () => onSelected(opt.value),
          ),
      ],
    );
  }
}

/// Pemilih tanggal adaptif:
/// - Light Mode: Flutter Material `showDatePicker` asli (100% tidak berubah).
/// - Dark Mode: `GlassModalSheet.show` berisi `GlassDatePicker.graphical` resmi
///   berbahasa Indonesia dengan aturan Rule 2 (`GlassSurfaceStyle.solid`).
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Pilih Tanggal',
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) {
  if (!GlassDesignTokens.isDarkGlass(context)) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: initialDatePickerMode,
    );
  }

  DateTime selected = initialDate;
  const monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  const weekdayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  return GlassModalSheet.show<DateTime>(
    context: context,
    detents: const {GlassSheetDetent.medium},
    initialState: GlassSheetState.half,
    halfSize: 0.68,
    topBorderRadius: AppRadius.xl,
    dragIndicatorColor: Colors.white.withValues(alpha: 0.35),
    settings: GlassDesignTokens.darkOverlaySettings(context),
    expandedColor: const Color(0xEC16222E),
    expandedDarkColor: const Color(0xEC16222E),
    builder: (sheetCtx) {
      return InheritedGlassSurfaceStyle(
        surfaceStyle: GlassSurfaceStyle.solid,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(null),
                      child: const Text('Batal'),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(selected),
                      child: Text(
                        'Pilih',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(sheetCtx).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GlassDatePicker.graphical(
                  initialDateTime: selected,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  firstDayOfWeek: 1,
                  monthNames: monthNames,
                  weekdayNames: weekdayNames,
                  tintColor: AppColors.primary,
                  surfaceStyle: GlassSurfaceStyle.solid,
                  onDateTimeChanged: (d) => selected = d,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

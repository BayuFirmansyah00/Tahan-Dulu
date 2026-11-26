import 'package:flutter/cupertino.dart';
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

/// Pemilih waktu adaptif:
/// - Light Mode: Flutter Material `showTimePicker` asli.
/// - Dark Mode: `GlassModalSheet.show` dengan `CupertinoDatePicker` mode waktu 24 jam.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Pilih Jam',
}) {
  if (!GlassDesignTokens.isDarkGlass(context)) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }

  final now = DateTime.now();
  DateTime selected = DateTime(
    now.year,
    now.month,
    now.day,
    initialTime.hour,
    initialTime.minute,
  );

  return GlassModalSheet.show<TimeOfDay>(
    context: context,
    detents: const {GlassSheetDetent.medium},
    initialState: GlassSheetState.half,
    halfSize: 0.42,
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
                      onPressed: () => Navigator.of(sheetCtx).pop(
                        TimeOfDay(
                          hour: selected.hour,
                          minute: selected.minute,
                        ),
                      ),
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
                SizedBox(
                  height: 190,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: selected,
                    onDateTimeChanged: (d) => selected = d,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Bilah pencarian adaptif:
/// - Light Mode: Material [TextField] asli.
/// - Dark Mode: [GlassSearchBar] resmi dengan efek kaca optik dan animasi clear.
class AppAdaptiveSearchBar extends StatelessWidget {
  const AppAdaptiveSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.query,
    required this.onChanged,
    this.clearTooltip = 'Hapus pencarian',
  });

  final TextEditingController controller;
  final String hintText;
  final String query;
  final ValueChanged<String> onChanged;
  final String clearTooltip;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_outlined),
                  tooltip: clearTooltip,
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        onChanged: onChanged,
      );
    }

    return GlassSearchBar(
      controller: controller,
      placeholder: hintText,
      useOwnLayer: true,
      surfaceStyle: GlassSurfaceStyle.glass,
      settings: GlassDesignTokens.darkInputSettings(context),
      height: 46,
      searchIconColor: Colors.white70,
      clearIconColor: Colors.white70,
      clearButtonSemanticLabel: clearTooltip,
      textStyle: const TextStyle(color: Colors.white, fontSize: 15),
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 15,
      ),
      onChanged: onChanged,
    );
  }
}

/// Dropdown / Pemilih nilai adaptif:
/// - Light Mode: Material [DropdownButtonFormField] asli (100% tidak berubah).
/// - Dark Mode: [GlassPicker] resmi yang membuka [GlassModalSheet] daftar opsi.
class AppAdaptiveDropdown<T> extends StatelessWidget {
  const AppAdaptiveDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.selectedItemBuilder,
    this.labelText,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.decoration,
    this.isExpanded = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final String? labelText;
  final String? hint;
  final Widget? prefixIcon;
  final String? Function(T?)? validator;
  final InputDecoration? decoration;
  final bool isExpanded;

  String _extractWidgetText(Widget widget) {
    if (widget is Text) return widget.data ?? '';
    if (widget is SingleChildRenderObjectWidget && widget.child != null) {
      return _extractWidgetText(widget.child!);
    }
    if (widget is ProxyWidget) return _extractWidgetText(widget.child);
    if (widget is MultiChildRenderObjectWidget) {
      return widget.children
          .map(_extractWidgetText)
          .where((s) => s.isNotEmpty)
          .join(' • ');
    }
    return '';
  }

  String _extractLabel(DropdownMenuItem<T> item) {
    final extracted = _extractWidgetText(item.child).trim();
    if (extracted.isNotEmpty) return extracted;
    return item.value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: isExpanded,
        decoration: decoration ??
            InputDecoration(
              labelText: labelText,
              hintText: hint,
              prefixIcon: prefixIcon,
            ),
        items: items,
        selectedItemBuilder: selectedItemBuilder,
        onChanged: onChanged,
        validator: validator,
      );
    }

    final effectiveLabel = labelText ?? decoration?.labelText;
    final effectiveHint = hint ?? decoration?.hintText ?? 'Pilih opsi';
    int selectedIndex = -1;
    DropdownMenuItem<T>? selectedItem;
    for (var i = 0; i < items.length; i++) {
      if (items[i].value == value) {
        selectedItem = items[i];
        selectedIndex = i;
        break;
      }
    }
    String? selectedText;
    if (selectedItem != null) {
      if (selectedItemBuilder != null && selectedIndex >= 0) {
        final built = selectedItemBuilder!(context);
        if (selectedIndex < built.length) {
          final extracted = _extractWidgetText(built[selectedIndex]).trim();
          if (extracted.isNotEmpty) selectedText = extracted;
        }
      }
      selectedText ??= _extractLabel(selectedItem);
    }

    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        return GlassFormField(
          label: effectiveLabel,
          errorText: field.errorText,
          child: GlassPicker(
            value: selectedText,
            placeholder: effectiveHint,
            useOwnLayer: true,
            surfaceStyle: GlassSurfaceStyle.glass,
            settings: GlassDesignTokens.darkInputSettings(context),
            shape: const LiquidRoundedRectangle(borderRadius: 14),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            placeholderStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 15,
            ),
            onTap: onChanged == null
                ? null
                : () async {
                    final picked = await GlassModalSheet.show<T>(
                      context: context,
                      detents: const {
                        GlassSheetDetent.medium,
                        GlassSheetDetent.large,
                      },
                      initialState: GlassSheetState.half,
                      halfSize: items.length > 5 ? 0.55 : 0.40,
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
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (effectiveLabel != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        4,
                                        20,
                                        10,
                                      ),
                                      child: Text(
                                        effectiveLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        20,
                                      ),
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                      itemBuilder: (_, idx) {
                                        final opt = items[idx];
                                        final isSelected = opt.value == value;
                                        return ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          title: DefaultTextStyle.merge(
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Theme.of(sheetCtx)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.white,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                            child: opt.child,
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  color: Theme.of(sheetCtx)
                                                      .colorScheme
                                                      .primary,
                                                )
                                              : null,
                                          onTap: () => Navigator.of(sheetCtx)
                                              .pop(opt.value),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    if (picked != null ||
                        items.any((e) => e.value == null && value != null)) {
                      field.didChange(picked);
                      onChanged?.call(picked);
                    }
                  },
          ),
        );
      },
    );
  }
}

/// AppBar adaptif:
/// - Light Mode: [AppBar] Material 3 asli.
/// - Dark Mode: [GlassAppBar] resmi tanpa latar kotak padat, tombol kaca melingkar.
class AppAdaptiveAppBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const AppAdaptiveAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.titleSpacing,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight = kToolbarHeight,
    this.bottom,
    this.flexibleSpace,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final double? titleSpacing;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final double toolbarHeight;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  bool shouldFullyObstruct(BuildContext context) =>
      !GlassDesignTokens.isDarkGlass(context);

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing,
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: toolbarHeight,
        bottom: bottom,
        flexibleSpace: flexibleSpace,
      );
    }

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final resolvedLeading = leading ??
        (automaticallyImplyLeading && canPop
            ? AppAdaptiveIconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    return GlassAppBar(
      title: title != null
          ? DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
              child: title!,
            )
          : null,
      leading: resolvedLeading,
      actions: actions,
      centerTitle: centerTitle ?? true,
      backgroundColor: const Color(0x8A0C141B),
      toolbarHeight: toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      buttonSettings: GlassDesignTokens.darkPlatterSettings(context),
      bottom: bottom,
    );
  }
}

/// Segmented control adaptif:
/// - Light Mode: Mempertahankan UI tab/chip asli lewat [lightBuilder].
/// - Dark Mode: [GlassSegmentedControl] resmi dengan indikator jelly optik.
class AppAdaptiveSegmentedControl<T> extends StatelessWidget {
  const AppAdaptiveSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    required this.lightBuilder,
    this.height = 44,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final WidgetBuilder lightBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context) || values.length < 2) {
      return lightBuilder(context);
    }

    final index = values.indexOf(selected);
    final safeIndex = index < 0 ? 0 : index;

    return GlassSegmentedControl(
      useOwnLayer: true,
      height: height,
      borderRadius: 22,
      backgroundColor: const Color(0x1E182634),
      indicatorColor: AppColors.primary.withValues(alpha: 0.78),
      settings: GlassDesignTokens.darkPlatterSettings(context),
      selectedTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      unselectedTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.75),
      ),
      segments: [
        for (final v in values) GlassSegment(label: labelBuilder(v)),
      ],
      selectedIndex: safeIndex,
      onSegmentSelected: (i) => onSelected(values[i]),
    );
  }
}

/// Tombol sekunder berbingkai adaptif:
/// - Light Mode: [OutlinedButton] / [OutlinedButton.icon] asli.
/// - Dark Mode: [GlassButton.custom] resmi dengan pegas sentuh dan sorotan Fresnel.
class AppAdaptiveOutlinedButton extends StatelessWidget {
  const AppAdaptiveOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.foregroundColor,
    this.borderColor,
    this.tintColor,
    this.height = 48,
    this.borderRadius = 24,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? tintColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: borderColor != null ? BorderSide(color: borderColor!) : null,
        minimumSize: Size(0, height),
      );
      if (icon != null) {
        return OutlinedButton.icon(
          style: style,
          onPressed: onPressed,
          icon: icon!,
          label: Text(label),
        );
      }
      return OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }

    final fg = foregroundColor ?? Colors.white;
    final disabled = onPressed == null;
    return SizedBox(
      height: height,
      child: GlassButton.custom(
        useOwnLayer: true,
        onTap: onPressed ?? () {},
        enabled: !disabled,
        surfaceStyle: GlassSurfaceStyle.glass,
        style: GlassButtonStyle.prominent,
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: GlassDesignTokens.darkPlatterSettings(context),
        tintColor: tintColor ??
            (borderColor?.withValues(alpha: 0.14) ?? const Color(0x16FFFFFF)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 18),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? fg.withValues(alpha: 0.45) : fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
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

/// Tombol aksi solid/tegas adaptif (mis. hapus, simpan di dialog):
/// - Light Mode: [ElevatedButton] / [ElevatedButton.icon] asli.
/// - Dark Mode: [GlassButton.custom] prominent dengan tint semantik dan animasi pegas.
class AppAdaptiveElevatedButton extends StatelessWidget {
  const AppAdaptiveElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 48,
    this.borderRadius = 24,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      final style = ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: Size(0, height),
      );
      if (icon != null) {
        return ElevatedButton.icon(
          style: style,
          onPressed: onPressed,
          icon: icon!,
          label: Text(label),
        );
      }
      return ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }

    final fg = foregroundColor ?? Colors.white;
    final bg = backgroundColor ?? AppColors.primary;
    final disabled = onPressed == null;
    return SizedBox(
      height: height,
      child: GlassButton.custom(
        useOwnLayer: true,
        onTap: onPressed ?? () {},
        enabled: !disabled,
        surfaceStyle: GlassSurfaceStyle.glass,
        style: GlassButtonStyle.prominent,
        shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
        settings: GlassDesignTokens.darkPlatterSettings(context),
        tintColor: bg.withValues(alpha: disabled ? 0.25 : 0.72),
        glowColor: bg.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fg, size: 18),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? fg.withValues(alpha: 0.5) : fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
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

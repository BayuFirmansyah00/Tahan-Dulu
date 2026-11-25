import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';

/// Helper untuk menampilkan Dialog bergaya Liquid Glass di Tahan Dulu.
///
/// Menggunakan `GlassDialog.show` dari library `liquid_glass_widgets`
/// dengan dukungan fallback aksesibilitas (Reduce Motion / High Contrast)
/// serta penyesuaian tombol aksi bernuansa Tahan Dulu.
Future<T?> showAppGlassDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  String? confirmLabel,
  VoidCallback? onConfirm,
  bool isDestructive = false,
  String cancelLabel = 'Batal',
  VoidCallback? onCancel,
  List<GlassDialogAction>? customActions,
  bool barrierDismissible = true,
}) {
  if (!GlassDesignTokens.isDarkGlass(context)) {
    // Light Mode atau mode aksesibilitas: Material Dialog asli
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : content,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onCancel?.call();
            },
            child: Text(cancelLabel),
          ),
          if (confirmLabel != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm?.call();
              },
              style: isDestructive
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(ctx).colorScheme.error,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
        ],
      ),
    );
  }

  final actions = customActions ??
      [
        GlassDialogAction(
          label: cancelLabel,
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
        ),
        if (confirmLabel != null)
          GlassDialogAction(
            label: confirmLabel,
            isPrimary: !isDestructive,
            isDestructive: isDestructive,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
      ];

  return GlassDialog.show<T>(
    context: context,
    title: title,
    message: message,
    content: content != null
        ? InheritedGlassSurfaceStyle(
            surfaceStyle: GlassSurfaceStyle.solid,
            child: content,
          )
        : null,
    settings: GlassDesignTokens.darkOverlaySettings(context),
    actions: actions,
  );
}

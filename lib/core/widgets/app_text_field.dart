import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/glass.dart';

/// Input standar TahanDulu:
/// - Light Mode: `TextFormField` Material 3 asli (100% tidak berubah).
/// - Dark Mode: [GlassFormField] + [GlassTextField] resmi dengan refraksi optik
///   dan validasi `FormField<String>`.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (GlassDesignTokens.isDarkGlass(context)) {
      return _DarkGlassFormInput(
        controller: controller,
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.palette.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _DarkGlassFormInput extends StatefulWidget {
  const _DarkGlassFormInput({
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;

  @override
  State<_DarkGlassFormInput> createState() => _DarkGlassFormInputState();
}

class _DarkGlassFormInputState extends State<_DarkGlassFormInput> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(covariant _DarkGlassFormInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncFromController);
      widget.controller?.addListener(_syncFromController);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromController());
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncFromController);
    super.dispose();
  }

  void _syncFromController() {
    final c = widget.controller;
    if (c == null) return;
    if (_fieldKey.currentState?.value != c.text) {
      _fieldKey.currentState?.didChange(c.text);
    }
  }

  Widget? _buildPrefix() {
    if (widget.prefixIcon == null && widget.prefixText == null) return null;
    if (widget.prefixIcon != null && widget.prefixText == null) {
      return Icon(widget.prefixIcon, size: 19, color: Colors.white70);
    }
    if (widget.prefixIcon == null && widget.prefixText != null) {
      return Text(
        widget.prefixText!.trimRight(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.prefixIcon, size: 19, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          widget.prefixText!.trimRight(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSuffix = widget.suffixIcon != null
        ? IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: Colors.white70,
                backgroundColor: Colors.transparent,
                side: BorderSide.none,
                minimumSize: const Size(24, 24),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
            ),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white70, size: 20),
              child: widget.suffixIcon!,
            ),
          )
        : null;

    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      builder: (field) {
        Widget input = GlassTextField(
          controller: widget.controller,
          placeholder: widget.hint,
          prefixIcon: _buildPrefix(),
          suffixIcon: effectiveSuffix,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
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
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.suffixIcon != null ? 11 : 14,
          ),
          onChanged: (value) {
            field.didChange(value);
            widget.onChanged?.call(value);
          },
        );

        if (widget.onTap != null) {
          input = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AbsorbPointer(
              absorbing: widget.readOnly,
              child: input,
            ),
          );
        }

        return GlassFormField(
          label: widget.label,
          errorText: field.errorText,
          child: input,
        );
      },
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../../data/datasources/remote/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/glass.dart';

/// Helper untuk menyelesaikan URL avatar (menangani relative path, localhost, emulator 10.0.2.2).
String resolveAvatarUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    if (ApiConfig.baseUrl.contains('10.0.2.2')) {
      return url
          .replaceAll('http://localhost:8000', 'http://10.0.2.2:8000')
          .replaceAll('http://127.0.0.1:8000', 'http://10.0.2.2:8000')
          .replaceAll('http://localhost', 'http://10.0.2.2');
    }
    return url;
  }
  // Relative path (misal: /storage/avatars/...)
  final base = ApiConfig.baseUrl.replaceAll('/api', '');
  final prefix = url.startsWith('/') ? '' : '/';
  return '$base$prefix$url';
}

/// Widget lingkaran avatar pengguna dengan fallback inisial teks dan badge kamera opsional.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 28,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.showEditBadge = false,
    this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final bool showEditBadge;
  final VoidCallback? onTap;

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Widget _buildFallback(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: textStyle ??
            TextStyle(
              color: fg,
              fontSize: radius * 0.8,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String url) {
    final resolved = resolveAvatarUrl(url);
    final isLocalFile = !resolved.startsWith('http://') && !resolved.startsWith('https://');

    Widget imageWidget;
    if (isLocalFile) {
      try {
        final file = File(resolved);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(context),
          );
        } else {
          imageWidget = _buildFallback(context);
        }
      } catch (_) {
        imageWidget = _buildFallback(context);
      }
    } else {
      imageWidget = Image.network(
        resolved,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    final content = hasAvatar ? _buildImage(context, avatarUrl!) : _buildFallback(context);

    Widget avatarCore = content;
    if (showEditBadge) {
      final badgeSize = (radius * 0.68).clamp(24.0, 36.0);
      avatarCore = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: context.palette.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.palette.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  AppAssets.setCameraBadge,
                  width: badgeSize - 4,
                  height: badgeSize - 4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.camera_alt_outlined,
                    size: badgeSize * 0.55,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarCore,
      );
    }

    return avatarCore;
  }
}

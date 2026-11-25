import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_providers.dart';
import '../utils/profile_ui.dart';

/// Menampilkan pratinjau foto profil ukuran besar dalam modal dialog.
void showProfilePhotoPreview(BuildContext context, {required String avatarUrl, required String name}) {
  final resolved = resolveAvatarUrl(avatarUrl);
  final isLocal = !resolved.startsWith('http://') && !resolved.startsWith('https://');

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: isLocal
                ? Image.file(
                    File(resolved),
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white54,
                    ),
                  )
                : Image.network(
                    resolved,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

/// Menampilkan bottom sheet aksi foto profil (Lihat, Ambil Kamera, Pilih Galeri, Hapus).
Future<void> showAvatarPickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  required UserModel user,
  required void Function(bool loading) onLoadingChanged,
}) async {
  final hasAvatar = user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
  final picker = ImagePicker();

  await showGlassSheet<void>(
    context: context,
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.palette.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto Profil',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              if (hasAvatar) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ctx.palette.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      color: ctx.palette.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Lihat Foto Profil',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showProfilePhotoPreview(
                      context,
                      avatarUrl: user.avatarUrl!,
                      name: user.name,
                    );
                  },
                ),
                const SizedBox(height: 6),
              ],

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ctx.palette.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: ctx.palette.secondary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Ambil Foto (Kamera)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      onLoadingChanged(true);
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .uploadAvatar(picked.path);
                      ref.invalidate(profileUserProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Foto profil berhasil diperbarui!'
                                  : 'Gagal memperbarui foto profil.',
                            ),
                            backgroundColor: ok ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e is ApiException ? e.message : 'Terjadi kesalahan: $e';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } finally {
                    onLoadingChanged(false);
                  }
                },
              ),
              const SizedBox(height: 6),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ctx.palette.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: ctx.palette.tertiary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      onLoadingChanged(true);
                      final ok = await ref
                          .read(authControllerProvider.notifier)
                          .uploadAvatar(picked.path);
                      ref.invalidate(profileUserProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Foto profil berhasil diperbarui!'
                                  : 'Gagal memperbarui foto profil.',
                            ),
                            backgroundColor: ok ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e is ApiException ? e.message : 'Terjadi kesalahan: $e';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } finally {
                    onLoadingChanged(false);
                  }
                },
              ),

              if (hasAvatar) ...[
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ctx.palette.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: ctx.palette.error,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Hapus Foto Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ctx.palette.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final confirmed = await showConfirmDialog(
                      context: context,
                      title: 'Hapus Foto Profil?',
                      message: 'Foto profil Anda akan dihapus dan diganti dengan inisial nama.',
                      cancelLabel: 'Batal',
                      confirmLabel: 'Ya, Hapus',
                      confirmColor: context.palette.error,
                      icon: Icons.delete_outline,
                    );
                    if (confirmed) {
                      onLoadingChanged(true);
                      try {
                        final ok = await ref
                            .read(authControllerProvider.notifier)
                            .deleteAvatar();
                        ref.invalidate(profileUserProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Foto profil berhasil dihapus.'
                                    : 'Gagal menghapus foto profil.',
                              ),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final msg = e is ApiException ? e.message : 'Terjadi kesalahan: $e';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        onLoadingChanged(false);
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

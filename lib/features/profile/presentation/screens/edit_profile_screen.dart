import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/user_model.dart';
import '../providers/profile_providers.dart';
import '../widgets/avatar_picker_sheet.dart';

/// Edit Profil: nama dapat diubah, email read-only, bio opsional.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  bool _saving = false;
  bool _bound = false;
  bool _avatarLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _bindOnData(UserModel? user) {
    if (_bound || user == null) return;
    _bound = true;
    // Mutasi provider di luar build (post-frame) agar tidak inkonsisten.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editProfileControllerProvider.notifier).load(user);
      _nameController.text = user.name;
      _emailController.text = user.email ?? '';
      _bioController.text = user.bio ?? '';
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (ref.read(editProfileControllerProvider).bio.length > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editProfileBioTooLong)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(editProfileControllerProvider.notifier).save();
      if (!mounted) return;
      if (ok) {
        ref.invalidate(profileUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.editProfileSaved),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.editProfileFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message =
          e is ApiException ? e.message : AppStrings.editProfileFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileUserProvider);
    user.whenData(_bindOnData);
    final draft = ref.watch(editProfileControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.editProfileTitle),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: user.when(
              data: (_) => Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header profil menyatu: ilustrasi menjadi latar tepat di
                      // belakang foto, avatar menumpuk di tepi bawah banner
                      // agar tidak tampil duplikat atas-bawah.
                      SizedBox(
                        height: 150 + 44,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                color: context.palette.primaryContainer,
                                child: Image.asset(
                                  AppAssets.illEditProfileBg,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Edit Profil',
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person_outline,
                                        size: 72,
                                        color: context.palette.primary,
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AppAvatar(
                                      name: draft.name,
                                      avatarUrl: user.value?.avatarUrl,
                                      radius: 44,
                                      showEditBadge: true,
                                      textStyle: textTheme.displayLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 36,
                                      ),
                                      onTap: _avatarLoading || user.value == null
                                          ? null
                                          : () => showAvatarPickerSheet(
                                                context,
                                                ref: ref,
                                                user: user.value!,
                                                onLoadingChanged: (l) {
                                                  if (mounted) setState(() => _avatarLoading = l);
                                                },
                                              ),
                                    ),
                                    if (_avatarLoading)
                                      Container(
                                        width: 88,
                                        height: 88,
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onPressed: _avatarLoading || user.value == null
                              ? null
                              : () => showAvatarPickerSheet(
                                    context,
                                    ref: ref,
                                    user: user.value!,
                                    onLoadingChanged: (l) {
                                      if (mounted) setState(() => _avatarLoading = l);
                                    },
                                  ),
                          icon: const Icon(Icons.image_outlined, size: 16),
                          label: const Text(AppStrings.editProfilePhoto),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _nameController,
                        label: AppStrings.editProfileName,
                        hint: AppStrings.editProfileNameHint,
                        validator: (v) => Validators.required(
                          v,
                          AppStrings.editProfileNameRequired,
                        ),
                        onChanged: (v) => ref
                            .read(editProfileControllerProvider.notifier)
                            .setName(v),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _emailController,
                        label: AppStrings.email,
                        readOnly: true,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: AppImageIcon(
                            assetPath: AppAssets.setSecurity,
                            size: 18,
                            fallbackIcon: Icons.lock_outline,
                          ),
                        ),
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.editProfileEmailFrozen,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _bioController,
                        label: AppStrings.editProfileBio,
                        hint: AppStrings.editProfileBioHint,
                        maxLines: 3,
                        onChanged: (v) {
                          ref
                              .read(editProfileControllerProvider.notifier)
                              .setBio(v);
                          setState(() {});
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_bioController.text.length}/120',
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: AppStrings.editProfileSave,
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(height: 8),
                      AppOutlineButton(
                        label: AppStrings.editProfileCancel,
                        onPressed: _saving ? null : () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(profileUserProvider),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../models/password_reset_flow.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final normalizedEmail = _emailController.text.trim();
      final info = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: normalizedEmail);
      if (!mounted) return;
      context.push(
        AppRoutes.verifyResetOtp,
        extra: PasswordResetOtpArgs(
          email: normalizedEmail,
          expiresInSeconds: info.expiresInSeconds,
          resendAfterSeconds: info.resendAfterSeconds,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.statusCode == 429
              ? 'Terlalu banyak permintaan. Coba lagi setelah beberapa saat.'
              : e.message,
        );
      }
    } on UnsupportedError catch (e) {
      if (mounted) setState(() => _error = e.message?.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Tidak dapat menghubungi server. Periksa koneksi.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
        leading: IconButton(
          tooltip: 'Kembali ke Login',
          onPressed: () => context.go(AppRoutes.login),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.forgotPasswordTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.forgotPasswordSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _emailController,
              label: AppStrings.email,
              hint: AppStrings.emailHint,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validators.email(
                value,
                requiredMessage: AppStrings.emailRequired,
                invalidMessage: AppStrings.emailInvalid,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: AppStrings.sendOtp,
              icon: Icons.mark_email_unread_outlined,
              isLoading: _submitting,
              onPressed: _submitting ? null : _requestOtp,
            ),
          ],
        ),
      ),
    );
  }
}

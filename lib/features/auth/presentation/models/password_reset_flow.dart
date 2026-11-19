class PasswordResetOtpArgs {
  const PasswordResetOtpArgs({
    required this.email,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  final String email;
  final int expiresInSeconds;
  final int resendAfterSeconds;
}

class PasswordResetTokenArgs {
  const PasswordResetTokenArgs({required this.resetToken});

  final String resetToken;
}

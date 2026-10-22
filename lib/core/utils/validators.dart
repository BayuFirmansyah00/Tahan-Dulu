/// Validator form sederhana. Bukan framework — fungsi per field.
abstract final class Validators {
  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    if (value == null || value.trim().isEmpty) return requiredMessage;
    if (!_emailPattern.hasMatch(value.trim())) return invalidMessage;
    return null;
  }
}

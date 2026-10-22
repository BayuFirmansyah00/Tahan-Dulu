import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('returns message for null/empty', () {
      expect(Validators.required(null, 'wajib'), 'wajib');
      expect(Validators.required('', 'wajib'), 'wajib');
      expect(Validators.required('   ', 'wajib'), 'wajib');
    });

    test('returns null for filled value', () {
      expect(Validators.required('Bayu', 'wajib'), isNull);
    });
  });

  group('Validators.email', () {
    test('returns required message when empty', () {
      expect(
        Validators.email(
          '',
          requiredMessage: AppStrings.emailRequired,
          invalidMessage: AppStrings.emailInvalid,
        ),
        AppStrings.emailRequired,
      );
    });

    test('returns invalid message for bad format', () {
      for (final bad in ['bayu', 'bayu@', 'bayu@email', '@email.com']) {
        expect(
          Validators.email(
            bad,
            requiredMessage: AppStrings.emailRequired,
            invalidMessage: AppStrings.emailInvalid,
          ),
          AppStrings.emailInvalid,
        );
      }
    });

    test('returns null for valid email', () {
      expect(
        Validators.email(
          'bayu@email.com',
          requiredMessage: AppStrings.emailRequired,
          invalidMessage: AppStrings.emailInvalid,
        ),
        isNull,
      );
    });
  });
}

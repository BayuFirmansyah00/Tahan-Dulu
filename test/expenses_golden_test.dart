import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/datasources/mock/mock_data.dart';
import 'package:tahan_dulu/data/models/user_model.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';

class _NotOnboardedAuthRepo extends MockAuthRepository {
  @override
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return MockData.user.copyWith(isOnboarded: false);
  }
}

/// Golden regresi visual No.5 pada viewport phone 390x844.
void main() {
  testWidgets('Expenses golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NotOnboardedAuthRepo()),
        ],
        child: const TahanDuluApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();

    // Step 1: Salary -> Lanjut
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.continueButton));
    await tester.pumpAndSettle();

    // Step 2: Instruments -> Lanjut
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.continueButton));
    await tester.pumpAndSettle();

    // Step 3: Budget -> Lanjut
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.continueButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.expensesTitle), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/expenses_screen.png'),
    );
  });
}

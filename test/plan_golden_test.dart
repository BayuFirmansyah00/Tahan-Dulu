import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/widgets/app_button.dart';
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

/// Golden regresi visual ringkasan rencana pada viewport phone 390x844.
void main() {
  testWidgets('Plan golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await initializeDateFormatting('id_ID');

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

    // Step 4: Expenses -> Lanjut
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.continueButton));
    await tester.pumpAndSettle();

    // Step 5: Goals -> Selesai
    await tester.tap(find.widgetWithText(AppButton, AppStrings.doneButton));
    await tester.pumpAndSettle();

    expect(find.text('Pemasukan Bulanan'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/plan_screen.png'),
    );

    // Scroll ke kartu aman & target untuk verifikasi visualnya.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/plan_screen_bottom.png'),
    );
  });
}

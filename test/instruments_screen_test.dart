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

/// No.4 — Pilih Instrumen Keuangan (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> Onboarding -> Salary (Step 1) -> Lanjut -> Instruments (Step 2).
Future<void> _pumpToInstruments(WidgetTester tester) async {
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
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);
}

int _checkCount(WidgetTester tester) {
  return tester
      .widgetList(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byIcon(Icons.check),
        ),
      )
      .length;
}

void main() {
  testWidgets('Instruments screen shows step 2 and title', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    expect(find.text(AppStrings.onboardingStep2), findsOneWidget);
    expect(find.text(AppStrings.instrumentsSubtitle), findsOneWidget);
  });

  testWidgets('Default instruments are shown with rupiah balances', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('Bank Jago'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('Rp5.000.000'), findsOneWidget);
    expect(find.text('Rp1.000.000'), findsOneWidget);
    expect(find.text('Rp500.000'), findsOneWidget);
  });

  testWidgets('BCA is pre-selected with check indicator', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);
    expect(_checkCount(tester), 1);
  });

  testWidgets('User can select another instrument', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    await _tapVisible(tester, find.text('Bank Jago'));
    expect(_checkCount(tester), 2);
  });

  testWidgets('Admin fee uses rupiah format', (WidgetTester tester) async {
    await _pumpToInstruments(tester);

    expect(find.text(AppStrings.instrumentDetail), findsNothing);
    // Panel detail milik BCA: fee 14.000.
    expect(find.textContaining('14.000'), findsWidgets);
  });

  testWidgets('Deselecting all shows validation and disables Lanjut', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    // BCA satu-satunya yang terpilih -> batalkan pilihan.
    await _tapVisible(tester, find.text('BCA'));

    expect(find.text(AppStrings.setupLater), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
      findsNothing,
    );
    expect(find.text(AppStrings.expensesTitle), findsNothing);
  });

  testWidgets('User can add an e-wallet instrument', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    await _tapVisible(tester, find.text(AppStrings.addInstrument));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.selectCategory), findsOneWidget);

    // Pilih tipe E-Wallet.
    await _tapVisible(tester, find.text(AppStrings.typeEWallet));
    await tester.pumpAndSettle();

    // Pilih provider OVO dari BankPickerSheet
    await _tapVisible(tester, find.text('OVO').last);
    await tester.pumpAndSettle();

    // Input saldo di form detail
    final balanceField = find.byType(TextFormField).at(1);
    await tester.enterText(balanceField, '250000');
    await tester.pump();
    await _tapVisible(tester, find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.text('OVO'), findsOneWidget);
    expect(find.text('Rp250.000'), findsOneWidget);
  });

  testWidgets('Lanjut saves instruments and goes to No.5', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingStep3), findsOneWidget);
  });

  testWidgets('Back returns to salary without losing data', (
    WidgetTester tester,
  ) async {
    await _pumpToInstruments(tester);

    await _tapVisible(tester, find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Kembali di No.3 dengan data utuh.
    expect(find.text(AppStrings.salaryTitle), findsOneWidget);
    expect(find.text('5.000.000'), findsOneWidget);
  });
}

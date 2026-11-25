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

/// Layar ringkasan rencana (mock repository, tanpa backend).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> Onboarding Steps 1 to 5 -> PlanScreen (Step 6).
Future<void> _pumpToPlan(WidgetTester tester) async {
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

  // Step 1: Salary -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 2: Instruments -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 3: Budget -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 4: Expenses -> Lanjut
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.continueButton),
  );
  await tester.pumpAndSettle();

  // Step 5: Goals -> Selesai
  await _tapVisible(
    tester,
    find.widgetWithText(AppButton, AppStrings.doneButton),
  );
  await tester.pumpAndSettle();

  expect(find.text('Pemasukan Bulanan'), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Plan shows income and canonical allocation', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text('Pemasukan Bulanan'), findsOneWidget);
    expect(find.text('Rp5.000.000'), findsWidgets);
    expect(find.text('Alokasi Bulanan'), findsOneWidget);
    expect(find.text('Kebutuhan'), findsOneWidget);
    expect(find.text('Rp2.500.000'), findsWidgets);
    expect(find.text('Pengeluaran Fleksibel'), findsOneWidget);
    expect(find.text('Investasi & Tabungan'), findsOneWidget);
    expect(find.text('Dana Darurat'), findsOneWidget);
  });

  testWidgets('Safe per day card matches design', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text('Batas Belanja Harian'), findsOneWidget);
    expect(find.textContaining('budget belanja yang aman digunakan hari ini'), findsOneWidget);
  });

  testWidgets('Goal card shows monthly investment target', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    expect(find.text('Target Investasi'), findsOneWidget);
    expect(find.textContaining('/ bulan'), findsWidgets);
    expect(find.text(AppStrings.planAdjustable), findsOneWidget);
  });

  testWidgets('Start button goes to dashboard', (
    WidgetTester tester,
  ) async {
    await _pumpToPlan(tester);

    await _tapVisible(tester, find.textContaining(AppStrings.startAppButton));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    expect(find.text('Bayu'), findsOneWidget);
  });
}

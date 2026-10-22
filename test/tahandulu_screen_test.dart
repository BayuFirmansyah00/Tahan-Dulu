import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

/// Login mock -> onboarding -> dashboard -> kartu Lihat TahanDulu.
Future<void> _pumpToTahanDulu(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
  final loginFields = find.byType(TextFormField);
  await tester.enterText(loginFields.at(0), 'bayu@email.com');
  await tester.enterText(loginFields.at(1), 'rahasia123');
  await tester.pump();
  await _tapVisible(tester, find.text(AppStrings.loginWithEmail));
  await tester.pumpAndSettle();

  for (var i = 0; i < 3; i++) {
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueButton),
    );
    await tester.pumpAndSettle();
  }
  await _tapVisible(
    tester,
    find.widgetWithText(ElevatedButton, AppStrings.doneButton),
  );
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.startAppButton));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.text(AppStrings.tahanDuluSee));
  await tester.pumpAndSettle();
  expect(find.text(AppStrings.tahanDuluPageTitle), findsOneWidget);
}

/// Isi form manual valid (nama, harga, kategori default).
Future<void> _fillProductForm(
  WidgetTester tester, {
  String name = 'Headset Sony',
  String price = '1000000',
}) async {
  final fields = find.byType(TextFormField);
  await tester.ensureVisible(fields.at(0));
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), price);
  await tester.pump();
}

void main() {
  testWidgets('List shows tabs, seed item, and education card', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);

    expect(find.text(AppStrings.tahanDuluPageSubtitle), findsOneWidget);
    expect(find.textContaining('Menunggu (1)'), findsOneWidget);
    expect(find.textContaining('Wishlist (0)'), findsOneWidget);
    expect(find.textContaining('Selesai (0)'), findsOneWidget);
    expect(find.text('Adidas Samba'), findsOneWidget);
    expect(find.text('Rp750.000'), findsOneWidget);
    expect(find.text(AppStrings.addItemAction), findsOneWidget);
    expect(find.text(AppStrings.tahanDuluEduTitle), findsOneWidget);
  });

  testWidgets('Tabs filter by status', (WidgetTester tester) async {
    await _pumpToTahanDulu(tester);

    await _tapVisible(tester, find.textContaining('Wishlist ('));
    expect(find.text('Adidas Samba'), findsNothing);
    expect(find.text(AppStrings.emptyTahanDulu), findsOneWidget);

    await _tapVisible(tester, find.textContaining('Menunggu ('));
    expect(find.text('Adidas Samba'), findsOneWidget);
  });

  testWidgets('Empty validation blocks analysis', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.methodManual));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.analyzeAction),
    );

    expect(find.text(AppStrings.productNameRequired), findsOneWidget);
    expect(find.text(AppStrings.productPriceRequired), findsOneWidget);
    expect(find.text(AppStrings.reviewFirstTitle), findsNothing);
  });

  testWidgets('Link method validates url and prefills form', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.methodLink));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'bukan-url');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueAction),
    );
    expect(find.text(AppStrings.productUrlInvalid), findsOneWidget);

    await tester.enterText(fields.at(0), 'https://tokopedia.com/x');
    await tester.pump();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.continueAction),
    );
    await tester.pumpAndSettle();

    // Form terbuka dengan URL terbawa.
    expect(find.text('https://tokopedia.com/x'), findsOneWidget);
  });

  testWidgets('Photo method honestly unavailable', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.comingSoonBadge), findsOneWidget);
    await _tapVisible(tester, find.text(AppStrings.methodPhoto));
    await tester.pump();
    expect(find.text(AppStrings.photoComingSoon), findsOneWidget);
  });

  testWidgets('Full flow to analysis shows real budget numbers', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.methodManual));
    await tester.pumpAndSettle();
    await _fillProductForm(tester);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.analyzeAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reviewFirstTitle), findsOneWidget);
    expect(find.text('Headset Sony'), findsWidgets);
    // 1jt / 1,25jt = 80%.
    expect(find.textContaining('80%'), findsOneWidget);
    expect(find.text(AppStrings.simulateImpactAction), findsOneWidget);
  });

  testWidgets('Back from analysis preserves draft inputs', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.methodManual));
    await tester.pumpAndSettle();
    await _fillProductForm(tester);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.analyzeAction),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reviewFirstTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Headset Sony'), findsOneWidget);
    expect(find.text('1.000.000'), findsOneWidget);
  });

  testWidgets('Wait saves timestamps then decide flow', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text(AppStrings.addItemAction));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.methodManual));
    await tester.pumpAndSettle();
    await _fillProductForm(tester);
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.analyzeAction),
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.simulateImpactAction),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.tahanDuluSimulateTitle), findsOneWidget);

    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.waitDurationLabel),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.waitTitle), findsOneWidget);

    await _tapVisible(tester, find.text(AppStrings.wait48));
    await _tapVisible(
      tester,
      find.widgetWithText(ElevatedButton, AppStrings.saveAndWaitAction),
    );
    await tester.pumpAndSettle();

    // Kembali di daftar; penghitung bertambah.
    expect(find.text(AppStrings.tahanDuluPageTitle), findsOneWidget);
    expect(find.textContaining('Menunggu (2)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Buy decision marks bought without auto transaction', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    Future<void> tapV(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TahanDuluApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tapV(find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tapV(
        find.widgetWithText(ElevatedButton, AppStrings.continueButton),
      );
      await tester.pumpAndSettle();
    }
    await tapV(
      find.widgetWithText(ElevatedButton, AppStrings.doneButton),
    );
    await tester.pumpAndSettle();
    await tapV(find.text(AppStrings.startAppButton));
    await tester.pumpAndSettle();

    final txBefore = await tester.runAsync(() => container
        .read(transactionRepositoryProvider)
        .getRecentTransactions()
        .then((l) => l.length));

    // Buka kartu seed (tanpa wait aktif -> langsung decide).
    await tapV(find.text(AppStrings.tahanDuluSee));
    await tester.pumpAndSettle();
    await tapV(find.text('Adidas Samba'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.decideTitle), findsOneWidget);

    await tapV(find.text(AppStrings.decideBuy));
    await tester.pumpAndSettle();
    await tapV(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.decideBuy),
      ),
    );
    // Dialog + repo async butuh advance eksplisit (settle bisa kembali
    // lebih dulu saat rantai microtask/dialog masih berjalan).
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.successBuyTitle), findsOneWidget);

    final txAfter = await tester.runAsync(() => container
        .read(transactionRepositoryProvider)
        .getRecentTransactions()
        .then((l) => l.length));
    expect(txAfter, txBefore);

    await tapV(find.text(AppStrings.seeTransactionsAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.transactionsTitle), findsWidgets);

    await tapV(
      find.descendant(
        of: find.byType(DashboardBottomNav),
        matching: find.text(AppStrings.navHome),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.dashboardGreeting), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Wishlist and cancel move items to right tabs', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);
    await _tapVisible(tester, find.text('Adidas Samba'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.decideWishlist));
    // Advance eksplisit: rantai async repo bisa mulai setelah settle
    // memeriksa quiescence (microtask race).
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Aksi wishlist menavigasi kembali ke daftar via go.
    expect(find.text(AppStrings.tahanDuluPageTitle), findsOneWidget);
    await _tapVisible(tester, find.textContaining('Wishlist ('));
    await tester.pumpAndSettle();
    expect(find.text('Adidas Samba'), findsOneWidget);
    await _tapVisible(tester, find.text('Adidas Samba'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.decideCancel));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.decideCancel),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.textContaining('Selesai ('));
    await tester.pumpAndSettle();
    expect(find.text('Adidas Samba'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Bottom navigation stays consistent', (
    WidgetTester tester,
  ) async {
    await _pumpToTahanDulu(tester);

    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navRecord), findsOneWidget);
    expect(find.text(AppStrings.navGoals), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);
  });
}

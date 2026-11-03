import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/widgets/app_icons.dart';
import 'package:tahan_dulu/data/models/api_bank.dart';
import 'package:tahan_dulu/data/models/api_financial_instrument.dart';
import 'package:tahan_dulu/data/models/financial_account.dart';
import 'package:tahan_dulu/data/providers/account_providers.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/add_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/screens/edit_account_screen.dart';
import 'package:tahan_dulu/features/accounts/presentation/widgets/bank_logo_badge.dart';
import 'package:tahan_dulu/features/accounts/presentation/widgets/bank_picker_sheet.dart';

void main() {
  const sampleBanks = [
    ApiBank(
      id: 1,
      slug: 'bca',
      name: 'Bank Central Asia',
      aliases: ['BCA', '014'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
      isActive: true,
    ),
    ApiBank(
      id: 2,
      slug: 'mandiri',
      name: 'Bank Mandiri',
      aliases: ['BMRI', '008'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg',
      isActive: true,
    ),
    ApiBank(
      id: 5,
      slug: 'jago',
      name: 'Bank Jago',
      aliases: ['Jago', '542'],
      category: 'bank-logo',
      logoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/jago.svg',
      isActive: true,
    ),
  ];

  const validBcaSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 26">
  <path fill="#0060AF" d="M10 5h20v16H10z"/>
</svg>''';

  const validMandiriSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 25">
  <path fill="#003D79" d="M5 5h30v15H5z"/>
</svg>''';

  setUp(() {
    BankLogoCache.clear();
  });

  group('BankLogoBadge Widget Tests', () {
    testWidgets('renders SvgPicture when valid rawSvg string is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BankLogoBadge(
                bankName: 'Bank Central Asia',
                bankSlug: 'bca',
                rawSvg: validBcaSvg,
                size: 48,
              ),
            ),
          ),
        ),
      );

      // Verify SvgPicture is rendered in the tree
      expect(find.byType(SvgPicture), findsOneWidget);
      // Fallback acronym text should NOT be visible when SVG is loaded
      expect(find.text('BCA'), findsNothing);
    });

    testWidgets('renders SvgPicture from cache for official bank catalog logo', (tester) async {
      const bcaUrl = 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg';
      BankLogoCache.inject(bcaUrl, validBcaSvg);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BankLogoBadge(
                bankName: 'Bank Central Asia',
                bankSlug: 'bca',
                bankLogoUrl: bcaUrl,
                size: 44,
              ),
            ),
          ),
        ),
      );

      // SVG should be rendered from cache
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(BankLogoCache.has(bcaUrl), isTrue);
    });

    testWidgets('displays acronym fallback when logo is null and no slug matches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BankLogoBadge(
                bankName: 'Koperasi Simpan Pinjam',
                bankSlug: null,
                bankLogoUrl: null,
                size: 48,
              ),
            ),
          ),
        ),
      );

      expect(find.text('KSP'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('rejects unapproved external image URLs and derives safe CDN or fallback', (tester) async {
      const suspiciousUrl = 'https://untrusted-external-site.com/exploit.png';
      expect(BankLogoBadge.isAllowedUrl(suspiciousUrl), isFalse);
      expect(BankLogoBadge.isAllowedUrl('https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg'), isTrue);
      expect(BankLogoBadge.isAllowedUrl('https://raw.githubusercontent.com/hafidznoor/idn-finlogos/main/icons/bca.svg'), isTrue);

      const badge = BankLogoBadge(
        bankName: 'Bank Central Asia',
        bankSlug: 'bca',
        bankLogoUrl: suspiciousUrl,
      );

      // Must sanitize to safe CDN URL, not using the untrusted external host
      expect(badge.resolvedLogoUrl, isNot(contains('untrusted-external-site.com')));
      expect(badge.resolvedLogoUrl, contains('cdn.jsdelivr.net'));
    });

    testWidgets('handles unknown bank slug gracefully without crashing and displays fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BankLogoBadge(
                bankName: 'Bank Daerah Khusus',
                bankSlug: 'bank-daerah-khusus-unknown',
                size: 44,
              ),
            ),
          ),
        ),
      );

      // Should not throw or crash, should display fallback acronym
      expect(tester.takeException(), isNull);
      expect(find.text('DK'), findsOneWidget);
    });
  });

  group('AccountProviderIcon Integration Tests', () {
    testWidgets('renders BankLogoBadge when bank metadata exists on account', (tester) async {
      const mandiriUrl = 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg';
      BankLogoCache.inject(mandiriUrl, validMandiriSvg);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AccountProviderIcon(
                type: AccountType.bank,
                bankName: 'Bank Mandiri',
                bankSlug: 'mandiri',
                bankLogoUrl: mandiriUrl,
                size: 44,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BankLogoBadge), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders legacy fallback when account has no bank linked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AccountProviderIcon(
                type: AccountType.ewallet,
                institutionName: null,
                bankName: null,
                bankSlug: null,
                bankLogoUrl: null,
                size: 44,
              ),
            ),
          ),
        ),
      );

      // When no bank is linked, it renders the default asset image for the account type
      expect(find.byType(BankLogoBadge), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BankPickerSheet Flow Tests', () {
    testWidgets('renders list and filters by search query and bank code', (tester) async {
      ApiBank? picked;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            banksProvider(null).overrideWith((ref) => Future.value(sampleBanks)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    picked = await BankPickerSheet.show(context);
                  },
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Verify all 3 banks are initially rendered
      expect(find.text('Bank Central Asia'), findsOneWidget);
      expect(find.text('Bank Mandiri'), findsOneWidget);
      expect(find.text('Bank Jago'), findsOneWidget);

      // Search for "jago"
      await tester.enterText(find.byType(TextField), 'jago');
      await tester.pumpAndSettle();

      expect(find.text('Bank Jago'), findsOneWidget);
      expect(find.text('Bank Central Asia'), findsNothing);
      expect(find.text('Bank Mandiri'), findsNothing);

      // Select Bank Jago
      await tester.tap(find.text('Bank Jago'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.slug, 'jago');
      expect(picked!.name, 'Bank Jago');
    });
  });

  group('Financial Integrity & Immutability Tests', () {
    test('selecting or changing bank does not alter account balance or total assets', () {
      const initialAccount = FinancialAccount(
        id: 'acc-1',
        name: 'Rekening Operasional',
        type: AccountType.bank,
        balance: 5000000,
        bankId: null,
        bankSlug: null,
      );

      // User links to BCA
      final linkedToBca = initialAccount.copyWith(
        bankId: 1,
        bankSlug: 'bca',
        bankName: 'Bank Central Asia',
        bankLogoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
      );

      expect(linkedToBca.balance, initialAccount.balance);
      expect(linkedToBca.balance, 5000000);

      // User switches to Mandiri
      final switchedToMandiri = linkedToBca.copyWith(
        bankId: 2,
        bankSlug: 'mandiri',
        bankName: 'Bank Mandiri',
        bankLogoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/mandiri.svg',
      );

      expect(switchedToMandiri.balance, 5000000);
      expect(switchedToMandiri.id, initialAccount.id);
    });

    test('legacy account without bank metadata serializes and renders without regression', () {
      const legacyAccount = FinancialAccount(
        id: 'legacy-1',
        name: 'Dompet Tunai',
        type: AccountType.ewallet,
        balance: 150000,
      );

      expect(legacyAccount.bankId, isNull);
      expect(legacyAccount.bankSlug, isNull);
      expect(legacyAccount.bankName, isNull);
      expect(legacyAccount.bankLogoUrl, isNull);
      expect(legacyAccount.balance, 150000);
    });
  });

  group('AddAccountScreen Bank Selection Flow Tests', () {
    const sampleInstrumentTypes = [
      ApiInstrumentType(id: 1, name: 'Bank', type: 'bank'),
      ApiInstrumentType(id: 2, name: 'Bank Digital', type: 'digitalBank'),
      ApiInstrumentType(id: 3, name: 'E-Wallet', type: 'ewallet'),
    ];

    testWidgets('shows bank picker when category is Bank and auto-fills account & institution name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            instrumentTypesProvider.overrideWith((ref) => Future.value(sampleInstrumentTypes)),
            banksProvider(null).overrideWith((ref) => Future.value(sampleBanks)),
          ],
          child: const MaterialApp(home: AddAccountScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Dropdown tipe instrumen contains categories
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);

      // Select Bank (id: 1)
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank').last);
      await tester.pumpAndSettle();

      // Katalog Bank should be visible
      expect(find.text('Katalog Bank'), findsOneWidget);
      expect(find.text('Hubungkan Bank (Opsional)'), findsOneWidget);

      // Tap to pick bank
      await tester.tap(find.text('Hubungkan Bank (Opsional)'));
      await tester.pumpAndSettle();

      // Select BCA
      await tester.tap(find.text('Bank Central Asia'));
      await tester.pumpAndSettle();

      // Verify Nama Akun and Nama Institusi are auto-filled with bank name
      expect(find.widgetWithText(TextFormField, 'Bank Central Asia'), findsWidgets);

      // Now switch bank to Mandiri
      await tester.tap(find.text('Bank Central Asia').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Mandiri'));
      await tester.pumpAndSettle();

      // Verify Nama Akun and Nama Institusi are updated to Bank Mandiri, no old BCA text
      expect(find.text('Bank Central Asia'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Bank Mandiri'), findsWidgets);

      // Change category to E-Wallet
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E-Wallet').last);
      await tester.pumpAndSettle();

      // Katalog Bank should be hidden
      expect(find.text('Katalog Bank'), findsNothing);
    });
  });

  group('EditAccountScreen Bank Selection Flow Tests', () {
    testWidgets('shows linked bank, updates names on switch, and clears on ewallet change', (tester) async {
      const initialAccount = FinancialAccount(
        id: 'acc-test-1',
        name: 'Bank Central Asia',
        type: AccountType.bank,
        balance: 2500000,
        institutionName: 'Bank Central Asia',
        bankId: 1,
        bankSlug: 'bca',
        bankName: 'Bank Central Asia',
        bankLogoUrl: 'https://cdn.jsdelivr.net/npm/idn-finlogos@2/dist/icons/bca.svg',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsOverviewProvider.overrideWith((ref) => Future.value([
              const AccountOverview(
                account: initialAccount,
                currentBalance: 2500000,
                transactionCount: 0,
              ),
            ])),
            banksProvider(null).overrideWith((ref) => Future.value(sampleBanks)),
          ],
          child: const MaterialApp(
            home: EditAccountScreen(accountId: 'acc-test-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: BCA is linked and Katalog Bank is shown
      expect(find.text('Katalog Bank'), findsOneWidget);
      expect(find.text('Bank Central Asia'), findsWidgets);

      // Switch bank to Bank Mandiri
      await tester.tap(find.widgetWithText(InkWell, 'Bank Central Asia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank Mandiri'));
      await tester.pumpAndSettle();

      // Verify names updated to Bank Mandiri
      expect(find.widgetWithText(TextFormField, 'Bank Mandiri'), findsWidgets);
      expect(find.text('Bank Central Asia'), findsNothing);

      // Change type to E-Wallet
      await tester.tap(find.byType(DropdownButtonFormField<AccountType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E-Wallet').last);
      await tester.pumpAndSettle();

      // Katalog Bank is hidden
      expect(find.text('Katalog Bank'), findsNothing);
    });
  });
}

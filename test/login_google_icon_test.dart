import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

void main() {
  test('aset Google login lokal tersedia dan terdaftar', () {
    expect(
      AppAssets.setGoogle,
      'assets/icons/icon_google_login.png',
    );
    expect(
      File(AppAssets.setGoogle).existsSync(),
      isTrue,
      reason: 'File ${AppAssets.setGoogle} harus ada di disk',
    );
  });

  testWidgets('tombol Login Google memakai Image.asset lokal 24px', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(find.text(AppStrings.loginHeadline), findsOneWidget);
    expect(find.text(AppStrings.continueWithGoogle), findsOneWidget);

    final iconFinder = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == AppAssets.setGoogle,
    );
    expect(iconFinder, findsOneWidget);

    final image = tester.widget<Image>(iconFinder);
    expect(image.width, 24);
    expect(image.height, 24);
    expect(image.fit, BoxFit.contain);
  });
}

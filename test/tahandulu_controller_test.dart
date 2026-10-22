import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/utils/finance_math.dart';
import 'package:tahan_dulu/data/models/purchase_consideration.dart';
import 'package:tahan_dulu/data/providers/app_providers.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/providers/tahandulu_controller.dart';
import 'package:tahan_dulu/features/tahandulu/presentation/utils/tahandulu_ui.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('draft validates name, price, url', () {
    final container = _container();
    final notifier = container.read(tahanDuluControllerProvider.notifier);

    expect(
      container.read(tahanDuluControllerProvider).isComplete,
      isFalse,
    );
    notifier.setName('Adidas Samba');
    notifier.setPrice(0);
    expect(
      container.read(tahanDuluControllerProvider).isComplete,
      isFalse,
    );
    notifier.setPrice(750000);
    notifier.setUrl('bukan-url');
    expect(
      container.read(tahanDuluControllerProvider).isComplete,
      isFalse,
    );
    notifier.setUrl('https://tokopedia.com/x');
    expect(
      container.read(tahanDuluControllerProvider).isComplete,
      isTrue,
    );
  });

  test('url validation accepts http(s) with host only', () {
    expect(isValidProductUrl('https://tokopedia.com/a'), isTrue);
    expect(isValidProductUrl('http://x.id'), isTrue);
    expect(isValidProductUrl('ftp://x.id'), isFalse);
    expect(isValidProductUrl('tokopedia.com/a'), isFalse);
    expect(isValidProductUrl(''), isFalse);
  });

  test('saveDraft creates then updates without duplication', () async {
    final container = _container();
    final notifier = container.read(tahanDuluControllerProvider.notifier);
    notifier.setName('Headset');
    notifier.setPrice(1000000);
    notifier.setCategory(ProductCategory.electronics);

    final created = await notifier.saveDraft();
    expect(created, isNotNull);
    expect(created!.status, ConsiderationStatus.considering);

    notifier.setPrice(900000);
    final updated = await notifier.saveDraft();
    expect(updated!.id, created.id);
    expect(updated.price, 900000);

    final repo = container.read(purchaseDecisionRepositoryProvider);
    final items = await repo.getConsiderations();
    expect(
      items.where((e) => e.itemName == 'Headset').length,
      1,
    );
  });

  test('concurrent saveDraft stores single item', () async {
    final container = _container();
    final notifier = container.read(tahanDuluControllerProvider.notifier);
    notifier.setName('Kamera');
    notifier.setPrice(2000000);

    final results =
        await Future.wait([notifier.saveDraft(), notifier.saveDraft()]);
    expect(results.where((e) => e != null).length, 1);
  });

  test('status transitions wishlist and cancel', () async {
    final container = _container();
    final notifier = container.read(tahanDuluControllerProvider.notifier);
    notifier.setName('Tas');
    notifier.setPrice(500000);
    final created = (await notifier.saveDraft())!;

    expect(
      await notifier.setStatus(created.id, ConsiderationStatus.wishlist),
      isTrue,
    );
    var items =
        await container.read(purchaseDecisionRepositoryProvider).getConsiderations();
    expect(
      items.firstWhere((e) => e.id == created.id).status,
      ConsiderationStatus.wishlist,
    );

    expect(
      await notifier.setStatus(created.id, ConsiderationStatus.cancelled),
      isTrue,
    );
    items =
        await container.read(purchaseDecisionRepositoryProvider).getConsiderations();
    expect(
      items.firstWhere((e) => e.id == created.id).status,
      ConsiderationStatus.cancelled,
    );
  });

  test('startWait stores explicit timestamps', () async {
    final container = _container();
    final notifier = container.read(tahanDuluControllerProvider.notifier);
    notifier.setName('Sepatu');
    notifier.setPrice(750000);
    final created = (await notifier.saveDraft())!;

    final start = DateTime(2026, 10, 12, 10, 0);
    expect(await notifier.startWait(created.id, 48, now: start), isTrue);

    final items =
        await container.read(purchaseDecisionRepositoryProvider).getConsiderations();
    final item = items.firstWhere((e) => e.id == created.id);
    expect(item.waitHours, 48);
    expect(item.waitStartedAt, start);
    expect(item.waitEndsAt, start.add(const Duration(hours: 48)));
    expect(item.isWaitingAt(start.add(const Duration(hours: 1))), isTrue);
    expect(item.isWaitingAt(start.add(const Duration(hours: 49))), isFalse);
  });

  test('wait remaining formatting', () {
    final now = DateTime(2026, 10, 12, 10, 0);
    expect(
      formatWaitRemaining(now.add(const Duration(hours: 18, minutes: 42)), now),
      '18:42:00',
    );
    expect(
      formatWaitRemaining(now.add(const Duration(hours: 50)), now),
      '2 hari lagi',
    );
    expect(formatWaitRemaining(now, now), 'Selesai');
    expect(
      formatWaitRemaining(now.subtract(const Duration(hours: 1)), now),
      'Selesai',
    );
  });

  test('budget share and delay math', () {
    // 750rb / 2jt = 37,5%.
    expect(
      purchaseBudgetShare(price: 750000, flexible: 2000000),
      closeTo(0.375, 0.0001),
    );
    expect(purchaseBudgetShare(price: 100, flexible: 0), isNull);
    // 750rb / 1,25jt x 30 = 18 hari.
    expect(
      targetDelayDays(price: 750000, monthlyContribution: 1250000),
      18,
    );
    expect(
      targetDelayDays(price: 750000, monthlyContribution: 0),
      isNull,
    );
  });
}

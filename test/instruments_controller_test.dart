import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/models/financial_instrument.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/instruments_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initial state has canonical defaults, BCA selected', () {
    final state = _container().read(instrumentsControllerProvider);

    expect(state.instruments.length, 3);
    expect(state.instruments[0].name, 'BCA');
    expect(state.instruments[0].monthlyAdminFee, 14000);
    expect(state.instruments[0].adminFeeDay, 15);
    expect(state.instruments[0].isSelected, isTrue);
    expect(state.instruments[1].isSelected, isFalse);
    expect(state.canContinue, isTrue);
  });

  test('toggleSelect selects and deselects', () {
    final container = _container();
    final notifier = container.read(instrumentsControllerProvider.notifier);

    notifier.toggleSelect('inst-jago');
    expect(
      container
          .read(instrumentsControllerProvider)
          .instruments[1]
          .isSelected,
      isTrue,
    );

    notifier.toggleSelect('inst-bca');
    notifier.toggleSelect('inst-jago');
    final state = container.read(instrumentsControllerProvider);
    expect(state.selected, isEmpty);
    expect(state.canContinue, isFalse);
  });

  test('updateAdminFee and updateAdminFeeDay work', () {
    final container = _container();
    final notifier = container.read(instrumentsControllerProvider.notifier);

    notifier.updateAdminFee('inst-bca', 20000);
    notifier.updateAdminFeeDay('inst-bca', 20);

    final bca =
        container.read(instrumentsControllerProvider).instruments[0];
    expect(bca.monthlyAdminFee, 20000);
    expect(bca.adminFeeDay, 20);
  });

  test('addInstrument appends and selects', () async {
    final container = _container();
    await container
        .read(instrumentsControllerProvider.notifier)
        .addInstrument(
          const FinancialInstrument(
            id: 'inst-ovo',
            name: 'OVO',
            type: InstrumentType.ewallet,
            initialBalance: 250000,
            isSelected: true,
          ),
        );

    final state = container.read(instrumentsControllerProvider);
    expect(state.instruments.length, 4);
    expect(state.instruments.last.name, 'OVO');
  });

  test('save persists instruments without touching No.3 data', () async {
    final container = _container();
    final notifier = container.read(instrumentsControllerProvider.notifier);

    // Instrumen baru harus ditambahkan via addInstrument (disimpan ke backend).
    // save() hanya memvalidasi dan navigasi, tidak menyimpan ulang.
    await notifier.addInstrument(
      const FinancialInstrument(
        id: 'inst-cash-new',
        name: 'Cash',
        type: InstrumentType.ewallet,
        initialBalance: 500000,
        isSelected: true,
      ),
    );
    notifier.updateAdminFee('inst-bca', 14000);
    expect(await notifier.save(), isTrue);

    final saved = container.read(onboardingRepositoryProvider)
        .getOnboardingData();
    expect(saved?.financialInstruments.length, 4);
    expect(
      saved?.financialInstruments
          .where((e) => e.isSelected)
          .map((e) => e.id),
      containsAll(['inst-bca', 'inst-cash-new']),
    );
    // Data No.3 tetap tersimpan.
    expect(saved?.monthlyIncome, 5000000);
    expect(saved?.salaryDay, 25);
  });

  test('save refuses when nothing is selected', () async {
    final container = _container();
    final notifier = container.read(instrumentsControllerProvider.notifier);

    notifier.toggleSelect('inst-bca');
    expect(await notifier.save(), isFalse);
  });
}

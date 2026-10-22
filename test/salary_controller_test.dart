import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/providers/onboarding_providers.dart';
import 'package:tahan_dulu/features/onboarding/presentation/providers/salary_controller.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initial state uses canonical defaults and can continue', () {
    final state = _container().read(salaryControllerProvider);

    expect(state.monthlyIncome, 5000000);
    expect(state.salaryDay, 25);
    expect(state.canContinue, isTrue);
  });

  test('zero income blocks continue', () {
    final container = _container();
    container.read(salaryControllerProvider.notifier).setIncome(0);

    final state = container.read(salaryControllerProvider);
    expect(state.isIncomeValid, isFalse);
    expect(state.canContinue, isFalse);
  });

  test('setSalaryDay updates day', () {
    final container = _container();
    container.read(salaryControllerProvider.notifier).setSalaryDay(28);

    expect(container.read(salaryControllerProvider).salaryDay, 28);
  });

  test('save persists data to repository for next steps', () async {
    final container = _container();
    final notifier = container.read(salaryControllerProvider.notifier);

    notifier.setIncome(7500000);
    notifier.setSalaryDay(1);
    expect(await notifier.save(), isTrue);

    final saved = container.read(onboardingRepositoryProvider).getSalarySetup();
    expect(saved?.monthlyIncome, 7500000);
    expect(saved?.salaryDay, 1);
  });

  test('save refuses when income invalid', () async {
    final container = _container();
    final notifier = container.read(salaryControllerProvider.notifier);

    notifier.setIncome(0);
    expect(await notifier.save(), isFalse);
  });
}

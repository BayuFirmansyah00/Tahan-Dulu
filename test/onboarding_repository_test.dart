import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/mock/mock_data.dart';
import 'package:tahan_dulu/data/repositories/onboarding_repository.dart';

void main() {
  test('repository is seeded with canonical demo data', () {
    final repo = InMemoryOnboardingRepository();
    final data = repo.getSalarySetup();

    expect(data, isNotNull);
    expect(data!.monthlyIncome, MockData.income);
    expect(data.monthlyIncome, 5000000);
    expect(data.salaryDay, MockData.salaryDay);
    expect(data.salaryDay, 25);
  });

  test('save then read returns data for next onboarding steps', () async {
    final repo = InMemoryOnboardingRepository();

    final saved = await repo.saveSalarySetup(
      monthlyIncome: 7500000,
      salaryDay: 1,
    );

    expect(saved.monthlyIncome, 7500000);
    expect(saved.salaryDay, 1);
    expect(repo.getSalarySetup(), saved);
  });
}

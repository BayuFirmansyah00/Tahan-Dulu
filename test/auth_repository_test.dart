import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/data/datasources/mock/mock_data.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';

void main() {
  final repo = MockAuthRepository();

  test('loginWithEmail returns canonical mock user', () async {
    final user = await repo.loginWithEmail(
      email: 'bayu@email.com',
      password: 'rahasia',
    );
    expect(user, MockData.user);
  });

  test('register returns user with given name and email', () async {
    final user = await repo.register(
      name: 'Bayu Firmansyah',
      email: 'bayu@email.com',
      password: 'rahasia',
    );
    expect(user.name, 'Bayu Firmansyah');
    expect(user.email, 'bayu@email.com');
  });

  test('signInWithGoogle returns canonical mock user', () async {
    final user = await repo.signInWithGoogle();
    expect(user, MockData.user);
  });
}

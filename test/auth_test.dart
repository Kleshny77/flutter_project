import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/core/validation.dart';

void main() {
  group('Validation (доменная логика авторизации)', () {
    test('email: пустое значение возвращает ошибку', () {
      expect(Validation.email(null), 'Введите e-mail');
      expect(Validation.email(''), 'Введите e-mail');
      expect(Validation.email('   '), 'Введите e-mail');
    });

    test('email: неверный формат возвращает ошибку', () {
      expect(Validation.email('a'), 'Проверьте формат: name@domain.com');
      expect(Validation.email('a@'), 'Проверьте формат: name@domain.com');
      expect(Validation.email('@b.com'), 'Проверьте формат: name@domain.com');
    });

    test('email: корректный формат возвращает null', () {
      expect(Validation.email('a@b.co'), isNull);
      expect(Validation.email('user@example.com'), isNull);
    });

    test('password: пустое значение возвращает ошибку', () {
      expect(Validation.password(null), 'Введите пароль');
      expect(Validation.password(''), 'Введите пароль');
    });

    test('password: непустое значение возвращает null', () {
      expect(Validation.password('1'), isNull);
    });

    test('passwordRegister: слабый пароль возвращает ошибку', () {
      expect(Validation.passwordRegister('short'), isNotNull);
      expect(Validation.passwordRegister('nocapitals1!'), isNotNull);
      expect(Validation.passwordRegister('NOLOWERCASE1!'), isNotNull);
      expect(Validation.passwordRegister('NoDigits!!'), isNotNull);
      expect(Validation.passwordRegister('NoSpecial123'), isNotNull);
    });

    test('passwordRegister: надёжный пароль возвращает null', () {
      expect(Validation.passwordRegister('Abcd123!'), isNull);
      expect(Validation.passwordRegister('MyP@ss12'), isNull);
    });

    test('repeatPassword: несовпадение возвращает ошибку', () {
      expect(Validation.repeatPassword('other', 'pass'), 'Пароли не совпадают');
    });

    test('repeatPassword: совпадение возвращает null', () {
      expect(Validation.repeatPassword('pass', 'pass'), isNull);
    });
  });
}

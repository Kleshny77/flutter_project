class Validation {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите e-mail';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Проверьте формат: name@domain.com';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }

  static String? passwordRegister(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (!isPasswordStrong(value)) {
      return 'Ненадежный пароль. Пароль должен быть не менее 8 символов, включать буквы в верхнем и нижнем регистре, содержать цифры и другие знаки';
    }
    return null;
  }

  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'),
    );
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  static String? repeatPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  static String? repeatPasswordLabel(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Не ввели повторный пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  static String? code(String? value) {
    if (value == null || value.length != 6) {
      return null;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Неверный код';
    }
    return null;
  }
}

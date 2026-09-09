import '../constants/app_constants.dart';

/// Reusable input validation helpers.
///
/// Each method returns `null` when the value is valid, which matches the
/// contract expected by `TextFormField.validator`.
abstract final class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final String? emptyError = required(value, field: 'Email');
    if (emptyError != null) {
      return emptyError;
    }
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final String? emptyError = required(value, field: 'Password');
    if (emptyError != null) {
      return emptyError;
    }
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? mathExpression(String? value) {
    final String? emptyError = required(value, field: 'Expression');
    if (emptyError != null) {
      return emptyError;
    }
    if (value!.trim().length > AppConstants.maxExpressionLength) {
      return 'Expression is too long '
          '(max ${AppConstants.maxExpressionLength} characters).';
    }
    return null;
  }
}

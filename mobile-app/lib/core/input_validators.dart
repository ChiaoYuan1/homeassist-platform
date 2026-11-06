class InputValidators {
  InputValidators._();

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String normalizeMalaysiaMobile(String value) {
    var cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    if (cleaned.startsWith('+60')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('60')) {
      cleaned = '0${cleaned.substring(2)}';
    }

    return cleaned;
  }

  static String malaysiaMobileE164(String value) {
    final local = normalizeMalaysiaMobile(value);
    if (local.startsWith('0')) {
      return '+60${local.substring(1)}';
    }
    return value.trim();
  }

  static String? requiredText(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, label: 'Email');
    if (required != null) {
      return required;
    }

    final email = value!.trim();
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? malaysiaMobile(String? value) {
    final required = requiredText(value, label: 'Mobile number');
    if (required != null) {
      return required;
    }

    final normalized = normalizeMalaysiaMobile(value!);

    if (!RegExp(r'^01\d{8,9}$').hasMatch(normalized)) {
      return 'Use a Malaysian mobile number, e.g. 0123456789 or +60123456789.';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredText(value, label: 'Password');
    if (required != null) {
      return required;
    }

    final password = value!;

    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Include at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Include at least one lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number.';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final required = requiredText(value, label: 'Confirm password');
    if (required != null) {
      return required;
    }

    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? ssmRegistrationNumber(
      String? value, {
        required String businessType,
      }) {
    final required = requiredText(value, label: 'SSM registration number');
    if (required != null) {
      return required;
    }

    final number = digitsOnly(value!);
    if (number.length != 12) {
      return 'Use the 12-digit SSM registration number.';
    }

    final year = int.tryParse(number.substring(0, 4));
    final currentYear = DateTime.now().year;
    if (year == null || year < 1900 || year > currentYear) {
      return 'The first 4 digits must be a valid registration year.';
    }

    final entityCode = number.substring(4, 6);
    final expectedCode = switch (businessType) {
      'sole_proprietorship' => '03',
      'partnership' => '03',
      'company' => '01',
      'llp' => '04',
      _ => null,
    };

    if (expectedCode != null && entityCode != expectedCode) {
      return 'The SSM entity code does not match the selected business type.';
    }

    return null;
  }

  static String? credentialNumber(String? value, {required String label}) {
    final required = requiredText(value, label: label);
    if (required != null) {
      return required;
    }

    final cleaned = value!.trim();
    if (cleaned.length < 4 || cleaned.length > 40) {
      return '$label must be between 4 and 40 characters.';
    }

    if (!RegExp(r'^[A-Za-z0-9\-/.() ]+$').hasMatch(cleaned)) {
      return '$label contains unsupported characters.';
    }

    return null;
  }
}

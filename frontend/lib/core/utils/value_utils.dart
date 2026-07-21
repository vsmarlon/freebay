class ValueUtils {
  ValueUtils._();

  /// Formats raw digits to CPF format: "000.000.000-00"
  static String formatCPF(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return raw;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  /// Formats raw digits to CNPJ format: "00.000.000/0000-00"
  static String formatCNPJ(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return raw;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  /// Formats raw digits to Brazilian phone format: "(11) 99999-9999" or "(11) 9999-9999"
  static String formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
  }

  /// Formats CEP zip code format: "00000-000"
  static String formatCEP(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return raw;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  /// Validates CPF checksum
  static bool validateCPF(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 11) return false;

    // Block common invalid patterns
    if (RegExp(r'^(\d)\1{10}$').hasMatch(clean)) return false;

    // Validate first digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(clean[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != int.parse(clean[9])) return false;

    // Validate second digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(clean[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    if (secondDigit != int.parse(clean[10])) return false;

    return true;
  }

  /// Validates CNPJ checksum
  static bool validateCNPJ(String cnpj) {
    final clean = cnpj.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 14) return false;

    // Block common invalid patterns
    if (RegExp(r'^(\d)\1{13}$').hasMatch(clean)) return false;

    // Validate first digit
    List<int> weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(clean[i]) * weight1[i];
    }
    int firstDigit = sum % 11;
    firstDigit = firstDigit < 2 ? 0 : 11 - firstDigit;
    if (firstDigit != int.parse(clean[12])) return false;

    // Validate second digit
    List<int> weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(clean[i]) * weight2[i];
    }
    int secondDigit = sum % 11;
    secondDigit = secondDigit < 2 ? 0 : 11 - secondDigit;
    if (secondDigit != int.parse(clean[13])) return false;

    return true;
  }

  /// Validates email address format (allows subdomains and plus-addressing)
  static bool validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validates username format: 3-20 chars, lowercase letters/numbers/underscore
  static bool validateUsername(String username) {
    return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username);
  }

  /// Truncates string to a maximum length with an optional suffix
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Capitalizes first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  /// Safely parses string to double
  static double parseDouble(String value, {double defaultValue = 0.0}) {
    if (value.isEmpty) return defaultValue;
    final normalized = value
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(normalized) ?? defaultValue;
  }

  /// Safely parses string to int
  static int parseInt(String value, {int defaultValue = 0}) {
    if (value.isEmpty) return defaultValue;
    final clean = value.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(clean) ?? defaultValue;
  }
}

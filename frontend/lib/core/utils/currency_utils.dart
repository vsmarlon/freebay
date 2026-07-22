class CurrencyUtils {
  CurrencyUtils._();

  /// Formats an integer cent value to Brazilian Real string (e.g. 1999 → "R$ 19,99").
  static String formatCents(int cents) {
    return 'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formats a double reais value to Brazilian Real string (e.g. 19.99 → "R$ 19,99").
  static String formatReais(double reais) {
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Converts a reais value to integer cents (e.g. 19.99 → 1999).
  static int reaisToCents(double reais) => (reais * 100).round();

  /// Parses a pt-BR amount string ("1.234,56") to integer cents, null when invalid.
  static int? parseReaisToCents(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final reais = double.tryParse(normalized);
    return reais == null ? null : reaisToCents(reais);
  }
}

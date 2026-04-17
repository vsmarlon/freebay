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
}

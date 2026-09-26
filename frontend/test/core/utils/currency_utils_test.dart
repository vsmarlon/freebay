import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/utils/currency_utils.dart';

void main() {
  test('parses create and edit pt-BR price input as integer cents', () {
    expect(CurrencyUtils.parseReaisToCents('12,34'), 1234);
    expect(CurrencyUtils.parseReaisToCents('1.234,56'), 123456);
    expect(CurrencyUtils.parseReaisToCents('12'), 1200);
    expect(CurrencyUtils.parseReaisToCents('12.34'), 123400);
  });

  test('rejects empty and negative prices', () {
    expect(CurrencyUtils.parseReaisToCents(''), isNull);
    expect(CurrencyUtils.parseReaisToCents('-12,34'), isNull);
  });
}

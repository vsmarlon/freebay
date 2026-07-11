import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/utils/value_utils.dart';

void main() {
  group('ValueUtils.validateEmail', () {
    test('accepts a plain email', () {
      expect(ValueUtils.validateEmail('user@example.com'), isTrue);
    });

    test('accepts subdomains', () {
      expect(ValueUtils.validateEmail('user@sub.example.com'), isTrue);
      expect(ValueUtils.validateEmail('user@mail.sub.example.com'), isTrue);
    });

    test('accepts plus-addressing', () {
      expect(ValueUtils.validateEmail('user+tag@gmail.com'), isTrue);
    });

    test('trims surrounding whitespace', () {
      expect(ValueUtils.validateEmail('  user@example.com  '), isTrue);
    });

    test('rejects missing @', () {
      expect(ValueUtils.validateEmail('userexample.com'), isFalse);
    });

    test('rejects missing domain', () {
      expect(ValueUtils.validateEmail('user@'), isFalse);
    });

    test('rejects missing TLD', () {
      expect(ValueUtils.validateEmail('user@example'), isFalse);
    });

    test('rejects empty string', () {
      expect(ValueUtils.validateEmail(''), isFalse);
    });
  });

  group('ValueUtils.validateCPF', () {
    test('accepts a valid CPF', () {
      expect(ValueUtils.validateCPF('11144477735'), isTrue);
    });

    test('rejects repeated digits', () {
      expect(ValueUtils.validateCPF('11111111111'), isFalse);
    });

    test('rejects wrong length', () {
      expect(ValueUtils.validateCPF('123'), isFalse);
    });

    test('rejects an invalid checksum', () {
      expect(ValueUtils.validateCPF('11144477736'), isFalse);
    });
  });

  group('ValueUtils.validateCNPJ', () {
    test('rejects repeated digits', () {
      expect(ValueUtils.validateCNPJ('11111111111111'), isFalse);
    });

    test('rejects wrong length', () {
      expect(ValueUtils.validateCNPJ('123'), isFalse);
    });
  });
}

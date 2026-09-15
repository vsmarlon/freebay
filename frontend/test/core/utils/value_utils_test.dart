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

  group('ValueUtils.validateUsername', () {
    test('accepts valid usernames', () {
      expect(ValueUtils.validateUsername('john_doe'), isTrue);
      expect(ValueUtils.validateUsername('alice123'), isTrue);
      expect(ValueUtils.validateUsername('dev_99_pro'), isTrue);
      expect(ValueUtils.validateUsername('abc'), isTrue);
    });

    test('rejects too short or too long', () {
      expect(ValueUtils.validateUsername('ab'), isFalse);
      expect(ValueUtils.validateUsername('a' * 21), isFalse);
    });

    test('rejects uppercase letters', () {
      expect(ValueUtils.validateUsername('JohnDoe'), isFalse);
    });

    test('rejects spaces', () {
      expect(ValueUtils.validateUsername('john doe'), isFalse);
    });

    test('rejects special characters including user requested hacky set', () {
      final hackyCharacters = [
        '#',
        '\$',
        '!',
        '%',
        '^',
        '@',
        '*',
        '(',
        ')',
        ',',
        '.',
        '/',
        '\\',
        '&',
      ];
      for (final char in hackyCharacters) {
        expect(
          ValueUtils.validateUsername('user${char}name'),
          isFalse,
          reason: 'Rejects username with character: $char',
        );
      }
    });

    test('rejects unicode and accented letters in usernames', () {
      expect(ValueUtils.validateUsername('joão_silva'), isFalse);
      expect(ValueUtils.validateUsername('usuário'), isFalse);
      expect(ValueUtils.validateUsername('user😀'), isFalse);
    });
  });

  group('ValueUtils.validateDisplayName', () {
    test('accepts valid display names with letters, numbers, and accents', () {
      expect(ValueUtils.validateDisplayName('John Doe'), isTrue);
      expect(ValueUtils.validateDisplayName('João da Silva'), isTrue);
      expect(ValueUtils.validateDisplayName('Maria-Eduarda'), isTrue);
      expect(ValueUtils.validateDisplayName("D'Angelo"), isTrue);
      expect(ValueUtils.validateDisplayName('Dr. Smith'), isTrue);
      expect(ValueUtils.validateDisplayName('Loja 10'), isTrue);
    });

    test('rejects names that are too short or too long', () {
      expect(ValueUtils.validateDisplayName('A'), isFalse);
      expect(ValueUtils.validateDisplayName('A' * 51), isFalse);
    });

    test('rejects hacky names containing prohibited symbols', () {
      final hackyPatterns = [
        '#\$!%^@*()*#\$,./\\',
        'John#Doe',
        'User\$1',
        'Hey!There',
        '50%Off',
        'test^user',
        '@hacker',
        'user*name',
        '(admin)',
        'Tom, Jerry',
        'user/admin',
        'path\\to\\file',
        'Tom & Jerry',
        '<script>alert(1)</script>',
        'Robert"); DROP TABLE;',
        'user_name_with_underscores',
      ];
      for (final name in hackyPatterns) {
        expect(
          ValueUtils.validateDisplayName(name),
          isFalse,
          reason: 'Rejects hacky display name: $name',
        );
      }
    });

    test('rejects consecutive spaces and empty strings', () {
      expect(ValueUtils.validateDisplayName(''), isFalse);
      expect(ValueUtils.validateDisplayName('   '), isFalse);
      expect(ValueUtils.validateDisplayName('John  Doe'), isFalse);
    });
  });
}

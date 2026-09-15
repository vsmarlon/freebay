import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/shared/utils/date_utils.dart';

void main() {
  test('formats an older chat date without locale initialization', () {
    expect(
      formatDateSeparator(DateTime(2026, 7, 23), now: DateTime(2026, 9, 14)),
      '23 DE JUL 2026',
    );
  });

  test(
    'parses a server instant in local time without changing the instant',
    () {
      final parsed = parseServerDateTime('2026-09-14T05:00:00.000Z');

      expect(parsed.toUtc(), DateTime.utc(2026, 9, 14, 5));
      expect(parsed.isUtc, isFalse);
    },
  );

  test('throws for malformed server dates', () {
    expect(() => parseServerDateTime('not-a-date'), throwsFormatException);
  });
}

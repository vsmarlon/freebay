import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/auth/data/services/apple_auth_nonce.dart';

void main() {
  test('hashes the original nonce with SHA-256 before the Apple request', () {
    expect(
      hashAppleRawNonce('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('generates distinct 32-character raw nonces', () {
    final first = generateAppleRawNonce();
    final second = generateAppleRawNonce();
    expect(first, hasLength(32));
    expect(second, hasLength(32));
    expect(second, isNot(first));
  });
}

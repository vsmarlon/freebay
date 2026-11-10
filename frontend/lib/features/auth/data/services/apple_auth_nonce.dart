import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _nonceCharacters =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

String generateAppleRawNonce() {
  final random = Random.secure();
  return List.generate(
    32,
    (_) => _nonceCharacters[random.nextInt(_nonceCharacters.length)],
  ).join();
}

String hashAppleRawNonce(String rawNonce) =>
    sha256.convert(utf8.encode(rawNonce)).toString();

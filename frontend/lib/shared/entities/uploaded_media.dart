class UploadedMedia {
  static const _blurHashAlphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~';

  final String url;
  final String? blurHash;

  const UploadedMedia({required this.url, this.blurHash});

  factory UploadedMedia.fromJson(Map<String, Object?> json) {
    final url = json['url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('Uploaded media URL is missing');
    }
    final hash = json['blurHash'];
    return UploadedMedia(
      url: url,
      blurHash: hash is String && isValidBlurHash(hash) ? hash : null,
    );
  }

  Map<String, Object?> toJson() => {
    'url': url,
    if (blurHash != null) 'blurHash': blurHash,
  };

  static bool isValidBlurHash(String value) {
    if (value.length < 6 || value.length > 166) return false;
    for (final character in value.split('')) {
      if (!_blurHashAlphabet.contains(character)) return false;
    }
    final sizeFlag = _blurHashAlphabet.indexOf(value[0]);
    final componentsX = sizeFlag % 9 + 1;
    final componentsY = sizeFlag ~/ 9 + 1;
    return value.length == 4 + 2 * componentsX * componentsY;
  }
}

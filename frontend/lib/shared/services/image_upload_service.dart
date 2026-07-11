import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class _CompressParams {
  final Uint8List bytes;
  final int quality;
  final int maxDimension;

  const _CompressParams(this.bytes, this.quality, this.maxDimension);
}

Uint8List? _decodeResizeEncode(_CompressParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) return null;

  final largestSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = largestSide > params.maxDimension
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? params.maxDimension : null,
          height: decoded.height > decoded.width ? params.maxDimension : null,
        )
      : decoded;

  return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
}

class ImageUploadService {
  ImageUploadService._();

  static const int maxUploadBytes = 800000;

  static Future<MultipartFile> compressedMultipartFile(
    String path, {
    required String filename,
  }) async {
    final originalBytes = await File(path).readAsBytes();

    int quality = 90;
    int maxDimension = 1600;

    Uint8List? compressed = await compute<_CompressParams, Uint8List?>(
      _decodeResizeEncode,
      _CompressParams(originalBytes, quality, maxDimension),
    );

    if (compressed == null) {
      throw Exception('Não foi possível preparar a imagem para upload.');
    }

    while (compressed != null &&
        compressed.length > maxUploadBytes &&
        quality > 50) {
      quality -= 8;
      if (quality <= 74) {
        maxDimension = 1280;
      }
      if (quality <= 66) {
        maxDimension = 1080;
      }

      compressed = await compute<_CompressParams, Uint8List?>(
        _decodeResizeEncode,
        _CompressParams(originalBytes, quality, maxDimension),
      );

      if (compressed == null) {
        throw Exception('Não foi possível preparar a imagem para upload.');
      }
    }

    return MultipartFile.fromBytes(
      compressed!,
      filename: filename,
      contentType: DioMediaType.parse('image/jpeg'),
    );
  }
}

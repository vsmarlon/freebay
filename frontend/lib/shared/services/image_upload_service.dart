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

  static const int compressedTargetBytes = 800000;
  static const int serverUploadMaxBytes = 5 * 1024 * 1024;
  static const int initialQuality = 90;
  static const int minimumQuality = 50;
  static const int qualityStep = 8;
  static const int reducedDimensionQuality = 74;
  static const int minimumDimensionQuality = 66;
  static const int initialMaxDimension = 1600;
  static const int reducedMaxDimension = 1280;
  static const int minimumMaxDimension = 1080;

  static Future<MultipartFile> compressedMultipartFile(
    String path, {
    required String filename,
  }) async {
    final originalBytes = await File(path).readAsBytes();

    int quality = initialQuality;
    int maxDimension = initialMaxDimension;

    Uint8List? compressed = await compute<_CompressParams, Uint8List?>(
      _decodeResizeEncode,
      _CompressParams(originalBytes, quality, maxDimension),
    );

    if (compressed == null) {
      throw Exception('Não foi possível preparar a imagem para upload.');
    }

    while (compressed != null &&
        compressed.length > compressedTargetBytes &&
        quality > minimumQuality) {
      quality -= qualityStep;
      if (quality <= reducedDimensionQuality) {
        maxDimension = reducedMaxDimension;
      }
      if (quality <= minimumDimensionQuality) {
        maxDimension = minimumMaxDimension;
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

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUploadService {
  ImageUploadService._();

  static const int maxUploadBytes = 1000000;

  static Future<MultipartFile> compressedMultipartFile(
    String path, {
    required String filename,
  }) async {
    int quality = 90;
    int minWidth = 1600;
    int minHeight = 1600;

    Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressed == null) {
      throw Exception('Não foi possível preparar a imagem para upload.');
    }

    while (compressed != null && compressed.length > maxUploadBytes && quality > 50) {
      quality -= 8;
      if (quality <= 74) {
        minWidth = 1280;
        minHeight = 1280;
      }
      if (quality <= 66) {
        minWidth = 1080;
        minHeight = 1080;
      }

      compressed = await FlutterImageCompress.compressWithFile(
        path,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
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

import 'dart:io';

import 'package:flutter/services.dart';

class MediaGalleryService {
  static const MethodChannel _channel = MethodChannel(
    'com.freebay.app/media_gallery',
  );

  Future<String> saveImage(Uint8List bytes) async {
    final result = await _channel.invokeMethod<String>('saveImage', {
      'bytes': bytes,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(code: 'save_failed');
    }
    return result;
  }

  Future<String> saveVideo(String path) async {
    if (!await File(path).exists()) {
      throw PlatformException(code: 'invalid_arguments');
    }
    final result = await _channel.invokeMethod<String>('saveVideo', {
      'path': path,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(code: 'save_failed');
    }
    return result;
  }
}

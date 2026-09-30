import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _CatalogAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'products': [
          {'id': 'product-1', 'title': 'Câmera', 'sellerId': 'seller-1'},
        ],
        'nextCursor': null,
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('catalog cache retains only a bounded number of first pages', () async {
    final directory = await Directory.systemTemp.createTemp('freebay-catalog-');
    Hive.init(directory.path);
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = _CatalogAdapter();
    final repository = ProductRepository(client: dio);

    for (var index = 0; index < 15; index++) {
      final result = await repository.getProducts(search: 'query-$index');
      expect(result.isRight, isTrue);
    }

    final box = await Hive.openBox('product_catalog_cache');
    await box.flush();
    expect(box.length, lessThanOrEqualTo(8));
  });
}

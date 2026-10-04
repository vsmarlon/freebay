import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _OfflineCatalogAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'message': 'offline'}),
    503,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'HTTP repository never substitutes its removed Hive catalog cache',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'freebay-catalog-',
      );
      Hive.init(directory.path);
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      final legacyBox = await Hive.openBox('product_catalog_cache');
      await legacyBox.put(
        'products|s:query|cat:null|min:null|max:null|cond:null|sort:null|cur:null',
        [
          {'id': 'old-product', 'title': 'Old item', 'sellerId': 'seller-1'},
        ],
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = _OfflineCatalogAdapter();
      final repository = ProductRepository(client: dio);

      final result = await repository.getProducts(search: 'query');

      expect(result.isLeft, isTrue);
    },
  );
}

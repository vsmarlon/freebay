import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';

class _CancelAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    expect(options.method, 'PATCH');
    expect(options.path, '/orders/order-1/cancel');
    expect(options.data, {'reason': 'Mudei de ideia'});
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'cancelamento não tenta decodificar pedido quando API responde sem corpo',
    () async {
      final client = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = _CancelAdapter();
      final result = await OrderRepositoryImpl(
        client: client,
      ).cancelOrder('order-1', reason: 'Mudei de ideia');
      expect(result.isRight, isTrue);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _ConfirmDeliveryAdapter implements HttpClientAdapter {
  _ConfirmDeliveryAdapter({this.confirmStatus = 200, this.orderStatus = 200});

  final int confirmStatus;
  final int orderStatus;
  final requests = <({String method, String path})>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add((method: options.method, path: options.path));
    if (options.path == '/orders/order-1/confirm-delivery' &&
        options.method == 'PATCH') {
      return _jsonResponse({
        'success': true,
        'data': {'sellerAmount': 900},
      }, confirmStatus);
    }
    if (options.path == '/orders/order-1' && options.method == 'GET') {
      return _jsonResponse({
        'success': true,
        'data': {
          'order': {
            'id': 'order-1',
            'buyerId': 'buyer-1',
            'sellerId': 'seller-1',
            'productId': 'product-1',
            'amount': 1000,
            'platformFee': 100,
            'sellerAmount': 900,
            'status': 'COMPLETED',
            'escrowStatus': 'RELEASED',
            'createdAt': '2026-10-05T00:00:00.000Z',
          },
        },
      }, orderStatus);
    }
    return _jsonResponse({'success': false}, 404);
  }

  ResponseBody _jsonResponse(Map<String, Object?> body, int status) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

Dio _client(_ConfirmDeliveryAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;

void main() {
  test(
    'PATCH acknowledgement is followed by the canonical order GET',
    () async {
      final adapter = _ConfirmDeliveryAdapter();
      final result = await OrderRepositoryImpl(
        client: _client(adapter),
      ).confirmDelivery('order-1');

      expect(result.isRight, isTrue);
      final order = result.rightOrNull!;
      expect(order.status, OrderStatus.completed);
      expect(order.escrowStatus, EscrowStatus.released);
      expect(order.amount, 1000);
      expect(order.sellerAmount, 900);
      expect(adapter.requests, [
        (method: 'PATCH', path: '/orders/order-1/confirm-delivery'),
        (method: 'GET', path: '/orders/order-1'),
      ]);
    },
  );

  for (final status in [401, 404, 409]) {
    test('confirmation HTTP $status fails without fetching an order', () async {
      final adapter = _ConfirmDeliveryAdapter(confirmStatus: status);
      final result = await OrderRepositoryImpl(
        client: _client(adapter),
      ).confirmDelivery('order-1');

      expect(result.isLeft, isTrue);
      expect(result.leftOrNull, switch (status) {
        401 => isA<UnauthorizedFailure>(),
        404 => isA<NotFoundFailure>(),
        _ => isA<ServerFailure>(),
      });
      expect(adapter.requests, [
        (method: 'PATCH', path: '/orders/order-1/confirm-delivery'),
      ]);
    });
  }

  test(
    'order GET failure after acknowledgement is not treated as success',
    () async {
      final adapter = _ConfirmDeliveryAdapter(orderStatus: 500);
      final result = await OrderRepositoryImpl(
        client: _client(adapter),
      ).confirmDelivery('order-1');

      expect(result.isLeft, isTrue);
      expect(result.leftOrNull, isA<ServerFailure>());
      expect(adapter.requests, [
        (method: 'PATCH', path: '/orders/order-1/confirm-delivery'),
        (method: 'GET', path: '/orders/order-1'),
      ]);
    },
  );
}

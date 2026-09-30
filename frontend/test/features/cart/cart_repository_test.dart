import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/cart/data/repositories/cart_repository.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  int status = 200;
  Object? responseData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? {'success': true, 'data': responseData ?? {}}
            : {
                'success': false,
                'error': {'message': 'failed'},
              },
      ),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends the cart quantity to the endpoint', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;

    final result = await CartRepositoryImpl(
      client: dio,
    ).addToCart('product-1', quantity: 3);

    expect(result.isRight, isTrue);
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/cart/product-1');
    expect(adapter.request?.data, {'quantity': 3});
  });

  test('decodes the payment details returned by cart checkout', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _Adapter()
      ..responseData = {
        'paymentGroupId': 'group-1',
        'items': [
          {
            'orderId': 'order-1',
            'productId': 'product-1',
            'productTitle': 'Câmera',
            'quantity': 2,
            'amount': 4000,
          },
        ],
        'totalOrders': 1,
        'totalAmount': 4000,
        'checkoutUrl': 'https://checkout.stripe.com/pay/cs_test_123',
        'paymentIntentClientSecret': null,
        'expiresAt': '2026-09-28T13:00:00.000Z',
      };
    dio.httpClientAdapter = adapter;

    final result = await CartRepositoryImpl(client: dio).checkoutCart();

    expect(result.isRight, isTrue);
    expect(result.rightOrNull?.items.single.orderId, 'order-1');
    expect(adapter.request?.data, {'mode': 'intent'});
  });
}

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_item_entity.dart';
import 'package:freebay/features/cart/data/repositories/cart_repository.dart';
import 'package:freebay/features/cart/presentation/pages/cart_checkout_page.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/presentation/pages/cart_page.dart';

class _CheckoutReadyCart extends CartNotifier {
  @override
  CartState build() => const CartState(
    lastCheckout: CartCheckoutEntity(
      paymentGroupId: 'group-1',
      totalOrders: 1,
      totalAmount: 4000,
      paymentIntentClientSecret: 'pi_test_secret',
    ),
  );

  @override
  Future<void> loadCart() async {}
}

class _OutOfStockCart extends CartNotifier {
  @override
  CartState build() => const CartState(
    cart: CartEntity(
      items: [
        CartItemEntity(
          id: 'item-1',
          productId: 'product-1',
          subtotal: 4000,
          product: ProductEntity(
            id: 'product-1',
            title: 'Câmera',
            price: 4000,
            sellerId: 'seller-1',
            soldCount: 1,
          ),
        ),
      ],
      totalItems: 1,
      totalPrice: 4000,
    ),
  );

  @override
  Future<void> loadCart() async {}
}

class _AddAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"success":true,"data":{}}',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('a created cart payment can be completed with PaymentSheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartProvider.overrideWith(_CheckoutReadyCart.new)],
        child: const MaterialApp(home: CartCheckoutPage()),
      ),
    );
    await tester.pump();

    expect(find.text('PAGAR COM CARTÃO'), findsOneWidget);
    expect(find.text('CHECKOUT GERADO'), findsOneWidget);
  });

  testWidgets('cart blocks checkout when an item no longer has stock', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartProvider.overrideWith(_OutOfStockCart.new)],
        child: const MaterialApp(home: CartPage()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('estoque insuficiente'), findsOneWidget);
    final continueButton = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'CONTINUAR'),
    );
    expect(continueButton.onPressed, isNull);
  });

  test('adding a new product clears the previous checkout result', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = _AddAdapter();
    final container = ProviderContainer(
      overrides: [
        cartProvider.overrideWith(_CheckoutReadyCart.new),
        cartRepositoryProvider.overrideWithValue(
          CartRepositoryImpl(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(cartProvider.notifier).addToCart('product-2'),
      isTrue,
    );
    expect(container.read(cartProvider).lastCheckout, isNull);
  });
}

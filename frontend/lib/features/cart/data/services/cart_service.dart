import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';

class CartService extends BaseHttpRepository {
  CartService({super.client});

  Future<Either<Failure, CartEntity>> getCart() => safeGet<CartEntity>(
    '/cart',
    extractKey: 'data',
    fromJson: CartEntity.fromJson,
  );

  Future<Either<Failure, void>> addToCart(
    String productId, {
    int quantity = 1,
  }) => safeVoid(
    () => client.post('/cart/$productId', data: {'quantity': quantity}),
  );

  Future<Either<Failure, void>> updateQuantity(
    String productId,
    int quantity,
  ) => safeVoid(
    () => client.patch('/cart/$productId', data: {'quantity': quantity}),
  );

  Future<Either<Failure, void>> removeFromCart(String productId) =>
      safeVoid(() => client.patch('/cart/$productId/remove'));

  Future<Either<Failure, void>> clearCart() =>
      safeVoid(() => client.patch('/cart/clear'));

  Future<Either<Failure, CartCheckoutEntity>> checkoutCart() =>
      safePost<CartCheckoutEntity>(
        '/cart/checkout',
        extractKey: 'data',
        fromJson: CartCheckoutEntity.fromJson,
      );
}

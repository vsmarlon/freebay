import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract interface class CartRepository {
  Future<Either<Failure, CartEntity>> getCart();
  Future<Either<Failure, void>> addToCart(String productId, {int quantity = 1});
  Future<Either<Failure, void>> updateQuantity(String productId, int quantity);
  Future<Either<Failure, void>> removeFromCart(String productId);
  Future<Either<Failure, void>> clearCart();
  Future<Either<Failure, CartCheckoutEntity>> checkoutCart();
}

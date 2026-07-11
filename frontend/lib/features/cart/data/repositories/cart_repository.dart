import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/services/cart_service.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class CartRepository implements ICartRepository {
  final CartService _service;

  CartRepository(this._service);

  @override
  Future<Either<Failure, CartEntity>> getCart() {
    return _service.getCart();
  }

  @override
  Future<Either<Failure, void>> addToCart(
    String productId, {
    int quantity = 1,
  }) {
    return _service.addToCart(productId, quantity: quantity);
  }

  @override
  Future<Either<Failure, void>> updateQuantity(String productId, int quantity) {
    return _service.updateQuantity(productId, quantity);
  }

  @override
  Future<Either<Failure, void>> removeFromCart(String productId) {
    return _service.removeFromCart(productId);
  }

  @override
  Future<Either<Failure, void>> clearCart() {
    return _service.clearCart();
  }

  @override
  Future<Either<Failure, CartCheckoutEntity>> checkoutCart() {
    return _service.checkoutCart();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/repositories/cart_repository.dart';
import 'package:freebay/features/cart/data/services/cart_service.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:freebay/features/cart/domain/usecases/add_to_cart_usecase.dart';
import 'package:freebay/features/cart/domain/usecases/checkout_cart_usecase.dart';
import 'package:freebay/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:freebay/features/cart/domain/usecases/get_cart_usecase.dart';
import 'package:freebay/features/cart/domain/usecases/remove_from_cart_usecase.dart';
import 'package:freebay/features/cart/domain/usecases/update_cart_quantity_usecase.dart';

final cartServiceProvider = Provider((ref) => CartService());

final cartRepositoryProvider = Provider<ICartRepository>((ref) {
  return CartRepository(ref.watch(cartServiceProvider));
});

final getCartUsecaseProvider = Provider(
  (ref) => GetCartUsecase(ref.watch(cartRepositoryProvider)),
);
final addToCartUsecaseProvider = Provider(
  (ref) => AddToCartUsecase(ref.watch(cartRepositoryProvider)),
);
final updateCartQuantityUsecaseProvider = Provider(
  (ref) => UpdateCartQuantityUsecase(ref.watch(cartRepositoryProvider)),
);
final removeFromCartUsecaseProvider = Provider(
  (ref) => RemoveFromCartUsecase(ref.watch(cartRepositoryProvider)),
);
final clearCartUsecaseProvider = Provider(
  (ref) => ClearCartUsecase(ref.watch(cartRepositoryProvider)),
);
final checkoutCartUsecaseProvider = Provider(
  (ref) => CheckoutCartUsecase(ref.watch(cartRepositoryProvider)),
);

class CartState {
  final bool isLoading;
  final CartEntity cart;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.cart = const CartEntity(items: [], totalItems: 0, totalPrice: 0),
    this.error,
  });

  CartState copyWith({
    bool? isLoading,
    CartEntity? cart,
    String? error,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      cart: cart ?? this.cart,
      error: error,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final GetCartUsecase _getCartUsecase;
  final AddToCartUsecase _addToCartUsecase;
  final UpdateCartQuantityUsecase _updateCartQuantityUsecase;
  final RemoveFromCartUsecase _removeFromCartUsecase;
  final ClearCartUsecase _clearCartUsecase;

  CartNotifier(
    this._getCartUsecase,
    this._addToCartUsecase,
    this._updateCartQuantityUsecase,
    this._removeFromCartUsecase,
    this._clearCartUsecase,
  ) : super(const CartState());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCartUsecase();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (cart) => state = state.copyWith(
        isLoading: false,
        cart: cart,
      ),
    );
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    final result = await _addToCartUsecase(
      AddToCartParams(productId: productId, quantity: quantity),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return true;
      },
    );
  }

  Future<bool> updateQuantity(String productId, int quantity) async {
    final result = await _updateCartQuantityUsecase(
      UpdateCartQuantityParams(productId: productId, quantity: quantity),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return true;
      },
    );
  }

  Future<bool> removeFromCart(String productId) async {
    final result = await _removeFromCartUsecase(productId);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return true;
      },
    );
  }

  Future<bool> clearCart() async {
    final result = await _clearCartUsecase();
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return true;
      },
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(
    ref.watch(getCartUsecaseProvider),
    ref.watch(addToCartUsecaseProvider),
    ref.watch(updateCartQuantityUsecaseProvider),
    ref.watch(removeFromCartUsecaseProvider),
    ref.watch(clearCartUsecaseProvider),
  );
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cart.totalItems;
});

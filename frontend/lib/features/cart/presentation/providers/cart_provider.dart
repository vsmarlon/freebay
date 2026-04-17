import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/services/cart_service.dart';

final cartServiceProvider = Provider((ref) => CartService());

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
  final CartService _service;

  CartNotifier(this._service) : super(const CartState());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.getCart();
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
    final result = await _service.addToCart(productId, quantity: quantity);
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
    final result = await _service.updateQuantity(productId, quantity);
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
    final result = await _service.removeFromCart(productId);
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
    final result = await _service.clearCart();
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
  return CartNotifier(ref.watch(cartServiceProvider));
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cart.totalItems;
});

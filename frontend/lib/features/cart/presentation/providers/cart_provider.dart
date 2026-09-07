import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/services/cart_service.dart';
import 'package:freebay/features/cart/data/repositories/cart_repository.dart';

final cartServiceProvider = Provider((ref) => CartService());

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(cartServiceProvider));
});

class CartState {
  final bool isLoading;
  final CartEntity cart;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.cart = const CartEntity(),
    this.error,
  });

  CartState copyWith({bool? isLoading, CartEntity? cart, String? error}) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      cart: cart ?? this.cart,
      error: error,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(cartRepositoryProvider).getCart();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (cart) => state = state.copyWith(isLoading: false, cart: cart),
    );
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    final result = await ref
        .read(cartRepositoryProvider)
        .addToCart(productId, quantity: quantity);
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
    final result = await ref
        .read(cartRepositoryProvider)
        .updateQuantity(productId, quantity);
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
    final result = await ref
        .read(cartRepositoryProvider)
        .removeFromCart(productId);
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
    final result = await ref.read(cartRepositoryProvider).clearCart();
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

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cart.totalItems;
});

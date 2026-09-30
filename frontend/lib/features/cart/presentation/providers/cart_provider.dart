import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/data/repositories/cart_repository.dart';
import 'package:freebay/features/cart/domain/repositories/cart_repository.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(client: HttpClient.instance),
);

class CartState {
  final bool isLoading;
  final bool isCheckingOut;
  final CartEntity cart;
  final CartCheckoutEntity? lastCheckout;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.isCheckingOut = false,
    this.cart = const CartEntity(),
    this.lastCheckout,
    this.error,
  });

  CartState copyWith({
    bool? isLoading,
    bool? isCheckingOut,
    CartEntity? cart,
    CartCheckoutEntity? lastCheckout,
    String? error,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      cart: cart ?? this.cart,
      lastCheckout: lastCheckout ?? this.lastCheckout,
      error: error,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  Future<void> loadCart() async {
    state = CartState(
      isLoading: true,
      cart: state.cart,
      lastCheckout: state.lastCheckout,
    );
    final result = await ref.read(cartRepositoryProvider).getCart();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (cart) => state = CartState(cart: cart, lastCheckout: state.lastCheckout),
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
        state = CartState(cart: state.cart);
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

  Future<bool> checkout() async {
    state = state.copyWith(isCheckingOut: true);
    final result = await ref
        .read(cartRepositoryProvider)
        .checkoutCart(hosted: kIsWeb);
    final success = result.fold(
      (failure) {
        state = state.copyWith(isCheckingOut: false, error: failure.message);
        return false;
      },
      (checkout) {
        state = state.copyWith(isCheckingOut: false, lastCheckout: checkout);
        return true;
      },
    );
    if (success) {
      ref.invalidate(purchasesListProvider);
      ref.invalidate(salesListProvider);
      ref.invalidate(myProductsProvider);
      await loadCart();
    }
    return success;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cart.totalItems;
});

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
  final bool isRecoveringCheckout;
  final bool checkoutRecoveryRequired;
  final bool checkoutPaid;
  final CartEntity cart;
  final CartCheckoutEntity? lastCheckout;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.isCheckingOut = false,
    this.isRecoveringCheckout = false,
    this.checkoutRecoveryRequired = false,
    this.checkoutPaid = false,
    this.cart = const CartEntity(),
    this.lastCheckout,
    this.error,
  });

  CartState copyWith({
    bool? isLoading,
    bool? isCheckingOut,
    bool? isRecoveringCheckout,
    bool? checkoutRecoveryRequired,
    bool? checkoutPaid,
    CartEntity? cart,
    CartCheckoutEntity? lastCheckout,
    String? error,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      isRecoveringCheckout: isRecoveringCheckout ?? this.isRecoveringCheckout,
      checkoutRecoveryRequired:
          checkoutRecoveryRequired ?? this.checkoutRecoveryRequired,
      checkoutPaid: checkoutPaid ?? this.checkoutPaid,
      cart: cart ?? this.cart,
      lastCheckout: lastCheckout ?? this.lastCheckout,
      error: error,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  int _sessionGeneration = 0;
  int _recoveryGeneration = 0;
  int _cartLoadGeneration = 0;

  @override
  CartState build() => const CartState();

  void resetForSessionChange() {
    _sessionGeneration++;
    _recoveryGeneration++;
    _cartLoadGeneration++;
    state = const CartState();
  }

  Future<void> recoverCheckout() async {
    final generation = _sessionGeneration;
    final request = ++_recoveryGeneration;
    state = state.copyWith(
      isRecoveringCheckout: true,
      checkoutRecoveryRequired: true,
    );
    final result = await ref
        .read(cartRepositoryProvider)
        .recoverCheckout(hosted: kIsWeb);
    if (!ref.mounted ||
        generation != _sessionGeneration ||
        request != _recoveryGeneration) {
      return;
    }
    result.fold((_) => state = state.copyWith(isRecoveringCheckout: false), (
      attempt,
    ) {
      if (attempt == null) {
        state = CartState(cart: state.cart);
        return;
      }
      if (attempt.status == 'PAID') {
        state = state.copyWith(
          isRecoveringCheckout: false,
          checkoutRecoveryRequired: false,
          checkoutPaid: state.cart.items.isEmpty,
        );
        return;
      }
      final secret = attempt.paymentIntentClientSecret;
      final url = attempt.checkoutUrl;
      if (attempt.status == 'CHECKING' && (url != null || secret != null)) {
        state = state.copyWith(
          isRecoveringCheckout: false,
          checkoutRecoveryRequired: false,
          lastCheckout: CartCheckoutEntity(
            paymentGroupId: attempt.paymentGroupId,
            totalOrders: attempt.orderIds.length,
            totalAmount: attempt.totalAmount,
            checkoutUrl: url,
            paymentIntentClientSecret: secret,
          ),
        );
      } else {
        state = state.copyWith(isRecoveringCheckout: false);
      }
    });
  }

  Future<void> loadCart() async {
    final generation = _sessionGeneration;
    final request = ++_cartLoadGeneration;
    state = state.copyWith(isLoading: true);
    final result = await ref.read(cartRepositoryProvider).getCart();
    if (!ref.mounted ||
        generation != _sessionGeneration ||
        request != _cartLoadGeneration) {
      return;
    }
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (cart) => state = state.copyWith(
        isLoading: false,
        cart: cart,
        checkoutPaid: cart.items.isEmpty ? state.checkoutPaid : false,
      ),
    );
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    final generation = _sessionGeneration;
    final result = await ref
        .read(cartRepositoryProvider)
        .addToCart(productId, quantity: quantity);
    if (!ref.mounted || generation != _sessionGeneration) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        state = CartState(cart: state.cart);
        await loadCart();
        return ref.mounted && generation == _sessionGeneration;
      },
    );
  }

  Future<bool> updateQuantity(String productId, int quantity) async {
    final generation = _sessionGeneration;
    final result = await ref
        .read(cartRepositoryProvider)
        .updateQuantity(productId, quantity);
    if (!ref.mounted || generation != _sessionGeneration) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return ref.mounted && generation == _sessionGeneration;
      },
    );
  }

  Future<bool> removeFromCart(String productId) async {
    final generation = _sessionGeneration;
    final result = await ref
        .read(cartRepositoryProvider)
        .removeFromCart(productId);
    if (!ref.mounted || generation != _sessionGeneration) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return ref.mounted && generation == _sessionGeneration;
      },
    );
  }

  Future<bool> clearCart() async {
    final generation = _sessionGeneration;
    final result = await ref.read(cartRepositoryProvider).clearCart();
    if (!ref.mounted || generation != _sessionGeneration) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await loadCart();
        return ref.mounted && generation == _sessionGeneration;
      },
    );
  }

  Future<bool> checkout() async {
    if (state.checkoutRecoveryRequired || state.isRecoveringCheckout) {
      return false;
    }
    final generation = _sessionGeneration;
    state = state.copyWith(isCheckingOut: true);
    final result = await ref
        .read(cartRepositoryProvider)
        .checkoutCart(hosted: kIsWeb);
    if (!ref.mounted || generation != _sessionGeneration) return false;
    final success = result.fold(
      (failure) {
        state = state.copyWith(
          isCheckingOut: false,
          checkoutRecoveryRequired: true,
          error: failure.message,
        );
        return false;
      },
      (checkout) {
        state = state.copyWith(
          isCheckingOut: false,
          lastCheckout: checkout,
          checkoutPaid: false,
        );
        return true;
      },
    );
    if (!success) await recoverCheckout();
    if (success) {
      ref.invalidate(purchasesListProvider);
      ref.invalidate(salesListProvider);
      ref.invalidate(myProductsProvider);
      await loadCart();
    }
    return success && ref.mounted && generation == _sessionGeneration;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).cart.totalItems;
});

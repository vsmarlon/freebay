import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/domain/repositories/cart_repository.dart';
import 'package:freebay/features/cart/presentation/providers/cart_provider.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _CartRepository implements CartRepository {
  final pending = <Completer<Either<Failure, CartEntity>>>[];
  final pendingMutations = <Completer<Either<Failure, void>>>[];
  final pendingCheckouts = <Completer<Either<Failure, CartCheckoutEntity>>>[];

  @override
  Future<Either<Failure, CartEntity>> getCart() {
    final request = Completer<Either<Failure, CartEntity>>();
    pending.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, void>> addToCart(
    String productId, {
    int quantity = 1,
  }) => _mutation();

  @override
  Future<Either<Failure, void>> clearCart() async => const Right(null);

  @override
  Future<Either<Failure, CartCheckoutEntity>> checkoutCart({
    bool hosted = false,
  }) {
    final request = Completer<Either<Failure, CartCheckoutEntity>>();
    pendingCheckouts.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, void>> removeFromCart(String productId) => _mutation();

  @override
  Future<Either<Failure, void>> updateQuantity(
    String productId,
    int quantity,
  ) => _mutation();

  Future<Either<Failure, void>> _mutation() {
    final request = Completer<Either<Failure, void>>();
    pendingMutations.add(request);
    return request.future;
  }
}

void main() {
  test(
    'an old account cart response cannot restore after session reset',
    () async {
      final repository = _CartRepository();
      final container = ProviderContainer(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final loading = container.read(cartProvider.notifier).loadCart();
      container.read(cartProvider.notifier).resetForSessionChange();
      repository.pending.single.complete(
        const Right(CartEntity(totalItems: 3, totalPrice: 1200)),
      );
      await loading;

      expect(container.read(cartProvider).cart.totalItems, 0);
    },
  );

  test(
    'a new session hydrates its cart after the previous load is discarded',
    () async {
      final repository = _CartRepository();
      final container = ProviderContainer(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final accountALoad = container.read(cartProvider.notifier).loadCart();
      container.read(cartProvider.notifier).resetForSessionChange();
      final accountBLoad = container.read(cartProvider.notifier).loadCart();

      repository.pending[0].complete(
        const Right(CartEntity(totalItems: 3, totalPrice: 1200)),
      );
      await accountALoad;
      expect(container.read(cartProvider).cart.totalItems, 0);

      repository.pending[1].complete(
        const Right(CartEntity(totalItems: 2, totalPrice: 850)),
      );
      await accountBLoad;
      expect(container.read(cartProvider).cart.totalItems, 2);
      expect(container.read(cartProvider).cart.totalPrice, 850);
    },
  );

  test(
    'a mutation completing after reset cannot reload or replace the next cart',
    () async {
      final repository = _CartRepository();
      final container = ProviderContainer(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final mutation = container.read(cartProvider.notifier).addToCart('old');
      container.read(cartProvider.notifier).resetForSessionChange();
      repository.pendingMutations.single.complete(const Right(null));

      expect(await mutation, isFalse);
      expect(repository.pending, isEmpty);
      expect(container.read(cartProvider).cart.totalItems, 0);
    },
  );

  test(
    'checkout completion after reset does not retain checkout state or reload',
    () async {
      final repository = _CartRepository();
      final container = ProviderContainer(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final checkout = container.read(cartProvider.notifier).checkout();
      expect(container.read(cartProvider).isCheckingOut, isTrue);
      container.read(cartProvider.notifier).resetForSessionChange();
      repository.pendingCheckouts.single.complete(
        const Right(CartCheckoutEntity(paymentGroupId: 'old-group')),
      );

      expect(await checkout, isFalse);
      expect(repository.pending, isEmpty);
      expect(container.read(cartProvider).isCheckingOut, isFalse);
      expect(container.read(cartProvider).lastCheckout, isNull);
    },
  );
}

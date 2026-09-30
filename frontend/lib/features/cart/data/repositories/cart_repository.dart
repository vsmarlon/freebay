import 'package:dio/dio.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/domain/repositories/cart_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';

class CartRepositoryImpl implements CartRepository {
  final Dio client;

  CartRepositoryImpl({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, CartEntity>> getCart() => requestEither(
    () => client.get('/cart'),
    decoder: (response) => Right(CartEntity.fromJson(response.data['data'])),
  );

  @override
  Future<Either<Failure, void>> addToCart(
    String productId, {
    int quantity = 1,
  }) => requestEither<void>(
    () => client.post('/cart/$productId', data: {'quantity': quantity}),
    decoder: (_) => const Right(null),
  );

  @override
  Future<Either<Failure, void>> updateQuantity(
    String productId,
    int quantity,
  ) => requestEither<void>(
    () => client.patch('/cart/$productId', data: {'quantity': quantity}),
    decoder: (_) => const Right(null),
  );

  @override
  Future<Either<Failure, void>> removeFromCart(String productId) =>
      requestEither<void>(
        () => client.patch('/cart/$productId/remove'),
        decoder: (_) => const Right(null),
      );

  @override
  Future<Either<Failure, void>> clearCart() => requestEither<void>(
    () => client.patch('/cart/clear'),
    decoder: (_) => const Right(null),
  );

  @override
  Future<Either<Failure, CartCheckoutEntity>> checkoutCart({
    bool hosted = false,
  }) => requestEither(
    () => client.post(
      '/cart/checkout',
      data: {'mode': hosted ? 'session' : 'intent'},
    ),
    decoder: (response) =>
        Right(CartCheckoutEntity.fromJson(response.data['data'])),
  );
}

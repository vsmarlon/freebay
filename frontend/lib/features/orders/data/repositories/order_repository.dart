import 'package:dio/dio.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/services/http_client.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Dio client;

  OrderRepositoryImpl({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) =>
      requestEither(
        () => client.get('/orders/$orderId'),
        decoder: (response) =>
            Right(OrderEntity.fromJson(response.data['data']['order'])),
      );

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) => requestEither(
    () => client.get(
      '/orders/my/purchases',
      queryParameters: {
        'cursor': ?cursor,
        'limit': limit,
        'status': ?status?.toApiString(),
      },
    ),
    decoder: (response) => Right(
      parseCursorPage<OrderEntity>(response.data['data'], OrderEntity.fromJson),
    ),
  );

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  }) => requestEither(
    () => client.get(
      '/orders/my/sales',
      queryParameters: {
        'cursor': ?cursor,
        'limit': limit,
        'status': ?status?.toApiString(),
      },
    ),
    decoder: (response) => Right(
      parseCursorPage<OrderEntity>(response.data['data'], OrderEntity.fromJson),
    ),
  );

  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) =>
      requestEither(
        () => client.post('/orders/$orderId/confirm-delivery'),
        decoder: (response) =>
            Right(OrderEntity.fromJson(response.data['data'])),
      );

  @override
  Future<Either<Failure, OrderEntity>> createOrder(String productId) =>
      requestEither(
        () => client.post('/orders', data: {'productId': productId}),
        decoder: (response) =>
            Right(OrderEntity.fromJson(response.data['data'])),
      );

  @override
  Future<Either<Failure, String>> cancelOrder(
    String orderId, {
    String? reason,
  }) => requestEither(
    () => client.patch(
      '/orders/$orderId/cancel',
      data: {'reason': reason ?? 'Cancelado pelo usuário'},
    ),
    decoder: (response) =>
        Right(response.data['data'] as String? ?? 'CANCELLED'),
  );

  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId) =>
      requestEither(
        () => client.get('/reviews/orders/$orderId/can-review'),
        decoder: (response) {
          final data = response.data['data'];
          return Right(
            data is Map<String, dynamic>
                ? CanReviewResponse.fromJson(data)
                : const CanReviewResponse(),
          );
        },
      );
}

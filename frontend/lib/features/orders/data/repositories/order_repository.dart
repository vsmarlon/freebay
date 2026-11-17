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
  Future<Either<Failure, OrderEntity>> getOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) => requestEither(
    () => client.get('/orders/$orderId', cancelToken: cancelToken),
    decoder: (response) {
      final data = response.data['data'] as Map<String, dynamic>;
      final order = Map<String, dynamic>.from(data['order'] as Map);
      final actions = data['allowedActions'];
      order['allowedActions'] = actions is List
          ? actions.whereType<String>().toList()
          : const <String>[];
      return Right(OrderEntity.fromJson(order));
    },
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
      _transition(orderId, 'confirm-delivery');

  @override
  Future<Either<Failure, OrderEntity>> markAsShipped(String orderId) =>
      _transition(orderId, 'ship');

  @override
  Future<Either<Failure, OrderEntity>> markAsDelivered(String orderId) =>
      _transition(orderId, 'deliver');

  Future<Either<Failure, OrderEntity>> _transition(
    String orderId,
    String action,
  ) async {
    final result = await requestEither<void>(
      () => client.patch('/orders/$orderId/$action'),
      decoder: (_) => const Right(null),
    );
    if (result.isLeft) {
      return Left(result.leftOrNull!);
    }

    // Transitions return an acknowledgement; reload the canonical order.
    return getOrder(orderId);
  }

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
    required String stepUpToken,
  }) => requestEither(
    () => client.patch(
      '/orders/$orderId/cancel',
      data: {'reason': reason ?? 'Cancelado pelo usuário'},
      options: Options(headers: {'x-step-up-token': stepUpToken}),
    ),
    decoder: (response) =>
        Right(response.data['data'] as String? ?? 'CANCELLED'),
  );

  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(
    String orderId, {
    CancelToken? cancelToken,
  }) => requestEither(
    () => client.get(
      '/reviews/orders/$orderId/can-review',
      cancelToken: cancelToken,
    ),
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

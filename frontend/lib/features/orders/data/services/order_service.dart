import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/entities/order_list_response.dart';

class OrderService extends BaseHttpRepository {
  OrderService({super.client});

  Future<Either<Failure, OrderEntity>> getOrder(String orderId) =>
      safeGet<OrderEntity>(
        '/orders/$orderId',
        extractKey: 'data',
        fromJson: OrderEntity.fromJson,
      );

  Future<Either<Failure, OrderListResponse>> getMyPurchases({
    int limit = 10,
    int offset = 0,
    String? status,
  }) => safeGet<OrderListResponse>(
    '/orders/my/purchases',
    queryParameters: {'limit': limit, 'offset': offset, 'status': ?status},
    extractKey: 'data',
    fromJson: OrderListResponse.fromJson,
  );

  Future<Either<Failure, OrderListResponse>> getMySales({
    int limit = 10,
    int offset = 0,
    String? status,
  }) => safeGet<OrderListResponse>(
    '/orders/my/sales',
    queryParameters: {'limit': limit, 'offset': offset, 'status': ?status},
    extractKey: 'data',
    fromJson: OrderListResponse.fromJson,
  );

  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) =>
      safePost<OrderEntity>(
        '/orders/$orderId/confirm-delivery',
        extractKey: 'data',
        fromJson: OrderEntity.fromJson,
      );

  Future<Either<Failure, OrderEntity>> createOrder(String productId) =>
      safePost<OrderEntity>(
        '/orders',
        data: {'productId': productId},
        extractKey: 'data',
        fromJson: OrderEntity.fromJson,
      );

  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId) =>
      safePost<OrderEntity>(
        '/orders/$orderId/cancel',
        extractKey: 'data',
        fromJson: OrderEntity.fromJson,
      );

  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId) =>
      safeGet<CanReviewResponse>(
        '/reviews/orders/$orderId/can-review',
        extractKey: 'data',
        fromJson: CanReviewResponse.fromJson,
        customMapper: (d) => d is Map<String, dynamic>
            ? CanReviewResponse.fromJson(d)
            : const CanReviewResponse(canReview: false),
      );
}

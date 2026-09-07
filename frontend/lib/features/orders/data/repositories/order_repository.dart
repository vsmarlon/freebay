import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class OrderRepository {
  final OrderService _service;

  OrderRepository(this._service);

  Future<Either<Failure, OrderEntity>> getOrder(String orderId) {
    return _service.getOrder(orderId);
  }

  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = 20,
    String? status,
  }) {
    return _service.getMyPurchases(
      cursor: cursor,
      limit: limit,
      status: status,
    );
  }

  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = 20,
    String? status,
  }) {
    return _service.getMySales(cursor: cursor, limit: limit, status: status);
  }

  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) {
    return _service.confirmDelivery(orderId);
  }

  Future<Either<Failure, OrderEntity>> createOrder(String productId) {
    return _service.createOrder(productId);
  }

  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId) {
    return _service.cancelOrder(orderId);
  }

  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId) {
    return _service.canReviewOrder(orderId);
  }
}

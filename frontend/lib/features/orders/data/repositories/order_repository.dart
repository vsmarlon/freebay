import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/features/orders/domain/repositories/i_order_repository.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class OrderRepository implements IOrderRepository {
  final OrderService _service;

  OrderRepository(this._service);

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) {
    return _service.getOrder(orderId);
  }

  @override
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

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = 20,
    String? status,
  }) {
    return _service.getMySales(cursor: cursor, limit: limit, status: status);
  }

  @override
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) {
    return _service.confirmDelivery(orderId);
  }

  @override
  Future<Either<Failure, OrderEntity>> createOrder(String productId) {
    return _service.createOrder(productId);
  }

  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId) {
    return _service.cancelOrder(orderId);
  }

  @override
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId) {
    return _service.canReviewOrder(orderId);
  }
}

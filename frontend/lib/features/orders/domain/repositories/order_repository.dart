import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';

const defaultOrderPageLimit = 20;

abstract interface class OrderRepository {
  Future<Either<Failure, OrderEntity>> getOrder(String orderId);
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  });
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = defaultOrderPageLimit,
    OrderStatus? status,
  });
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId);
  Future<Either<Failure, OrderEntity>> createOrder(String productId);
  Future<Either<Failure, String>> cancelOrder(String orderId, {String? reason});
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId);
}

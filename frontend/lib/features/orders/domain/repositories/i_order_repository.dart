import 'package:dartz/dartz.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

abstract class IOrderRepository {
  Future<Either<Failure, OrderEntity>> getOrder(String orderId);
  Future<Either<Failure, OrderListResponse>> getMyPurchases({
    int limit = 10,
    int offset = 0,
    String? status,
  });
  Future<Either<Failure, OrderListResponse>> getMySales({
    int limit = 10,
    int offset = 0,
    String? status,
  });
  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId);
  Future<Either<Failure, OrderEntity>> createOrder(String productId);
  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId);
  Future<Either<Failure, CanReviewResponse>> canReviewOrder(String orderId);
}

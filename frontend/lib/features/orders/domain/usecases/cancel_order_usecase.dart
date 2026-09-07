import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';

class CancelOrderUsecase implements Usecase<OrderEntity, String> {
  final OrderRepository _repository;

  CancelOrderUsecase(this._repository);

  @override
  UsecaseResponse<Failure, OrderEntity> call(String orderId) {
    return _repository.cancelOrder(orderId);
  }
}

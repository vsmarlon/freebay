import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/i_order_repository.dart';

class CanReviewOrderUsecase implements Usecase<CanReviewResponse, String> {
  final IOrderRepository _repository;

  CanReviewOrderUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CanReviewResponse> call(String orderId) {
    return _repository.canReviewOrder(orderId);
  }
}

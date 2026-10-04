import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';

typedef CancelOrderParams = ({
  String orderId,
  String reason,
  String stepUpToken,
});

class CancelOrderUsecase implements Usecase<String, CancelOrderParams> {
  final OrderRepository _repository;

  CancelOrderUsecase(this._repository);

  @override
  UsecaseResponse<Failure, String> call(CancelOrderParams params) {
    return _repository.cancelOrder(
      params.orderId,
      reason: params.reason,
      stepUpToken: params.stepUpToken,
    );
  }
}

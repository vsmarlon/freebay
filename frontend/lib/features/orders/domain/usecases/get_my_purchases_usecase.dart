import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/features/orders/domain/repositories/i_order_repository.dart';

class GetMyPurchasesParams {
  final int limit;
  final int offset;
  final String? status;

  GetMyPurchasesParams({this.limit = 10, this.offset = 0, this.status});
}

class GetMyPurchasesUsecase
    implements Usecase<OrderListResponse, GetMyPurchasesParams> {
  final IOrderRepository _repository;

  GetMyPurchasesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, OrderListResponse> call(
      GetMyPurchasesParams params) {
    return _repository.getMyPurchases(
      limit: params.limit,
      offset: params.offset,
      status: params.status,
    );
  }
}

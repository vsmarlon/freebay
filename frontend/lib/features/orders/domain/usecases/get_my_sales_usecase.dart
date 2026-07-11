import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/orders/data/entities/order_list_response.dart';
import 'package:freebay/features/orders/domain/repositories/i_order_repository.dart';

class GetMySalesParams {
  final int limit;
  final int offset;
  final String? status;

  GetMySalesParams({this.limit = 10, this.offset = 0, this.status});
}

class GetMySalesUsecase
    implements Usecase<OrderListResponse, GetMySalesParams> {
  final IOrderRepository _repository;

  GetMySalesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, OrderListResponse> call(GetMySalesParams params) {
    return _repository.getMySales(
      limit: params.limit,
      offset: params.offset,
      status: params.status,
    );
  }
}

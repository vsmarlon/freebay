import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';

class GetMySalesParams {
  final String? cursor;
  final int limit;
  final String? status;

  GetMySalesParams({this.cursor, this.limit = 20, this.status});
}

class GetMySalesUsecase
    implements Usecase<CursorPage<OrderEntity>, GetMySalesParams> {
  final OrderRepository _repository;

  GetMySalesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CursorPage<OrderEntity>> call(
    GetMySalesParams params,
  ) {
    return _repository.getMySales(
      cursor: params.cursor,
      limit: params.limit,
      status: params.status,
    );
  }
}

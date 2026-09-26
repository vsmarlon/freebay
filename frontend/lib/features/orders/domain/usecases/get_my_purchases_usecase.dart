import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/domain/repositories/order_repository.dart';

class GetMyPurchasesParams {
  final String? cursor;
  final int limit;
  final OrderStatus? status;

  GetMyPurchasesParams({
    this.cursor,
    this.limit = defaultOrderPageLimit,
    this.status,
  });
}

class GetMyPurchasesUsecase
    implements Usecase<CursorPage<OrderEntity>, GetMyPurchasesParams> {
  final OrderRepository _repository;

  GetMyPurchasesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CursorPage<OrderEntity>> call(
    GetMyPurchasesParams params,
  ) {
    return _repository.getMyPurchases(
      cursor: params.cursor,
      limit: params.limit,
      status: params.status,
    );
  }
}

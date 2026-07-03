import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class UpdateCartQuantityParams {
  final String productId;
  final int quantity;

  UpdateCartQuantityParams({required this.productId, required this.quantity});
}

class UpdateCartQuantityUsecase
    implements Usecase<void, UpdateCartQuantityParams> {
  final ICartRepository _repository;

  UpdateCartQuantityUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call(UpdateCartQuantityParams params) {
    return _repository.updateQuantity(params.productId, params.quantity);
  }
}

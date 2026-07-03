import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class ClearCartUsecase implements NoParamsUsecase<void> {
  final ICartRepository _repository;

  ClearCartUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call() {
    return _repository.clearCart();
  }
}

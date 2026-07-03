import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class RemoveFromCartUsecase implements Usecase<void, String> {
  final ICartRepository _repository;

  RemoveFromCartUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call(String productId) {
    return _repository.removeFromCart(productId);
  }
}

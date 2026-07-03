import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class CheckoutCartUsecase implements NoParamsUsecase<CartCheckoutEntity> {
  final ICartRepository _repository;

  CheckoutCartUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CartCheckoutEntity> call() {
    return _repository.checkoutCart();
  }
}

import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class AddToCartParams {
  final String productId;
  final int quantity;

  AddToCartParams({required this.productId, this.quantity = 1});
}

class AddToCartUsecase implements Usecase<void, AddToCartParams> {
  final ICartRepository _repository;

  AddToCartUsecase(this._repository);

  @override
  UsecaseResponse<Failure, void> call(AddToCartParams params) {
    return _repository.addToCart(params.productId, quantity: params.quantity);
  }
}

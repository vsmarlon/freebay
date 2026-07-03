import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/features/cart/domain/repositories/i_cart_repository.dart';

class GetCartUsecase implements NoParamsUsecase<CartEntity> {
  final ICartRepository _repository;

  GetCartUsecase(this._repository);

  @override
  UsecaseResponse<Failure, CartEntity> call() {
    return _repository.getCart();
  }
}

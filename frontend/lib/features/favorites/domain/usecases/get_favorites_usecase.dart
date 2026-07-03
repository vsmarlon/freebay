import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/favorites/domain/repositories/i_favorites_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class GetFavoritesUsecase implements NoParamsUsecase<List<ProductEntity>> {
  final IFavoritesRepository _repository;

  GetFavoritesUsecase(this._repository);

  @override
  UsecaseResponse<Failure, List<ProductEntity>> call() {
    return _repository.getFavorites();
  }
}

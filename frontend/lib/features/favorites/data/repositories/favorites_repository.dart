import 'package:freebay/shared/either/either.dart';
import 'package:freebay/features/favorites/data/services/favorites_service.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class FavoritesRepository {
  final FavoritesService _service;

  FavoritesRepository(this._service);

  Future<Either<Failure, void>> toggleFavorite(String productId) {
    return _service.toggleFavorite(productId);
  }

  Future<Either<Failure, bool>> isFavorited(String productId) {
    return _service.isFavorited(productId);
  }

  Future<Either<Failure, List<ProductEntity>>> getFavorites() {
    return _service.getFavorites();
  }
}

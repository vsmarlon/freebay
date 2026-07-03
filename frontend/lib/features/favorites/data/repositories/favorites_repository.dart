import 'package:dartz/dartz.dart';
import 'package:freebay/features/favorites/data/services/favorites_service.dart';
import 'package:freebay/features/favorites/domain/repositories/i_favorites_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class FavoritesRepository implements IFavoritesRepository {
  final FavoritesService _service;

  FavoritesRepository(this._service);

  @override
  Future<Either<Failure, bool>> toggleFavorite(String productId) {
    return _service.toggleFavorite(productId);
  }

  @override
  Future<Either<Failure, bool>> isFavorited(String productId) {
    return _service.isFavorited(productId);
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getFavorites() {
    return _service.getFavorites();
  }
}

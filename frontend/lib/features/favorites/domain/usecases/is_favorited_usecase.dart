import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/favorites/domain/repositories/i_favorites_repository.dart';

class IsFavoritedUsecase implements Usecase<bool, String> {
  final IFavoritesRepository _repository;

  IsFavoritedUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call(String productId) {
    return _repository.isFavorited(productId);
  }
}

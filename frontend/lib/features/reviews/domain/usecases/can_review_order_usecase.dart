import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/reviews/domain/repositories/i_review_repository.dart';

class CanReviewOrderUsecase implements Usecase<bool, String> {
  final IReviewRepository _repository;

  CanReviewOrderUsecase(this._repository);

  @override
  UsecaseResponse<Failure, bool> call(String orderId) {
    return _repository.canReviewOrder(orderId);
  }
}

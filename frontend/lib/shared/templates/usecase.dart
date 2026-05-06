import 'package:dartz/dartz.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

typedef UsecaseResponse<Failure, Output> = Future<Either<Failure, Output>>;

abstract class Usecase<Output, Params> {
  UsecaseResponse<Failure, Output> call(Params params);
}

class NoParams {}

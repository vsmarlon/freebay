import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';

abstract class ICategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
}

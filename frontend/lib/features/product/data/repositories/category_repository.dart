import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/product/domain/repositories/i_category_repository.dart';

class CategoryRepository extends BaseHttpRepository
    implements ICategoryRepository {
  CategoryRepository({super.client});

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      safeGetList<CategoryEntity>(
        '/categories',
        listKey: 'data.categories',
        fromJson: CategoryEntity.fromJson,
      );
}

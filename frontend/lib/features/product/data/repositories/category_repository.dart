import 'package:dartz/dartz.dart';
import 'package:freebay/shared/services/http_client.dart';
import '../../../../shared/errors/failures/failures.dart';
import '../entities/category_entity.dart';

class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final response = await HttpClient.instance.get('/categories');

      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data as Map<String, dynamic>;
        final categoriesData = payload['categories'] as List<dynamic>? ??
            ((payload['data'] as Map<String, dynamic>?)?['categories']
                    as List<dynamic>? ??
                <dynamic>[]);
        final categories = categoriesData
            .map(
                (json) => CategoryEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(categories);
      }
      return const Left(ServerFailure('Erro ao carregar categorias'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }
}

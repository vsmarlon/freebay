import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';

class CategoryRepository {
  final Dio client;

  CategoryRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      requestEither(
        () => client.get('/categories'),
        decoder: (response) {
          final raw = response.data['data']['categories'];
          final categories = raw is List
              ? raw
                    .whereType<Map>()
                    .map(
                      (item) => CategoryEntity.fromJson(
                        Map<String, dynamic>.from(item),
                      ),
                    )
                    .toList()
              : <CategoryEntity>[];
          return Right(categories);
        },
      );
}

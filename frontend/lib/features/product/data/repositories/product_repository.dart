import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/create_product_input.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

class ProductRepository {
  final Dio client;

  ProductRepository({Dio? client}) : client = client ?? HttpClient.instance;

  Future<Either<Failure, ProductEntity>> getProductById(
    String id, {
    CancelToken? cancelToken,
  }) => requestEither(
    () => client.get('/products/$id', cancelToken: cancelToken),
    decoder: (response) =>
        Right(ProductEntity.fromJson(response.data['data']['product'])),
  );

  Future<Either<Failure, ProductPageResult>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
    ProductCondition? condition,
    String? sort,
    CancelToken? cancelToken,
  }) => requestEither<ProductPageResult>(
    () => client.get(
      '/products',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (condition != null) 'condition': condition.wireValue,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'minPrice': ?minPrice,
        'maxPrice': ?maxPrice,
        'cursor': ?cursor,
      },
      cancelToken: cancelToken,
    ),
    decoder: (response) {
      final data = response.data['data'];
      final map = data as Map<String, dynamic>?;
      final productsData = (map?['products'] as List?) ?? [];
      final nextCursor = map?['nextCursor'] as String?;
      final products = productsData
          .whereType<Map>()
          .map((j) => ProductEntity.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      return Right(
        ProductPageResult(
          products: products,
          hasMore: nextCursor != null,
          nextCursor: nextCursor,
        ),
      );
    },
  );

  Future<Either<Failure, ProductEntity>> createProduct(
    CreateProductInput input,
  ) async {
    if (input.imagePath.isEmpty) return const Left(UnknownFailure());
    try {
      final formData = FormData.fromMap({
        'title': input.title,
        'description': input.description,
        'price': input.price,
        'condition': input.condition.wireValue,
        'categoryId': input.categoryId,
        'image': await ImageUploadService.compressedMultipartFile(
          input.imagePath,
          filename: 'product.jpg',
        ),
      });
      return requestEither(
        () => client.post(
          '/products',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        ),
        decoder: (response) =>
            Right(ProductEntity.fromJson(response.data['data'])),
      );
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) => requestEither(
    () => client.patch('/products/$id', data: productData),
    decoder: (response) => Right(ProductEntity.fromJson(response.data['data'])),
  );

  Future<Either<Failure, List<ProductEntity>>> getMyProducts() => requestEither(
    () => client.get('/products/mine/all'),
    decoder: (response) {
      final raw = response.data['data']['products'];
      final products = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      ProductEntity.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <ProductEntity>[];
      return Right(products);
    },
  );
}

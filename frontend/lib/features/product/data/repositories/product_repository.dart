import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/image_upload_service.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/product/domain/repositories/i_product_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class ProductRepository implements IProductRepository {
  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final response = await HttpClient.instance.get('/products/$id');

      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById status: ${response.statusCode}');
        debugPrint('[PRODUCT] getProductById data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final productData = responseData['product'] as Map<String, dynamic>;
        
        // Extract seller info
        if (productData['seller'] != null) {
          productData['sellerName'] = productData['seller']['displayName'];
          productData['sellerAvatar'] = productData['seller']['avatarUrl'];
        }
        final images = productData['images'] as List?;
        if (images != null && images.isNotEmpty) {
          final firstImage = images.first as Map;
          productData['imageUrl'] = firstImage['url'];
        }
        return Right(ProductEntity.fromJson(productData));
      }
      return const Left(NotFoundFailure('Produto não encontrado.'));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProductById error: $e');
        debugPrint('[PRODUCT] getProductById stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? search,
    String? category,
    int? minPrice,
    int? maxPrice,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await HttpClient.instance
          .get('/products', queryParameters: queryParams);

      if (kDebugMode) {
        debugPrint('[PRODUCT] getProducts status: ${response.statusCode}');
        debugPrint('[PRODUCT] getProducts data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final productsData = (data?['products'] as List?) ?? [];

        final products = productsData.map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          if (map['seller'] != null) {
            map['sellerName'] = map['seller']['displayName'];
            map['sellerAvatar'] = map['seller']['avatarUrl'];
          }
          final images = map['images'] as List?;
          if (images != null && images.isNotEmpty) {
            final firstImage = images.first as Map;
            map['imageUrl'] = firstImage['url'];
          }
          return ProductEntity.fromJson(map);
        }).toList();

        return Right(products);
      } else {
        return const Left(ServerFailure('Erro ao carregar os anúncios.'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProducts DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getProducts error: $e');
        debugPrint('[PRODUCT] getProducts stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final imagePath = productData.remove('imagePath') as String?;
      if (kDebugMode) {
        debugPrint('[PRODUCT REPO] createProduct payload=$productData');
        debugPrint('[PRODUCT REPO] createProduct imagePath=$imagePath');
      }
      final formData = FormData.fromMap({
        ...productData,
        if (imagePath != null)
          'image': await ImageUploadService.compressedMultipartFile(
            imagePath,
            filename: 'product.jpg',
          ),
      });

      final response = await HttpClient.instance.post(
        '/products',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (kDebugMode) {
        debugPrint('[PRODUCT REPO] createProduct status=${response.statusCode}');
        debugPrint('[PRODUCT REPO] createProduct response=${response.data}');
      }
      if (response.statusCode == 201 && response.data != null) {
        return Right(ProductEntity.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro ao criar anúncio.'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] createProduct DioException: ${e.type}');
        debugPrint('[PRODUCT] createProduct message: ${e.message}');
        debugPrint('[PRODUCT] createProduct response: ${e.response?.data}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] createProduct unexpected error: $e');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await HttpClient.instance.patch(
        '/products/$id',
        data: productData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(ProductEntity.fromJson(data));
      }

      return const Left(ServerFailure('Erro ao atualizar anúncio.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, List<ProductEntity>>> getMyProducts() async {
    try {
      final response = await HttpClient.instance.get('/products/mine/all');

      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts status: ${response.statusCode}');
        debugPrint('[PRODUCT] getMyProducts data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final productsData = (data?['products'] as List?) ?? [];

        final products = productsData.map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          if (map['seller'] != null) {
            map['sellerName'] = map['seller']['displayName'];
            map['sellerAvatar'] = map['seller']['avatarUrl'];
          }
          final images = map['images'] as List?;
          if (images != null && images.isNotEmpty) {
            final firstImage = images.first as Map;
            map['imageUrl'] = firstImage['url'];
          }
          return ProductEntity.fromJson(map);
        }).toList();

        return Right(products);
      }
      return const Left(ServerFailure('Erro ao carregar seus anúncios.'));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts DioException: ${e.type}');
      }
      return Left(mapDioExceptionToFailure(e));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] getMyProducts error: $e');
        debugPrint('[PRODUCT] getMyProducts stack: $stack');
      }
      return const Left(UnknownFailure());
    }
  }
}

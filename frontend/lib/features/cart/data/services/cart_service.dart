import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/features/cart/data/entities/cart_checkout_entity.dart';
import 'package:freebay/features/cart/data/entities/cart_entity.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/services/http_client.dart';

class CartService {
  Future<Either<Failure, CartEntity>> getCart() async {
    try {
      final response = await HttpClient.instance.get('/cart');
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(CartEntity.fromJson(data));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, void>> addToCart(String productId, {int quantity = 1}) async {
    try {
      await HttpClient.instance.post(
        '/cart/$productId',
        data: {'quantity': quantity},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, void>> updateQuantity(String productId, int quantity) async {
    try {
      await HttpClient.instance.patch(
        '/cart/$productId',
        data: {'quantity': quantity},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, void>> removeFromCart(String productId) async {
    try {
      await HttpClient.instance.delete('/cart/$productId');
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, void>> clearCart() async {
    try {
      await HttpClient.instance.delete('/cart');
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<Either<Failure, CartCheckoutEntity>> checkoutCart({
    required String customerName,
    required String customerTaxId,
    required String customerEmail,
  }) async {
    try {
      final response = await HttpClient.instance.post(
        '/cart/checkout',
        data: {
          'customerName': customerName,
          'customerTaxId': customerTaxId,
          'customerEmail': customerEmail,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return Right(CartCheckoutEntity.fromJson(data));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}

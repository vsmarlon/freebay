import 'package:freebay/shared/either/either.dart';

import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

import 'package:freebay/features/orders/data/entities/order_list_response.dart';

class OrderService {
  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final wrappedData = data['data'];
      if (wrappedData is Map<String, dynamic>) {
        return wrappedData;
      }

      final order = data['order'];
      if (order is Map<String, dynamic>) {
        return order;
      }

      return data;
    }

    return <String, dynamic>{};
  }

  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async {
    try {
      final response = await HttpClient.instance.get('/orders/$orderId');

      if (response.statusCode == 200 && response.data != null) {
        final payload = _extractPayload(response.data);
        return Right(OrderEntity.fromJson(payload));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, OrderListResponse>> getMyPurchases({
    int limit = 10,
    int offset = 0,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await HttpClient.instance.get(
        '/orders/my/purchases',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(OrderListResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, OrderListResponse>> getMySales({
    int limit = 10,
    int offset = 0,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await HttpClient.instance.get(
        '/orders/my/sales',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(OrderListResponse.fromJson(response.data['data']));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) async {
    try {
      final response = await HttpClient.instance.post(
        '/orders/$orderId/confirm-delivery',
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(OrderEntity.fromJson(data));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, OrderEntity>> createOrder(String productId) async {
    try {
      final response = await HttpClient.instance.post(
        '/orders',
        data: {'productId': productId},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final payload = _extractPayload(response.data);
        return Right(OrderEntity.fromJson(payload));
      }

      return const Left(ServerFailure('Erro na requisição'));
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId) async {
    try {
      final response = await HttpClient.instance.post(
        '/orders/$orderId/cancel',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(OrderEntity.fromJson(data));
      } else {
        return const Left(ServerFailure('Erro na requisição'));
      }
    } catch (e) {
      return const Left(ServerFailure('Erro de conexão'));
    }
  }

  Future<Either<Failure, CanReviewResponse>> canReviewOrder(
    String orderId,
  ) async {
    try {
      final response = await HttpClient.instance.get(
        '/reviews/orders/$orderId/can-review',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(CanReviewResponse.fromJson(response.data['data']));
      } else {
        return Right(const CanReviewResponse(canReview: false));
      }
    } catch (e) {
      return Right(const CanReviewResponse(canReview: false));
    }
  }
}

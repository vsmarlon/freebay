import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

class OrderListResponse {
  final List<OrderEntity> orders;
  final int total;
  final int limit;
  final int offset;

  const OrderListResponse({
    required this.orders,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => OrderEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      offset: json['offset'] as int? ?? 0,
    );
  }

  bool get hasMore => offset + orders.length < total;
}

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

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData != null && responseData is Map) {
        final errorObj = responseData['error'];
        if (errorObj != null && errorObj is Map) {
          final message = errorObj['message'];
          if (message != null) return message.toString();
        }
      }
    }
    return 'Erro ao conectar com o servidor.';
  }

  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async {
    try {
      final response = await HttpClient.instance.get('/orders/$orderId');

      if (response.statusCode == 200 && response.data != null) {
        return Right(OrderEntity.fromJson(_extractPayload(response.data)));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, OrderListResponse>> getMyPurchases({
    int limit = 10,
    int offset = 0,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
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
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, OrderListResponse>> getMySales({
    int limit = 10,
    int offset = 0,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
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
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, OrderEntity>> confirmDelivery(String orderId) async {
    try {
      final response = await HttpClient.instance.post(
        '/orders/$orderId/confirm-delivery',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(OrderEntity.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
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
        return Right(OrderEntity.fromJson(_extractPayload(response.data)));
      }

      return Left(ServerFailure(_extractErrorMessage(response.data)));
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, OrderEntity>> cancelOrder(String orderId) async {
    try {
      final response = await HttpClient.instance.post(
        '/orders/$orderId/cancel',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(OrderEntity.fromJson(response.data['data']));
      } else {
        return Left(ServerFailure(_extractErrorMessage(response.data)));
      }
    } catch (e) {
      return Left(ServerFailure(_extractErrorMessage(e)));
    }
  }

  Future<Either<Failure, CanReviewResponse>> canReviewOrder(
      String orderId) async {
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

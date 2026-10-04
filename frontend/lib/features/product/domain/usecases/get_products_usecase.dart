import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/data/entities/product_page_result.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

class GetProductsParams extends Equatable {
  final String? search;
  final String? category;
  final int? minPrice;
  final int? maxPrice;
  final String? cursor;
  final ProductCondition? condition;
  final ProductSort sort;

  const GetProductsParams({
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.cursor,
    this.condition,
    this.sort = ProductSort.recent,
  });

  GetProductsParams withCursor(String? nextCursor) {
    return GetProductsParams(
      search: search,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      cursor: nextCursor,
      condition: condition,
      sort: sort,
    );
  }

  @override
  List<Object?> get props => [
    search,
    category,
    minPrice,
    maxPrice,
    cursor,
    condition,
    sort,
  ];
}

class GetProductsUsecase
    implements Usecase<ProductPageResult, GetProductsParams> {
  final ProductRepository _repository;

  GetProductsUsecase(this._repository);

  @override
  UsecaseResponse<Failure, ProductPageResult> call(
    GetProductsParams params, {
    CancelToken? cancelToken,
  }) async {
    return await _repository.getProducts(
      search: params.search,
      category: params.category,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      cursor: params.cursor,
      condition: params.condition,
      sort: params.sort.wireValue,
      cancelToken: cancelToken,
    );
  }
}

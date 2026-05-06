import 'package:equatable/equatable.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/product/domain/repositories/i_product_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class GetProductsParams extends Equatable {
  final String? search;
  final String? category;
  final int? minPrice;
  final int? maxPrice;
  final String? cursor;

  const GetProductsParams({
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.cursor,
  });

  @override
  List<Object?> get props => [search, category, minPrice, maxPrice, cursor];
}

class GetProductsUsecase
    implements Usecase<List<ProductEntity>, GetProductsParams> {
  final IProductRepository _repository;

  GetProductsUsecase(this._repository);

  @override
  UsecaseResponse<Failure, List<ProductEntity>> call(
      GetProductsParams params) async {
    return await _repository.getProducts(
      search: params.search,
      category: params.category,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      cursor: params.cursor,
    );
  }
}

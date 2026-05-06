import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/product/domain/repositories/i_product_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class CreateProductUsecase
    implements Usecase<ProductEntity, Map<String, dynamic>> {
  final IProductRepository _repository;

  CreateProductUsecase(this._repository);

  @override
  UsecaseResponse<Failure, ProductEntity> call(
      Map<String, dynamic> params) async {
    return await _repository.createProduct(params);
  }
}

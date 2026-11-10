import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/templates/usecase.dart';
import 'package:freebay/features/product/data/repositories/product_repository.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';
import 'package:freebay/features/product/data/entities/create_product_input.dart';

class CreateProductUsecase
    implements Usecase<ProductEntity, CreateProductInput> {
  final ProductRepository _repository;

  CreateProductUsecase(this._repository);

  @override
  UsecaseResponse<Failure, ProductEntity> call(
    CreateProductInput params,
  ) async {
    return await _repository.createProduct(params);
  }
}

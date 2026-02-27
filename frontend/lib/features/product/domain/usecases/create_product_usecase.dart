import '../../../../shared/errors/failures/failures.dart';
import '../../../../shared/templates/usecase.dart';
import '../repositories/i_product_repository.dart';
import '../../data/entities/product_entity.dart';

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

import 'package:freebay/features/product/data/entities/product_entity.dart';

class ProductPageResult {
  final List<ProductEntity> products;
  final bool hasMore;
  final String? nextCursor;

  const ProductPageResult({
    required this.products,
    required this.hasMore,
    this.nextCursor,
  });
}

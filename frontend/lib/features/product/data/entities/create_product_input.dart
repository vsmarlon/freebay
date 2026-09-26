import 'package:freebay/features/product/domain/product_filters.dart';

class CreateProductInput {
  final String title;
  final String description;
  final int price;
  final ProductCondition condition;
  final String categoryId;
  final String imagePath;

  const CreateProductInput({
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.categoryId,
    required this.imagePath,
  });
}

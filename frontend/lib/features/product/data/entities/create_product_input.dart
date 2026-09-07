class CreateProductInput {
  final String title;
  final String description;
  final int price;
  final String condition;
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

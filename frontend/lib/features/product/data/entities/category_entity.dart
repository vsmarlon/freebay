import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final List<CategoryEntity> children;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.children = const [],
  });

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parentId'] as String?,
      children: (json['children'] as List?)
              ?.map((c) => CategoryEntity.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, name, slug, parentId, children];
}

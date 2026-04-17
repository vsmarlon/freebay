import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_entity.g.dart';

@JsonSerializable()
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

  factory CategoryEntity.fromJson(Map<String, dynamic> json) =>
      _$CategoryEntityFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryEntityToJson(this);

  @override
  List<Object?> get props => [id, name, slug, parentId, children];
}

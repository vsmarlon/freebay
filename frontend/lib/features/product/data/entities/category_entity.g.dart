// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryEntity _$CategoryEntityFromJson(Map<String, dynamic> json) =>
    CategoryEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parentId'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CategoryEntityToJson(CategoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'parentId': instance.parentId,
      'children': instance.children,
    };

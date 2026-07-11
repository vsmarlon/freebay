// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'og_metadata_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OgMetadataEntity _$OgMetadataEntityFromJson(Map<String, dynamic> json) =>
    _OgMetadataEntity(
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      siteName: json['siteName'] as String?,
      url: json['url'] as String,
    );

Map<String, dynamic> _$OgMetadataEntityToJson(_OgMetadataEntity instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'siteName': instance.siteName,
      'url': instance.url,
    };

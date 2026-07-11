import 'package:freezed_annotation/freezed_annotation.dart';

part 'og_metadata_entity.freezed.dart';
part 'og_metadata_entity.g.dart';

@freezed
abstract class OgMetadataEntity with _$OgMetadataEntity {
  const factory OgMetadataEntity({
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    required String url,
  }) = _OgMetadataEntity;

  factory OgMetadataEntity.fromJson(Map<String, dynamic> json) =>
      _$OgMetadataEntityFromJson(json);
}

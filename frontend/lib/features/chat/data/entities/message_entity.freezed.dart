// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageEntity {

 String get id; String get conversationId; String get senderId; String? get content; String get type; String? get attachmentUrl;@JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) OgMetadataEntity? get metadata; String? get replyToId; MessageEntity? get replyTo; List<MessageReactionEntity> get reactions; DateTime? get deletedAt; DateTime? get readAt; DateTime? get deliveredAt; DateTime get createdAt;
/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageEntityCopyWith<MessageEntity> get copyWith => _$MessageEntityCopyWithImpl<MessageEntity>(this as MessageEntity, _$identity);

  /// Serializes this MessageEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,content,type,attachmentUrl,metadata,replyToId,replyTo,const DeepCollectionEquality().hash(reactions),deletedAt,readAt,deliveredAt,createdAt);

@override
String toString() {
  return 'MessageEntity(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, type: $type, attachmentUrl: $attachmentUrl, metadata: $metadata, replyToId: $replyToId, replyTo: $replyTo, reactions: $reactions, deletedAt: $deletedAt, readAt: $readAt, deliveredAt: $deliveredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MessageEntityCopyWith<$Res>  {
  factory $MessageEntityCopyWith(MessageEntity value, $Res Function(MessageEntity) _then) = _$MessageEntityCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String senderId, String? content, String type, String? attachmentUrl,@JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) OgMetadataEntity? metadata, String? replyToId, MessageEntity? replyTo, List<MessageReactionEntity> reactions, DateTime? deletedAt, DateTime? readAt, DateTime? deliveredAt, DateTime createdAt
});


$OgMetadataEntityCopyWith<$Res>? get metadata;$MessageEntityCopyWith<$Res>? get replyTo;

}
/// @nodoc
class _$MessageEntityCopyWithImpl<$Res>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._self, this._then);

  final MessageEntity _self;
  final $Res Function(MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = freezed,Object? type = null,Object? attachmentUrl = freezed,Object? metadata = freezed,Object? replyToId = freezed,Object? replyTo = freezed,Object? reactions = null,Object? deletedAt = freezed,Object? readAt = freezed,Object? deliveredAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as OgMetadataEntity?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as MessageEntity?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReactionEntity>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OgMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $OgMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageEntityCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $MessageEntityCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageEntity].
extension MessageEntityPatterns on MessageEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageEntity value)  $default,){
final _that = this;
switch (_that) {
case _MessageEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String? content,  String type,  String? attachmentUrl, @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson)  OgMetadataEntity? metadata,  String? replyToId,  MessageEntity? replyTo,  List<MessageReactionEntity> reactions,  DateTime? deletedAt,  DateTime? readAt,  DateTime? deliveredAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.type,_that.attachmentUrl,_that.metadata,_that.replyToId,_that.replyTo,_that.reactions,_that.deletedAt,_that.readAt,_that.deliveredAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String senderId,  String? content,  String type,  String? attachmentUrl, @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson)  OgMetadataEntity? metadata,  String? replyToId,  MessageEntity? replyTo,  List<MessageReactionEntity> reactions,  DateTime? deletedAt,  DateTime? readAt,  DateTime? deliveredAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MessageEntity():
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.type,_that.attachmentUrl,_that.metadata,_that.replyToId,_that.replyTo,_that.reactions,_that.deletedAt,_that.readAt,_that.deliveredAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String senderId,  String? content,  String type,  String? attachmentUrl, @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson)  OgMetadataEntity? metadata,  String? replyToId,  MessageEntity? replyTo,  List<MessageReactionEntity> reactions,  DateTime? deletedAt,  DateTime? readAt,  DateTime? deliveredAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MessageEntity() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.content,_that.type,_that.attachmentUrl,_that.metadata,_that.replyToId,_that.replyTo,_that.reactions,_that.deletedAt,_that.readAt,_that.deliveredAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageEntity extends MessageEntity {
  const _MessageEntity({required this.id, required this.conversationId, required this.senderId, this.content, this.type = 'TEXT', this.attachmentUrl, @JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) this.metadata, this.replyToId, this.replyTo, final  List<MessageReactionEntity> reactions = const [], this.deletedAt, this.readAt, this.deliveredAt, required this.createdAt}): _reactions = reactions,super._();
  factory _MessageEntity.fromJson(Map<String, dynamic> json) => _$MessageEntityFromJson(json);

@override final  String id;
@override final  String conversationId;
@override final  String senderId;
@override final  String? content;
@override@JsonKey() final  String type;
@override final  String? attachmentUrl;
@override@JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) final  OgMetadataEntity? metadata;
@override final  String? replyToId;
@override final  MessageEntity? replyTo;
 final  List<MessageReactionEntity> _reactions;
@override@JsonKey() List<MessageReactionEntity> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

@override final  DateTime? deletedAt;
@override final  DateTime? readAt;
@override final  DateTime? deliveredAt;
@override final  DateTime createdAt;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageEntityCopyWith<_MessageEntity> get copyWith => __$MessageEntityCopyWithImpl<_MessageEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,content,type,attachmentUrl,metadata,replyToId,replyTo,const DeepCollectionEquality().hash(_reactions),deletedAt,readAt,deliveredAt,createdAt);

@override
String toString() {
  return 'MessageEntity(id: $id, conversationId: $conversationId, senderId: $senderId, content: $content, type: $type, attachmentUrl: $attachmentUrl, metadata: $metadata, replyToId: $replyToId, replyTo: $replyTo, reactions: $reactions, deletedAt: $deletedAt, readAt: $readAt, deliveredAt: $deliveredAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MessageEntityCopyWith<$Res> implements $MessageEntityCopyWith<$Res> {
  factory _$MessageEntityCopyWith(_MessageEntity value, $Res Function(_MessageEntity) _then) = __$MessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String senderId, String? content, String type, String? attachmentUrl,@JsonKey(fromJson: _ogFromJson, toJson: _ogToJson) OgMetadataEntity? metadata, String? replyToId, MessageEntity? replyTo, List<MessageReactionEntity> reactions, DateTime? deletedAt, DateTime? readAt, DateTime? deliveredAt, DateTime createdAt
});


@override $OgMetadataEntityCopyWith<$Res>? get metadata;@override $MessageEntityCopyWith<$Res>? get replyTo;

}
/// @nodoc
class __$MessageEntityCopyWithImpl<$Res>
    implements _$MessageEntityCopyWith<$Res> {
  __$MessageEntityCopyWithImpl(this._self, this._then);

  final _MessageEntity _self;
  final $Res Function(_MessageEntity) _then;

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? content = freezed,Object? type = null,Object? attachmentUrl = freezed,Object? metadata = freezed,Object? replyToId = freezed,Object? replyTo = freezed,Object? reactions = null,Object? deletedAt = freezed,Object? readAt = freezed,Object? deliveredAt = freezed,Object? createdAt = null,}) {
  return _then(_MessageEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as OgMetadataEntity?,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as MessageEntity?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<MessageReactionEntity>,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OgMetadataEntityCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $OgMetadataEntityCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}/// Create a copy of MessageEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageEntityCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $MessageEntityCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}

// dart format on

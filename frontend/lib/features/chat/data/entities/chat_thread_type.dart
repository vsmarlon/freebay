import 'package:freezed_annotation/freezed_annotation.dart';

enum ChatThreadType {
  @JsonValue('ORDER')
  order,
  @JsonValue('DIRECT')
  direct,
}

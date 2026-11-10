import 'package:freezed_annotation/freezed_annotation.dart';

enum ChatThreadType {
  @JsonValue('ORDER')
  order('ORDER'),
  @JsonValue('DIRECT')
  direct('DIRECT');

  const ChatThreadType(this.wireValue);

  final String wireValue;

  static ChatThreadType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

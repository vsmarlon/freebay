import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastErrorInfo {
  final String message;
  final String? route;

  const LastErrorInfo(this.message, this.route);
}

final lastErrorProvider = StateProvider<LastErrorInfo?>((ref) => null);

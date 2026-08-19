import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastErrorInfo {
  final String message;
  final String? route;

  const LastErrorInfo(this.message, this.route);
}

class LastErrorNotifier extends Notifier<LastErrorInfo?> {
  @override
  LastErrorInfo? build() => null;

  void setError(LastErrorInfo? info) {
    state = info;
  }
}

final lastErrorProvider = NotifierProvider<LastErrorNotifier, LastErrorInfo?>(
  LastErrorNotifier.new,
);

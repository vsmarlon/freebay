import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/services/storage_service.dart';

part 'session_lock_preference_provider.g.dart';

@Riverpod(keepAlive: true)
class SessionLockPreference extends _$SessionLockPreference {
  static const choices = [0, 1, 5, 15, 30];

  @override
  int build() => StorageService.getSessionLockMinutesSync();

  Future<void> setMinutes(int minutes) async {
    if (!choices.contains(minutes)) {
      throw ArgumentError.value(minutes, 'minutes');
    }
    await StorageService.setSessionLockMinutes(minutes);
    state = minutes;
  }
}

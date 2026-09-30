import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _backgroundAnimatedKey = 'background_animated';

final backgroundAnimatedProvider =
    NotifierProvider<BackgroundAnimatedNotifier, bool>(
      BackgroundAnimatedNotifier.new,
    );

class BackgroundAnimatedNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    // ponytail: keep the aurora still by default; animation is opt-in on slower GPUs.
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final saved = prefs.getBool(_backgroundAnimatedKey);
      if (saved != null) state = saved;
    } catch (_) {
      // Keep the still default.
    }
  }

  Future<void> setAnimated(bool animated) async {
    state = animated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backgroundAnimatedKey, animated);
    } catch (_) {
      // Silently fail
    }
  }
}

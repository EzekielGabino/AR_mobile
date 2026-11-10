import 'package:shared_preferences/shared_preferences.dart';

/// First-open app guide (Profile / join / hub overview).
class AppOnboardingStore {
  static const _key = 'app_onboarding_completed_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> setCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, completed);
  }

  /// Profile: show the app guide again on next open or immediately after reset.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

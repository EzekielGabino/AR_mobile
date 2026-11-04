import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the AR lab UI onboarding should be shown again.
class LabOnboardingStore {
  static const _key = 'lab_onboarding_dismissed_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> setDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, dismissed);
  }

  /// For Profile / settings: show onboarding again next Start lab.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class PostRegistrationOnboardingStorage {
  Future<bool> shouldPresentOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }

  static const String _key = 'post_registration_onboarding_pending_v1';
}

class ReminderCompletionStorage {
  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(prefs.getStringList(_key) ?? const <String>[]);
  }

  Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList()..sort());
  }

  static const String _key = 'taken_reminder_ids_v1';
}

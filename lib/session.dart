import 'package:shared_preferences/shared_preferences.dart';

/// Simple session storage utility for persisting logged-in user id.
class SessionStore {
  static const _kUserKey = 'logged_in_user';

  /// Save the current logged-in username (or user id).
  static Future<void> saveUser(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, userName);
  }

  /// Returns stored username or null if not logged in.
  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserKey);
  }

  /// Clears stored session.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }
}


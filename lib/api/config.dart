import 'package:shared_preferences/shared_preferences.dart';

/// Stores runtime configuration for backend connectivity.
class ApiConfig {
  static const _kBaseUrlKey = 'api_base_url';
  static const _kAuthTokenKey = 'api_auth_token';

  /// Returns the configured base URL or empty string if not set.
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBaseUrlKey) ?? '';
  }

  /// Persists the base URL (set empty to disable network calls).
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.trim().isEmpty) {
      await prefs.remove(_kBaseUrlKey);
    } else {
      await prefs.setString(_kBaseUrlKey, url.trim());
    }
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthTokenKey);
  }

  static Future<void> setAuthToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_kAuthTokenKey);
    } else {
      await prefs.setString(_kAuthTokenKey, token);
    }
  }
}


import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _serverUrlKey = 'server_url';
  static const _defaultServerUrl = 'http://10.0.2.2:8000';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }
}

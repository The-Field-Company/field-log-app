import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_service.dart';

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenFreshnessMs = 30000;

  static Timer? _refreshTimer;
  static Completer<String>? _refreshCompleter;

  static Future<void> login(String username, String password) async {
    final serverUrl = await PreferencesService.getServerUrl();
    final url = Uri.parse('$serverUrl/api/token/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid username or password');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, data['access'] as String);
    await prefs.setString(_refreshTokenKey, data['refresh'] as String);

    scheduleRefresh();
  }

  static Future<void> logout() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _refreshCompleter = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) return false;
    return getTokenExp(refreshToken) > DateTime.now().millisecondsSinceEpoch;
  }

  static int getTokenExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 0;
      final payload = parts[1];
      // Add padding for base64
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return ((json['exp'] as num) * 1000).toInt();
    } catch (_) {
      return 0;
    }
  }

  static String? getUsername() {
    // Synchronous version using cached token — call after isAuthenticated
    return _getUsernameFromPrefsSync();
  }

  static String? _getUsernameFromPrefsSync() {
    // We need a sync way to get username; cache it on login/refresh
    return _cachedUsername;
  }

  static String? _cachedUsername;

  static Future<String?> getUsernameAsync() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64.normalize(parts[1]);
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      _cachedUsername = json['username'] as String?;
      return _cachedUsername;
    } catch (_) {
      return null;
    }
  }

  static Future<void> ensureFreshToken() async {
    final token = await getToken();
    if (token == null) return;

    final remaining = getTokenExp(token) - DateTime.now().millisecondsSinceEpoch;
    if (remaining < _tokenFreshnessMs) {
      await refreshAccessToken();
    }
  }

  static Future<String> refreshAccessToken() async {
    // Dedupe concurrent refresh calls
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String>();
    try {
      final result = await _doRefresh();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  static Future<String> _doRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final serverUrl = await PreferencesService.getServerUrl();
    final url = Uri.parse('$serverUrl/api/token/refresh/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Token refresh failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = data['access'] as String;
    await prefs.setString(_accessTokenKey, newAccessToken);

    // Some servers also rotate refresh tokens
    if (data.containsKey('refresh')) {
      await prefs.setString(_refreshTokenKey, data['refresh'] as String);
    }

    // Update cached username
    await getUsernameAsync();

    scheduleRefresh();
    return newAccessToken;
  }

  static void scheduleRefresh() {
    _refreshTimer?.cancel();

    // Fire-and-forget async work inside sync method
    () async {
      final token = await getToken();
      if (token == null) return;

      final delay = getTokenExp(token) - DateTime.now().millisecondsSinceEpoch - 60000;
      _refreshTimer = Timer(
        Duration(milliseconds: delay > 0 ? delay : 0),
        () => refreshAccessToken().catchError((_) => ''),
      );
    }();
  }

  /// Call on app start to restore session state
  static Future<bool> initSession() async {
    if (!await isAuthenticated()) return false;
    if (!await isSessionValid()) {
      await logout();
      return false;
    }
    await getUsernameAsync();
    scheduleRefresh();
    return true;
  }
}

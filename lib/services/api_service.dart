import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session.dart';
import 'preferences_service.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _httpTimeout = Duration(seconds: 30);

  static Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Session> getSession(String sessionId) async {
    final serverUrl = await PreferencesService.getServerUrl();
    final url = Uri.parse('$serverUrl/api/sessions/$sessionId/');

    final http.Response response;
    try {
      response = await http
          .get(url, headers: await _authHeaders())
          .timeout(_httpTimeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection and try again.');
    }

    if (response.statusCode == 404) {
      throw ApiException('Session not found. Please check the session ID and try again.', statusCode: 404);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('This session requires authentication.', statusCode: response.statusCode);
    }
    if (response.statusCode >= 500) {
      throw ApiException('The server is temporarily unavailable. Please try again later.', statusCode: response.statusCode);
    }
    if (response.statusCode != 200) {
      throw ApiException('Something went wrong. Please try again.', statusCode: response.statusCode);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Session.fromJson(json);
  }

  static Future<void> createSubmission(
    int sessionId,
    Map<String, dynamic> data, {
    String submittedBy = 'Anonymous',
  }) async {
    final serverUrl = await PreferencesService.getServerUrl();
    final url = Uri.parse('$serverUrl/api/sessions/$sessionId/submissions/');

    final http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'submitted_by': submittedBy,
              'data': data,
            }),
          )
          .timeout(_httpTimeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Check your connection and try again.');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('This session is no longer accepting public submissions.', statusCode: response.statusCode);
    }
    if (response.statusCode == 404) {
      throw ApiException('Session not found. It may have been deleted.', statusCode: 404);
    }
    if (response.statusCode >= 500) {
      throw ApiException('The server is temporarily unavailable. Please try again later.', statusCode: response.statusCode);
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException('Something went wrong. Please try again.', statusCode: response.statusCode);
    }
  }
}

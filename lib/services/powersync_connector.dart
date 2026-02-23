import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';
import 'auth_service.dart';
import 'preferences_service.dart';

/// PowerSync backend connector mirroring ui/src/services/powersync/connector.js
class FieldLogConnector extends PowerSyncBackendConnector {
  static const _httpTimeout = Duration(seconds: 30);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await AuthService.ensureFreshToken();

    final token = await AuthService.getToken();
    if (token == null) return null;

    final powerSyncUrl = await PreferencesService.getPowerSyncUrl();

    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: token,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    await AuthService.ensureFreshToken();
    final token = await AuthService.getToken();
    final serverUrl = await PreferencesService.getServerUrl();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    for (final op in transaction.crud) {
      if (op.table != 'fieldlog_submission') continue;
      if (op.op != UpdateType.put) continue;

      final record = op.opData;
      final sessionId = record?['session_id'];

      dynamic parsedData;
      try {
        parsedData = jsonDecode(record?['data'] as String? ?? '{}');
      } catch (e) {
        // H4: malformed record data — log and skip rather than silently drop.
        // The transaction will still complete so PowerSync doesn't retry forever.
        if (kDebugMode) {
          debugPrint('[PowerSync] Skipping record ${op.id} — malformed JSON data: $e');
        }
        continue;
      }

      final url = Uri.parse('$serverUrl/api/sessions/$sessionId/submissions/');
      final body = jsonEncode({
        'id': op.id,
        'submitted_by': record?['submitted_by'] ?? 'Anonymous',
        'data': parsedData,
      });

      final http.Response response;
      try {
        response = await http
            .post(url, headers: headers, body: body)
            .timeout(_httpTimeout);
      } on TimeoutException {
        // Let PowerSync retry on next sync cycle rather than blocking the queue
        throw Exception('Upload timed out for record ${op.id}. Will retry on next sync.');
      }

      // 200 = idempotent duplicate, 201 = new, 409 = conflict (also OK)
      if (!response.ok && response.statusCode != 409) {
        throw Exception('Upload failed: ${response.statusCode} ${response.body}');
      }
    }

    await transaction.complete();
  }
}

extension on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}

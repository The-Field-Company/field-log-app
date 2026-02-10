import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';
import 'auth_service.dart';
import 'preferences_service.dart';

/// PowerSync backend connector mirroring ui/src/services/powersync/connector.js
class FieldLogConnector extends PowerSyncBackendConnector {
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
      } catch (_) {
        continue;
      }

      final url = Uri.parse('$serverUrl/api/sessions/$sessionId/submissions/');
      final body = jsonEncode({
        'id': op.id,
        'submitted_by': record?['submitted_by'] ?? 'Anonymous',
        'data': parsedData,
      });

      final response = await http.post(url, headers: headers, body: body);

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

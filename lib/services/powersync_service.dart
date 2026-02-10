import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'powersync_schema.dart';
import 'powersync_connector.dart';

/// PowerSync database service mirroring ui/src/services/powersync/index.js
class PowerSyncService {
  static PowerSyncDatabase? _db;

  static Future<PowerSyncDatabase> initPowerSync() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/fieldlog.db';

    final db = PowerSyncDatabase(
      schema: schema,
      path: dbPath,
    );
    await db.initialize();
    await db.connect(connector: FieldLogConnector());

    _db = db;
    return db;
  }

  static PowerSyncDatabase? getPowerSync() {
    return _db;
  }

  static Future<void> disconnectPowerSync() async {
    if (_db != null) {
      await _db!.disconnect();
      _db = null;
    }
  }
}

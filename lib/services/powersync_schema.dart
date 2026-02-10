import 'package:powersync/powersync.dart';

/// PowerSync schema mirroring ui/src/services/powersync/schema.js
/// Table matches the Django fieldlog_submission model.
/// The `id` column is auto-created by PowerSync (UUID primary key).
const schema = Schema([
  Table('fieldlog_submission', [
    Column.integer('session_id'),
    Column.text('submitted_by'),
    Column.text('data'),
    Column.text('submitted_at'),
  ]),
]);

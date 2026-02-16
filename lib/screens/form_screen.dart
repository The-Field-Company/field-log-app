import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/powersync_service.dart';
import '../services/location_service.dart';
import '../widgets/formkit_renderer.dart';
import '../widgets/tally_renderer.dart';
import '../widgets/surveyjs_renderer.dart';
import '../widgets/sync_status_widget.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late Session _session;
  String _locationStatus = 'Acquiring location...';
  bool _locationReady = false;
  Map<String, int> _tallyCounts = {};
  bool _tallyCountsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = ModalRoute.of(context)!.settings.arguments as Session;
    if (_session.trackLocation) {
      _initLocation();
    }
    if (_session.formMode == 'tally' && !_tallyCountsLoaded) {
      _loadTallyCounts();
    }
  }

  Future<void> _loadTallyCounts() async {
    final db = PowerSyncService.getPowerSync();
    if (db == null) {
      setState(() => _tallyCountsLoaded = true);
      return;
    }

    final rows = await db.getAll(
      'SELECT data FROM fieldlog_submission WHERE session_id = ?',
      [_session.id],
    );

    final counts = <String, int>{};
    for (final row in rows) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      final key = data['tally_key'] as String?;
      if (key != null) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _tallyCounts = counts;
        _tallyCountsLoaded = true;
      });
    }
  }

  Future<void> _initLocation() async {
    final status = await LocationService.getStatus();
    if (mounted) {
      setState(() {
        _locationStatus = status;
        _locationReady = status == 'Location available';
      });
    }
  }

  void _onSyncTransition(SyncStateTransition transition) {
    if (!mounted) return;

    // In tally mode, suppress syncComplete — it fires after every single tap
    // when online, which spams the user. The pill widget still shows status.
    if (transition == SyncStateTransition.syncComplete &&
        _session.formMode == 'tally') {
      return;
    }

    late final String message;
    late final Color bgColor;

    switch (transition) {
      case SyncStateTransition.wentOffline:
        message = 'You\'re offline \u2014 data saves locally';
        bgColor = Colors.orange.shade700;
      case SyncStateTransition.backOnline:
        message = 'Back online \u2014 syncing...';
        bgColor = AppColors.accentLight;
      case SyncStateTransition.syncComplete:
        message = 'All submissions synced';
        bgColor = AppColors.accent;
    }

    // Clear previous sync toasts to prevent stacking on rapid flapping
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _submitToLocal(Map<String, dynamic> data) async {
    final db = PowerSyncService.getPowerSync();
    if (db == null) {
      throw Exception('PowerSync not initialized');
    }

    final id = const Uuid().v4();
    final username = AuthService.getUsername() ?? 'Anonymous';

    await db.execute(
      'INSERT INTO fieldlog_submission (id, session_id, submitted_by, data, submitted_at) VALUES (?, ?, ?, ?, ?)',
      [
        id,
        _session.id,
        username,
        jsonEncode(data),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> _submitFormData(Map<String, dynamic> data) async {
    // Attach location if tracking
    if (_session.trackLocation) {
      final location = await LocationService.captureLocation();
      if (location != null) {
        data['_location'] = location;
      }
    }

    try {
      await _submitToLocal(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/success',
      arguments: _session,
    );
  }

  Future<void> _submitTally(Map<String, dynamic> data) async {
    // Attach location if tracking
    if (_session.trackLocation) {
      final location = await LocationService.captureLocation();
      if (location != null) {
        data['_location'] = location;
      }
    }

    try {
      await _submitToLocal(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record tally: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Keep local counts in sync without re-querying
    final tallyKey = data['tally_key'] as String?;
    if (tallyKey != null) {
      setState(() {
        _tallyCounts = Map<String, int>.from(_tallyCounts);
        _tallyCounts[tallyKey] = (_tallyCounts[tallyKey] ?? 0) + 1;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['tally_label']} +1'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildRenderer() {
    switch (_session.formMode) {
      case 'tally':
        if (!_tallyCountsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return TallyRenderer(
          components: _session.components,
          onTap: _submitTally,
          initialCounts: _tallyCounts,
        );
      case 'surveyjs':
        if (_session.schema != null) {
          return SurveyjsRenderer(
            schema: _session.schema!,
            onSubmit: _submitFormData,
          );
        }
        return const Center(child: Text('No survey schema found'));
      case 'formkit':
      default:
        return FormkitRenderer(
          components: _session.components,
          onSubmit: _submitFormData,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SyncStatusWidget(onTransition: _onSyncTransition),
          ),
        ],
      ),
      body: Column(
        children: [
          // Form renderer
          Expanded(child: _buildRenderer()),
          // GPS status indicator
          if (_session.trackLocation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _locationReady
                    ? AppColors.accent.withValues(alpha: 0.05)
                    : Colors.orange.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _locationReady
                        ? Icons.location_on
                        : Icons.location_searching,
                    size: 16,
                    color: _locationReady ? AppColors.accent : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _locationStatus,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _locationReady
                          ? AppColors.accent
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:powersync/powersync.dart';
import '../theme/app_colors.dart';
import '../services/powersync_service.dart';

/// A compact pill widget that shows the current sync state.
/// Designed for app bars — small, unobtrusive, glanceable.
class SyncStatusWidget extends StatefulWidget {
  /// Optional callback when sync state transitions happen.
  /// Useful for parent widgets that want to show toasts.
  final void Function(SyncStateTransition transition)? onTransition;

  const SyncStatusWidget({super.key, this.onTransition});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

enum SyncStateTransition { wentOffline, backOnline, syncComplete }

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  StreamSubscription<SyncStatus>? _subscription;
  bool _connected = false;
  bool _uploading = false;
  bool? _previousConnected;

  @override
  void initState() {
    super.initState();
    _listenToStatus();
  }

  void _listenToStatus() {
    final db = PowerSyncService.getPowerSync();
    if (db == null) return;

    // Set initial state
    final current = db.currentStatus;
    _connected = current.connected;
    _uploading = current.uploading;
    _previousConnected = _connected;

    _subscription = db.statusStream.listen((status) {
      if (!mounted) return;

      final wasConnected = _previousConnected;
      final wasUploading = _uploading;

      setState(() {
        _connected = status.connected;
        _uploading = status.uploading;
      });

      // Detect transitions for toast notifications
      if (widget.onTransition != null) {
        if (wasConnected == true && !status.connected) {
          widget.onTransition!(SyncStateTransition.wentOffline);
        } else if (wasConnected == false && status.connected) {
          widget.onTransition!(SyncStateTransition.backOnline);
        } else if (wasUploading && !status.uploading && status.connected) {
          widget.onTransition!(SyncStateTransition.syncComplete);
        }
      }

      _previousConnected = status.connected;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String label;
    late final Color color;

    if (!_connected) {
      icon = Icons.cloud_off_outlined;
      label = 'Offline';
      color = Colors.orange.shade700;
    } else if (_uploading) {
      icon = Icons.cloud_upload_outlined;
      label = 'Syncing';
      color = AppColors.accentLight;
    } else {
      icon = Icons.cloud_done_outlined;
      label = 'Synced';
      color = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_uploading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone widget for the success screen that shows sync state as a subtitle line.
class SyncStatusText extends StatefulWidget {
  const SyncStatusText({super.key});

  @override
  State<SyncStatusText> createState() => _SyncStatusTextState();
}

class _SyncStatusTextState extends State<SyncStatusText> {
  StreamSubscription<SyncStatus>? _subscription;
  bool _connected = false;
  bool _uploading = false;
  // Only true once we observe uploading→done while connected on this screen.
  // Prevents the false "Uploaded to server" state on mount before PowerSync
  // has started processing the just-submitted record.
  bool _uploadConfirmed = false;

  @override
  void initState() {
    super.initState();
    final db = PowerSyncService.getPowerSync();
    if (db != null) {
      final current = db.currentStatus;
      _connected = current.connected;
      _uploading = current.uploading;

      _subscription = db.statusStream.listen((status) {
        if (!mounted) return;
        final wasUploading = _uploading;
        setState(() {
          _connected = status.connected;
          _uploading = status.uploading;
          if (wasUploading && !status.uploading && status.connected) {
            _uploadConfirmed = true;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String text;
    late final Color color;

    if (_uploadConfirmed) {
      // Terminal state: upload is done regardless of current connectivity.
      // Must be checked first — going offline after a confirmed upload does
      // not invalidate the upload.
      icon = Icons.cloud_done_outlined;
      text = 'Uploaded to server';
      color = AppColors.accent;
    } else if (!_connected) {
      icon = Icons.cloud_queue_outlined;
      text = 'Saved locally \u2014 will upload when online';
      color = Colors.orange.shade700;
    } else {
      // Covers both: actively uploading, and pending (connected but PowerSync
      // hasn't started the cycle yet). Both correctly read as "in progress".
      icon = Icons.cloud_upload_outlined;
      text = 'Uploading to server...';
      color = AppColors.accentLight;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

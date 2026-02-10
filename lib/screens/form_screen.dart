import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/session.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/formkit_renderer.dart';
import '../widgets/tally_renderer.dart';
import '../widgets/surveyjs_renderer.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late Session _session;
  bool _submitting = false;
  String _locationStatus = 'Acquiring location...';
  bool _locationReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = ModalRoute.of(context)!.settings.arguments as Session;
    if (_session.trackLocation) {
      _initLocation();
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

  Future<void> _submitFormData(Map<String, dynamic> data) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      // Attach location if tracking
      if (_session.trackLocation) {
        final location = await LocationService.captureLocation();
        if (location != null) {
          data['_location'] = location;
        }
      }

      await ApiService.createSubmission(_session.id, data);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/success',
        arguments: _session,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        _showSessionUnavailableDialog(e.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect. Check your internet connection.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitTally(Map<String, dynamic> data) async {
    try {
      // Attach location if tracking
      if (_session.trackLocation) {
        final location = await LocationService.captureLocation();
        if (location != null) {
          data['_location'] = location;
        }
      }

      await ApiService.createSubmission(_session.id, data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['tally_label']} +1'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: AppColors.accent,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        _showSessionUnavailableDialog(e.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to record tally. Check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSessionUnavailableDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Session Unavailable',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '$message\n\nPlease contact your session administrator.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildRenderer() {
    switch (_session.formMode) {
      case 'tally':
        return TallyRenderer(
          components: _session.components,
          onTap: _submitTally,
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
      ),
      body: Column(
        children: [
          // Submitting overlay
          if (_submitting)
            const LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.borderColor,
            ),
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

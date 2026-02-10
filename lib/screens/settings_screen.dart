import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await PreferencesService.getServerUrl();
    _controller.text = url;
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    // Remove trailing slash
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await PreferencesService.setServerUrl(cleanUrl);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SERVER URL',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use http://10.0.2.2:8000 for Android emulator, or your server\'s IP address.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_saved ? 'Saved!' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

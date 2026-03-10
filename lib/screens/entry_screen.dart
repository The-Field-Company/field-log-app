import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../theme/app_colors.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/powersync_service.dart';
import '../widgets/sync_status_widget.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _username;
  Session? _cachedSession;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadCachedSession();
  }

  Future<void> _loadUsername() async {
    final username = await AuthService.getUsernameAsync();
    if (mounted) setState(() => _username = username);
  }

  Future<void> _loadCachedSession() async {
    final session = await PreferencesService.getCachedSession();
    if (mounted) setState(() => _cachedSession = session);
  }

  Future<void> _loadForm() async {
    final id = _controller.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Please enter a Session ID');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await ApiService.getSession(id);
      await PreferencesService.cacheSession(session);
      if (!mounted) return;
      Navigator.pushNamed(context, '/form', arguments: session);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      setState(() => _error = 'Network error. Check your connection and server URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await PowerSyncService.disconnectPowerSync();
    await AuthService.logout();
    await PreferencesService.clearCachedSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with username, settings, logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  if (_username != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _username!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const SyncStatusWidget(),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined,
                        color: AppColors.textTertiary),
                    onPressed: _logout,
                    tooltip: 'Sign out',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 120,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scientific Field Data Collection',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Continue previous session
                    if (_cachedSession != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/form',
                                arguments: _cachedSession,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Continue: ${_cachedSession!.name}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Session ID input
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _loadForm(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Session ID',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Error message
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Load Form button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _loadForm,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Load Form'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

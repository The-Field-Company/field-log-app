import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

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
      if (!mounted) return;
      Navigator.pushNamed(context, '/form', arguments: session);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Network error. Check your connection and server URL.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            // Top bar with settings
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.textTertiary),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
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

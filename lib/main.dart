import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/form_screen.dart';
import 'screens/success_screen.dart';
import 'services/auth_service.dart';
import 'services/powersync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore session: check if user is still authenticated
  String initialRoute = '/login';
  final sessionValid = await AuthService.initSession();
  if (sessionValid) {
    initialRoute = '/';
    try {
      await PowerSyncService.initPowerSync();
    } catch (e) {
      debugPrint('[PowerSync] init failed on startup: $e');
    }
  }

  runApp(FieldLogApp(initialRoute: initialRoute));
}

class FieldLogApp extends StatelessWidget {
  final String initialRoute;

  const FieldLogApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldLog',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const EntryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/form': (context) => const FormScreen(),
        '/success': (context) => const SuccessScreen(),
      },
    );
  }
}

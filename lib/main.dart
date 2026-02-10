import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/entry_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/form_screen.dart';
import 'screens/success_screen.dart';

void main() {
  runApp(const FieldLogApp());
}

class FieldLogApp extends StatelessWidget {
  const FieldLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldLog',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const EntryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/form': (context) => const FormScreen(),
        '/success': (context) => const SuccessScreen(),
      },
    );
  }
}

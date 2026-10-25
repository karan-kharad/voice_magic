import 'package:flutter/material.dart';
import 'src/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhatsAppVoiceChangerApp());
}

class WhatsAppVoiceChangerApp extends StatelessWidget {
  const WhatsAppVoiceChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Voice Changer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1218),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF25D366),
          secondary: Color(0xFF00B4D8),
          surface: Color(0xFF191D26),
          error: Color(0xFFEF476F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1218),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

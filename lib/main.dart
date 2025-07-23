import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Global theme notifier
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://emttwzssiuztjcjapurw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtdHR3enNzaXV6dGpjamFwdXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4NTc5NTIsImV4cCI6MjA2ODQzMzk1Mn0.CbmV5UdjhVSS_KUGHBJWIV-TWDs-jOTl5VG3vl5ZZRY',
  );

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'RapidWarn',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F7FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFECEFF1),
              foregroundColor: Colors.black,
              elevation: 2,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF5D9CEC),
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            cardColor: Colors.white,
            shadowColor: Colors.grey,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.black54),
            ),
            fontFamily: 'Roboto',
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF80CBC4),
              foregroundColor: Colors.black,
            ),
            cardColor: Colors.grey.shade900,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.white70),
            ),
            fontFamily: 'Roboto',
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // When animation completes → go next
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goNext();
      }
    });

    // Safety fallback (6s max wait)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_controller.isCompleted) {
        _goNext();
      }
    });
  }

  void _goNext() async {
    try {
      // Check for persistent admin session first
      final prefs = await SharedPreferences.getInstance();
      final isAdminLoggedIn = prefs.getBool('admin_logged_in') ?? false;
      final adminPhone = prefs.getString('admin_phone') ?? '';

      if (isAdminLoggedIn && adminPhone == '9324476116') {
        print('🔄 Restoring admin session for $adminPhone');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      // Check for regular user Firebase Auth session
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔄 Restoring user session for ${user.email}');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      // No session found - go to onboarding
      print('🔄 No session found - showing onboarding');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } catch (e) {
      print('❌ Error checking authentication state: $e');
      // Fallback to onboarding on error
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
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
      backgroundColor: Colors.black,
      body: Center(
        child: Lottie.asset(
          'assets/animation/login_animation.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

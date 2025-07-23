import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ ADD THIS!

import 'login_screen.dart';
import 'signup_screen.dart';

class PurposeScreen extends StatelessWidget {
  const PurposeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Animated background
          Positioned.fill(
            child: Lottie.asset(
              'assets/animation/fog_smoke.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),

          // ✅ Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  SizedBox(
                    height: 100,
                    child: Lottie.asset(
                      'assets/animation/onboard2.json',
                      repeat: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Stay Alert. Stay Safe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "RapidWarn connects communities in real-time to keep you safe & informed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),

                  const Spacer(),

                  /// ✅ Slide to Login WITH sound
                  SlideAction(
                    text: 'SLIDE TO LOGIN',
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    outerColor: Colors.tealAccent,
                    innerColor: Colors.black,
                    elevation: 6,
                    sliderButtonIcon:
                        const Icon(Icons.login, color: Colors.white),
                    onSubmit: () async {
                      final player = AudioPlayer();
                      await player.play(AssetSource('sounds/success.mp3'));

                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  /// ✅ Slide to Sign Up WITH sound
                  SlideAction(
                    text: 'SLIDE TO SIGN UP',
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    outerColor: Colors.white,
                    innerColor: Colors.tealAccent,
                    elevation: 6,
                    sliderButtonIcon:
                        const Icon(Icons.person_add, color: Colors.black),
                    onSubmit: () async {
                      final player = AudioPlayer();
                      await player.play(AssetSource('sounds/success.mp3'));

                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Together, we warn. Together, we stay safe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

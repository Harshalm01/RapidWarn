import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:background_bubbles/background_bubbles.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart'; // For Haptic

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _errorMessage;

  // ✅ Confetti + Audio
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = "All fields are required.");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = "Password must be at least 6 characters.");
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // ✅ Show Confetti, Play Sound, Vibrate
      _confettiController.play();
      _audioPlayer
          .play(AssetSource('success.mp3')); // Make sure to add an audio file!
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop(); // Back to Login
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Password is too weak.';
      } else {
        _errorMessage = e.message;
      }
      setState(() {});
    } catch (_) {
      setState(() => _errorMessage = "Unexpected error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(color: const Color(0xFF121212)),

        // ✅ Bubble background
        Positioned.fill(
          child: BubblesAnimation(
            backgroundColor: Colors.transparent,
            particleColor: Colors.tealAccent.withOpacity(0.3),
            particleCount: 80,
            particleRadius: 4,
          ),
        ),

        // ✅ Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 50,
            colors: const [Colors.tealAccent, Colors.white, Colors.blueAccent],
          ),
        ),

        // ✅ Signup Form
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF80CBC4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInput(_emailController, "Email", Icons.email),
                  const SizedBox(height: 16),
                  _buildInput(_passwordController, "Password", Icons.lock,
                      obscure: true),
                  const SizedBox(height: 16),
                  _buildInput(_confirmPasswordController, "Confirm Password",
                      Icons.lock_outline,
                      obscure: true),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Log In",
                      style: TextStyle(
                        color: Color(0xFF80CBC4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInput(
      TextEditingController controller, String hint, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.grey[850],
        prefixIcon: Icon(icon, color: Colors.tealAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

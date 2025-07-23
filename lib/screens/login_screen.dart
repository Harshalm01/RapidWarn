import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:background_bubbles/background_bubbles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rapidwarn/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _fadeController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailPassword() async {
    setState(() => _errorMessage = null);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "An unexpected error occurred.");
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _errorMessage = null);
    try {
      if (kIsWeb) {
        // ✅ Web: Use signInWithPopup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        // ✅ Mobile: Use google_sign_in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _errorMessage = "Google Sign‑In cancelled.");
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(
          () => _errorMessage = e.message ?? "Firebase Auth error occurred.");
    } catch (e) {
      setState(() => _errorMessage =
          "An unexpected error occurred during Google Sign‑In.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    return Scaffold(
      body: Stack(children: [
        Container(color: const Color(0xFF121212)),
        Positioned.fill(
          child: BubblesAnimation(
            backgroundColor: Colors.transparent,
            particleColor: Colors.tealAccent.withOpacity(0.3),
            particleCount: 80,
            particleRadius: 4,
            widget: const SizedBox.shrink(),
          ),
        ),
        FadeTransition(
          opacity: fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/images/icon.jpg', height: 72),
                  const SizedBox(height: 12),
                  const Text(
                    'RapidWarn',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF80CBC4),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildInputField(
                      controller: _emailController,
                      icon: Icons.email,
                      hint: "Email"),
                  const SizedBox(height: 16),
                  _buildInputField(
                      controller: _passwordController,
                      icon: Icons.lock,
                      hint: "Password",
                      obscure: true),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _signInWithEmailPassword,
                    style: _buttonStyle(),
                    child: const Text("Login with Email"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset('assets/google_logo.png', height: 24),
                    label: const Text("Sign in with Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(_errorMessage!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen())),
                    child: const Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(
                        color: Color(0xFF80CBC4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
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

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF80CBC4),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: const Size.fromHeight(50),
    );
  }
}

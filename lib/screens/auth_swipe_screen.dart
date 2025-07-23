import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:background_bubbles/background_bubbles.dart';

import 'home_screen.dart';

class AuthSwipeScreen extends StatefulWidget {
  const AuthSwipeScreen({super.key});

  @override
  State<AuthSwipeScreen> createState() => _AuthSwipeScreenState();
}

class _AuthSwipeScreenState extends State<AuthSwipeScreen> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();

  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmail.text.trim(),
        password: _loginPass.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Login failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signupEmail.text.trim(),
        password: _signupPass.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Signup failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          BubblesAnimation(
            backgroundColor: const Color(0xFF121212),
            particleColor: Colors.tealAccent.withOpacity(0.3),
            particleCount: 80,
            particleRadius: 4,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  'RapidWarn',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay alert. Stay connected.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    children: [
                      _buildLoginCard(),
                      _buildSignupCard(),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.tealAccent),
                      onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: Colors.tealAccent),
                      onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent)),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Center(
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Login',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _loginEmail,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _loginPass,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupCard() {
    return Center(
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _signupEmail,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _signupPass,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

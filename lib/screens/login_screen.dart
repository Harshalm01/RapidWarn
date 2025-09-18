import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/email_service.dart';
import 'dart:math';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Email OTP login state
  String? _emailOtpErrorMessage;
  bool _isEmailOtpLoading = false;
  String? _sentOtp;

  Future<void> _loginWithEmailOtp(BuildContext context) async {
    String email = '';
    String enteredOtp = '';
    _emailOtpErrorMessage = null;
    _sentOtp = null;
    _isEmailOtpLoading = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email Verification',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    _sentOtp == null
                        ? 'Enter your email to receive a One-Time Password (OTP).'
                        : 'Enter the 6-digit OTP sent to $email',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sentOtp == null)
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'example@email.com',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (val) => email = val.trim(),
                        enabled: _sentOtp == null,
                      ),
                    if (_sentOtp != null) ...[
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        onChanged: (val) => enteredOtp = val,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 48,
                          fieldWidth: 40,
                          activeColor: Colors.green,
                          selectedColor: Colors.blue,
                          inactiveColor: Colors.grey[300]!,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Text('Didn\'t receive the code? Check your spam folder.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                    if (_emailOtpErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_emailOtpErrorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ]
                  ],
                ),
              ),
              actions: [
                if (_sentOtp == null)
                  TextButton(
                    onPressed: _isEmailOtpLoading
                        ? null
                        : () async {
                            // Validate email first
                            if (email.isEmpty ||
                                !email.contains('@') ||
                                !email.contains('.')) {
                              setState(() {
                                _emailOtpErrorMessage =
                                    'Please enter a valid email address.';
                              });
                              return;
                            }

                            setState(() => _isEmailOtpLoading = true);
                            // Generate 6-digit OTP
                            final otp =
                                (Random().nextInt(900000) + 100000).toString();
                            final now = DateTime.now();
                            final time =
                                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                            final sent = await EmailService.sendOtpEmail(
                              toEmail: email,
                              otp: otp,
                              time: time,
                            );
                            if (sent) {
                              setState(() {
                                _sentOtp = otp;
                                _isEmailOtpLoading = false;
                                _emailOtpErrorMessage = null;
                              });
                            } else {
                              setState(() {
                                _emailOtpErrorMessage =
                                    'Failed to send OTP. Please try again.';
                                _isEmailOtpLoading = false;
                              });
                            }
                          },
                    child: _isEmailOtpLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send OTP'),
                  ),
                if (_sentOtp != null)
                  TextButton(
                    onPressed: _isEmailOtpLoading
                        ? null
                        : () async {
                            setState(() => _isEmailOtpLoading = true);
                            if (enteredOtp == _sentOtp) {
                              // After OTP verification, sign in or create Firebase user
                              final fb_auth.FirebaseAuth _auth =
                                  fb_auth.FirebaseAuth.instance;
                              // Create a secure random password for this session
                              final randomPassword =
                                  'RapidWarnOtp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

                              try {
                                // Try to create user first (most common case for OTP login)
                                await _auth.createUserWithEmailAndPassword(
                                    email: email, password: randomPassword);
                              } on fb_auth.FirebaseAuthException catch (e) {
                                if (e.code == 'email-already-in-use') {
                                  // User exists, try to sign them in with custom token or handle differently
                                  // For OTP-based login, we'll create a custom solution
                                  try {
                                    // Since user exists, we'll delete and recreate (not recommended for production)
                                    // Better solution: Use Firebase custom tokens or phone auth
                                    await _auth.createUserWithEmailAndPassword(
                                        email: email, password: randomPassword);
                                  } catch (e2) {
                                    setState(() {
                                      _emailOtpErrorMessage =
                                          'Email already registered. Please use a different login method.';
                                      _isEmailOtpLoading = false;
                                    });
                                    return;
                                  }
                                } else {
                                  setState(() {
                                    _emailOtpErrorMessage =
                                        e.message ?? 'Login failed.';
                                    _isEmailOtpLoading = false;
                                  });
                                  return;
                                }
                              } catch (e) {
                                setState(() {
                                  _emailOtpErrorMessage =
                                      'Login failed: ${e.toString()}';
                                  _isEmailOtpLoading = false;
                                });
                                return;
                              }
                              Navigator.of(ctx).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                              );
                            } else {
                              setState(() {
                                _emailOtpErrorMessage = 'Invalid OTP.';
                                _isEmailOtpLoading = false;
                              });
                            }
                          },
                    child: _isEmailOtpLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify OTP'),
                  ),
                TextButton(
                  onPressed: () {
                    _sentOtp = null;
                    _emailOtpErrorMessage = null;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {
      _sentOtp = null;
      _emailOtpErrorMessage = null;
      _isEmailOtpLoading = false;
    });
  }

  // Register tab controllers and error state
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  final TextEditingController _signupConfirmPasswordController =
      TextEditingController();
  String? _signupErrorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final supabase = Supabase.instance.client;

  String? _errorMessage;
  bool _rememberMe = false;
  int _tabIndex = 0; // 0: Login, 1: Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  /// 🔄 Sync user from Firebase → Supabase
  Future<void> _syncUserToSupabase(fb_auth.User user) async {
    try {
      await supabase.from('users').upsert({
        'firebase_uid': user.uid,
        'email': user.email,
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'firebase_uid');
    } catch (e) {
      debugPrint("❌ Failed to sync user to Supabase: $e");
    }
  }

  Future<void> _signInWithEmailPassword() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null) {
        await _syncUserToSupabase(cred.user!);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = "An unexpected error occurred.");
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);

    try {
      fb_auth.UserCredential cred;

      if (kIsWeb) {
        fb_auth.GoogleAuthProvider googleProvider =
            fb_auth.GoogleAuthProvider();
        cred = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final fb_auth.AuthCredential credential =
            fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        cred = await _auth.signInWithCredential(credential);
      }

      if (cred.user != null) {
        await _syncUserToSupabase(cred.user!);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = "Google Sign-In failed.");
    }
  }

  Future<void> _signUp() async {
    setState(() => _signupErrorMessage = null);
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text.trim();
    final confirmPassword = _signupConfirmPasswordController.text.trim();
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _signupErrorMessage = "All fields are required.");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _signupErrorMessage = "Passwords do not match.");
      return;
    }
    if (password.length < 6) {
      setState(() =>
          _signupErrorMessage = "Password must be at least 6 characters.");
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (!mounted) return;
      setState(() {
        _tabIndex = 0;
        _signupEmailController.clear();
        _signupPasswordController.clear();
        _signupConfirmPasswordController.clear();
      });
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _signupErrorMessage = 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        _signupErrorMessage = 'Password is too weak.';
      } else {
        _signupErrorMessage = e.message;
      }
      setState(() {});
    } catch (_) {
      setState(() => _signupErrorMessage = "Unexpected error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Heading
              const Text(
                'Go ahead and set up\nyour account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in-up',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tab Bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tabIndex = 0),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _tabIndex == 0
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: _tabIndex == 0
                                        ? Colors.black
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tabIndex = 1),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _tabIndex == 1
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    color: _tabIndex == 1
                                        ? Colors.black
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_tabIndex == 0) ...[
                      // ...existing code for Login tab...
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.black45),
                          suffixIcon: const Icon(Icons.visibility_outlined,
                              color: Colors.black38),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? false),
                            activeColor: const Color(0xFF7CA183),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          const Text('Remember me',
                              style: TextStyle(color: Colors.black87)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    color: Color(0xFF7CA183),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _signInWithEmailPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7CA183),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_errorMessage!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Or login with',
                                style: TextStyle(color: Colors.black54)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: Image.asset('assets/google_logo.png',
                                  height: 22),
                              label: const Text('Google',
                                  style: TextStyle(color: Colors.black)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _loginWithEmailOtp(context),
                              icon: const Icon(Icons.email,
                                  color: Color(0xFF388E3C)),
                              label: const Text('Email OTP',
                                  style: TextStyle(color: Colors.black)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                backgroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Register tab UI (match Login tab style)
                      TextField(
                        controller: _signupEmailController,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _signupPasswordController,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _signupConfirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.black45),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7CA183),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                      if (_signupErrorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(_signupErrorMessage!,
                            style: const TextStyle(color: Colors.redAccent)),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: const Color(0xFF00FFD0),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        prefixIcon: Icon(icon, color: Color(0xFF00FFD0)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF00FFD0), width: 2),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00FFD0),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      minimumSize: const Size.fromHeight(50),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.2),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}

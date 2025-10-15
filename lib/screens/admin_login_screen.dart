// lib/screens/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showOtpField = false;

  // Predefined admin data
  final Map<String, Map<String, dynamic>> _adminPhones = {
    '+1234567890': {
      'name': 'Super Admin',
      'role': 'super_admin',
      'predefinedOTP': '123456',
      'isActive': true,
    },
    '+9876543210': {
      'name': 'Emergency Admin',
      'role': 'emergency_admin',
      'predefinedOTP': '654321',
      'isActive': true,
    },
    '+919324476116': {
      'name': 'Test Admin',
      'role': 'test_admin',
      'predefinedOTP': '011107',
      'isActive': true,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Admin Login Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A085), Color(0xFF2ECC71)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Admin Access',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'RapidWarn Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Phone Number Input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Admin phone number',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2ECC71)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1B2028),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }

                      // Apply the same strict validation as in _handleLogin
                      String phoneInput =
                          value.replaceAll(' ', '').replaceAll('-', '');
                      String? matchedPhone;

                      // Check if input matches any predefined admin number
                      for (String adminPhone in _adminPhones.keys) {
                        // Remove country codes to get base number
                        String baseAdminNumber = adminPhone
                            .replaceAll('+91', '')
                            .replaceAll('+1', '')
                            .replaceAll('+', '');

                        // Check multiple input formats for this admin number
                        if (phoneInput ==
                                adminPhone || // Full format: +91932476116
                            phoneInput ==
                                adminPhone.replaceAll(
                                    '+', '') || // Without +: 91932476116
                            phoneInput == baseAdminNumber) {
                          // Base number: 932476116
                          matchedPhone = adminPhone;
                          break;
                        }
                      }

                      if (matchedPhone == null) {
                        return 'Unauthorized phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // OTP Input (shown after phone verification)
                  if (_showOtpField)
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF2ECC71)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1B2028),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter OTP';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _showOtpField ? 'Verify OTP' : 'Send OTP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back to User Login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to User Login',
                      style: TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String phoneInput =
          _phoneController.text.replaceAll(' ', '').replaceAll('-', '');
      String? fullPhone;

      // Strict validation - only allow predefined admin numbers
      // Check if input matches any predefined admin number (with flexible formatting)

      for (String adminPhone in _adminPhones.keys) {
        // Remove +91, +1, etc. to get base number
        String baseAdminNumber = adminPhone
            .replaceAll('+91', '')
            .replaceAll('+1', '')
            .replaceAll('+', '');

        // Check multiple input formats for this admin number
        if (phoneInput == adminPhone || // Full format: +91932476116
            phoneInput ==
                adminPhone.replaceAll('+', '') || // Without +: 91932476116
            phoneInput == baseAdminNumber) {
          // Base number: 932476116
          fullPhone = adminPhone; // Use the exact predefined format
          break;
        }
      }

      // If no match found, reject immediately
      if (fullPhone == null) {
        _showSnackBar(
            'Unauthorized phone number. Only predefined admin numbers allowed.',
            Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      if (!_showOtpField) {
        // Step 1: Verify phone number exists in admin list
        if (_adminPhones.containsKey(fullPhone)) {
          setState(() {
            _showOtpField = true;
            _isLoading = false;
          });
          _showSnackBar('OTP sent! Use the predefined OTP.', Colors.green);
        } else {
          _showSnackBar('Unauthorized phone number', Colors.red);
          setState(() => _isLoading = false);
        }
      } else {
        // Step 2: Verify OTP
        final adminData = _adminPhones[fullPhone]!;
        if (_otpController.text == adminData['predefinedOTP']) {
          // Store admin session
          await _storeAdminSession(fullPhone, adminData);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
              ),
            );
          }
        } else {
          _showSnackBar('Invalid OTP', Colors.red);
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      _showSnackBar('Login failed: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _storeAdminSession(
      String phone, Map<String, dynamic> adminData) async {
    try {
      // Store in SharedPreferences for persistent login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      await prefs.setString('admin_phone', phone);
      await prefs.setString('admin_name', adminData['name']);
      await prefs.setString('admin_role', adminData['role']);
      await prefs.setInt(
          'admin_login_time', DateTime.now().millisecondsSinceEpoch);

      print('✅ Admin session saved to SharedPreferences: $phone');

      // Store in Firestore for session management
      await FirebaseFirestore.instance
          .collection('admin_sessions')
          .doc(phone)
          .set({
        'phone': phone,
        'name': adminData['name'],
        'role': adminData['role'],
        'loginTime': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Admin session saved to Firestore: $phone');
    } catch (e) {
      print('❌ Failed to store admin session: $e');
    }
  }

  // Static method to clear admin session (can be called from anywhere)
  static Future<void> clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_logged_in');
      await prefs.remove('admin_phone');
      await prefs.remove('admin_name');
      await prefs.remove('admin_role');
      await prefs.remove('admin_login_time');

      print('✅ Admin session cleared from SharedPreferences');
    } catch (e) {
      print('❌ Failed to clear admin session: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

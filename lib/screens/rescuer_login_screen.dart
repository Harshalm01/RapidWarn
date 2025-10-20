import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rescuer_dashboard_screen.dart';

class RescuerLoginScreen extends StatefulWidget {
  const RescuerLoginScreen({Key? key}) : super(key: key);

  @override
  State<RescuerLoginScreen> createState() => _RescuerLoginScreenState();
}

class _RescuerLoginScreenState extends State<RescuerLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showOtpField = false;

  // Predefined rescuer data
  final Map<String, Map<String, dynamic>> _rescuerPhones = {
    '+1234567891': {
      'name': 'Rescue Team Alpha',
      'email': 'alpha@rescueteam.com',
      'role': 'team_leader',
      'predefinedOTP': '111111',
      'isActive': true,
    },
    '+9876543211': {
      'name': 'Rescue Team Beta',
      'email': 'beta@rescueteam.com',
      'role': 'rescuer',
      'predefinedOTP': '222222',
      'isActive': true,
    },
    '+919324476117': {
      'name': 'Test Rescuer',
      'email': 'test@rescueteam.com',
      'role': 'rescuer',
      'predefinedOTP': '999999',
      'isActive': true,
    },
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String phoneInput =
          _phoneController.text.replaceAll(' ', '').replaceAll('-', '');
      String? fullPhone;

      // Check if input matches any predefined rescuer number
      for (String rescuerPhone in _rescuerPhones.keys) {
        // Remove +91, +1, etc. to get base number
        String baseRescuerNumber = rescuerPhone
            .replaceAll('+91', '')
            .replaceAll('+1', '')
            .replaceAll('+', '');

        // Check multiple input formats for this rescuer number
        if (phoneInput == rescuerPhone || // Full format: +919324476117
            phoneInput ==
                rescuerPhone.replaceAll('+', '') || // Without +: 919324476117
            phoneInput == baseRescuerNumber) {
          // Base number: 9324476117
          fullPhone = rescuerPhone; // Use the exact predefined format
          break;
        }
      }

      // If no match found, reject immediately
      if (fullPhone == null) {
        _showSnackBar(
            'Unauthorized phone number. Only registered rescue team members allowed.',
            Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      if (!_showOtpField) {
        // Step 1: Verify phone number exists in rescuer list
        if (_rescuerPhones.containsKey(fullPhone)) {
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
        final rescuerData = _rescuerPhones[fullPhone]!;
        if (_otpController.text == rescuerData['predefinedOTP']) {
          // Store rescuer session
          await _storeRescuerSession(fullPhone, rescuerData);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RescuerDashboardScreen(
                  rescuerEmail: rescuerData['email'],
                ),
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

  Future<void> _storeRescuerSession(
      String phone, Map<String, dynamic> rescuerData) async {
    try {
      // Store in SharedPreferences for persistent login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rescuer_logged_in', true);
      await prefs.setString('rescuer_phone', phone);
      await prefs.setString('rescuer_name', rescuerData['name']);
      await prefs.setString('rescuer_email', rescuerData['email']);
      await prefs.setString('rescuer_role', rescuerData['role']);
      await prefs.setInt(
          'rescuer_login_time', DateTime.now().millisecondsSinceEpoch);

      print('✅ Rescuer session saved to SharedPreferences: $phone');

      // Store in Firestore for session management
      await FirebaseFirestore.instance
          .collection('rescuer_sessions')
          .doc(phone)
          .set({
        'phone': phone,
        'name': rescuerData['name'],
        'email': rescuerData['email'],
        'role': rescuerData['role'],
        'loginTime': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      print('✅ Rescuer session saved to Firestore: $phone');
    } catch (e) {
      print('❌ Failed to store rescuer session: $e');
    }
  }

  // Static method to clear rescuer session (can be called from anywhere)
  static Future<void> clearRescuerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rescuer_logged_in');
      await prefs.remove('rescuer_phone');
      await prefs.remove('rescuer_name');
      await prefs.remove('rescuer_email');
      await prefs.remove('rescuer_role');
      await prefs.remove('rescuer_login_time');

      print('✅ Rescuer session cleared from SharedPreferences');
    } catch (e) {
      print('❌ Failed to clear rescuer session: $e');
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
                  const SizedBox(height: 40),

                  // Rescuer Login Header
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
                          Icons.health_and_safety,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Rescuer Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Emergency Response Team Access',
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
                      hintText: 'Rescuer phone number',
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
                        borderSide: const BorderSide(color: Color(0xFF16A085)),
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

                      // Check if input matches any predefined rescuer number
                      for (String rescuerPhone in _rescuerPhones.keys) {
                        // Remove country codes to get base number
                        String baseRescuerNumber = rescuerPhone
                            .replaceAll('+91', '')
                            .replaceAll('+1', '')
                            .replaceAll('+', '');

                        // Check multiple input formats for this rescuer number
                        if (phoneInput ==
                                rescuerPhone || // Full format: +919324476117
                            phoneInput ==
                                rescuerPhone.replaceAll(
                                    '+', '') || // Without +: 919324476117
                            phoneInput == baseRescuerNumber) {
                          // Base number: 9324476117
                          matchedPhone = rescuerPhone;
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
                              const BorderSide(color: Color(0xFF16A085)),
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
                        backgroundColor: const Color(0xFF16A085),
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
                        color: Color(0xFF16A085),
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
}

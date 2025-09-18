import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static const String serviceId =
      'harshalservice'; // Replace with your EmailJS Service ID
  static const String templateId =
      'harshaltemplate'; // Replace with your EmailJS Template ID
  static const String userId =
      'Iz61o0lghavi21GgJ'; // Replace with your EmailJS Public Key

  /// Sends an OTP email using EmailJS
  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String otp,
    required String time,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'email': toEmail, // must match {{email}} in EmailJS template
          'passcode': otp,
          'time': time,
        },
      }),
    );
    print('EmailJS response status: \\n${response.statusCode}');
    print('EmailJS response body: \\n${response.body}');
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}

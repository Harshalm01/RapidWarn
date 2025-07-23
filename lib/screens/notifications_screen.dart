// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: const Center(
        child: Text(
          '🔔 Real-time notifications coming soon!\nConnect FCM + Supabase Edge Function.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

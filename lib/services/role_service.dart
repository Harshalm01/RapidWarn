// lib/services/role_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  RoleService._();
  static final supabase = Supabase.instance.client;

  /// Ensure the logged-in Firebase user has a row in `users`.
  static Future<void> ensureUserRow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await supabase.from('users').upsert({
      'id': user.uid, // Firebase UID
      'firebase_uid': user.uid,
      'email': user.email,
      'role': 'user', // default role
    }, onConflict: 'id');
  }

  /// Returns true if the logged-in user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final res = await supabase
        .from('users')
        .select('role')
        .eq('id', user.uid)
        .maybeSingle();

    if (res == null) return false;
    return (res['role'] as String?) == 'admin';
  }
}

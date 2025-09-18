import 'package:flutter/material.dart';
import '../services/role_service.dart';

class AdminGate extends StatefulWidget {
  final Widget child;
  final Widget? fallback;

  const AdminGate({super.key, required this.child, this.fallback});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ok = await RoleService.isCurrentUserAdmin();
    if (mounted) setState(() => _isAdmin = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isAdmin!) return widget.child;
    return widget.fallback ?? const Center(child: Text('🚫 Admins only'));
  }
}

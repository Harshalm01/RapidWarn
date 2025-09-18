import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const UserManagementPage(),
    const ContentModerationPage(),
    const ReportsPage(),
    const NotificationsPage(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.teal,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Content"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Notifications"),
        ],
      ),
    );
  }
}

//
// ---------------- Users Page ----------------
//
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> _setRole(String userId, String role) async {
    try {
      await usersRef.doc(userId).update({'role': role});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Role updated to '$role'")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update role: $e")),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete user"),
        content: const Text(
            "This will remove the user from Firestore (does NOT delete Firebase Auth account). Continue?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete")),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await usersRef.doc(userId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User deleted")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: usersRef.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final users = snapshot.data?.docs ?? [];
        if (users.isEmpty) {
          return const Center(child: Text("🚫 No users found."));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i].data() as Map<String, dynamic>;
            final id = users[i].id;
            final email = u['email'] ?? 'unknown';
            final role = u['role'] ?? 'user';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                    child:
                        Text(email.isNotEmpty ? email[0].toUpperCase() : '?')),
                title: Text(email),
                subtitle: Text("role: $role\nuid: $id"),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'promote') await _setRole(id, 'admin');
                    if (value == 'demote') await _setRole(id, 'user');
                    if (value == 'ban') await _setRole(id, 'banned');
                    if (value == 'unban') await _setRole(id, 'user');
                    if (value == 'delete') await _deleteUser(id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'promote', child: Text('Promote → admin')),
                    const PopupMenuItem(
                        value: 'demote', child: Text('Demote → user')),
                    const PopupMenuItem(value: 'ban', child: Text('Ban user')),
                    const PopupMenuItem(
                        value: 'unban', child: Text('Unban user')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete user',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//
// ---------------- Content Moderation Page ----------------
//
class ContentModerationPage extends StatelessWidget {
  const ContentModerationPage({super.key});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "Unknown time";
    final dt = ts.toDate();
    return DateFormat("MMM d, y • h:mm a").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final postsRef = FirebaseFirestore.instance.collection('media_items');

    return StreamBuilder<QuerySnapshot>(
      stream: postsRef.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final data = snapshot.data?.docs ?? [];
        if (data.isEmpty) {
          return const Center(child: Text("🚫 No posts yet."));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) {
            final item = data[i].data() as Map<String, dynamic>;
            final id = data[i].id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item['url'] ?? "",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, _, __) =>
                        const Icon(Icons.broken_image, size: 40),
                  ),
                ),
                title: Text(item['category'] ?? "Unknown Category",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "👤 By: ${item['uploaded_by'] ?? "anonymous"}\n🕒 ${_formatDate(item['created_at'])}",
                    style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await postsRef.doc(id).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Post deleted")));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

//
// ---------------- Reports Page ----------------
//
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _totalUploads = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final adminsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      final uploadsSnap =
          await FirebaseFirestore.instance.collection('media_items').get();

      setState(() {
        _totalUsers = usersSnap.docs.length;
        _totalAdmins = adminsSnap.docs.length;
        _totalUploads = uploadsSnap.docs.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to fetch counts: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
            child: ListTile(
                title: const Text('Total users'),
                trailing: Text('$_totalUsers'))),
        Card(
            child: ListTile(
                title: const Text('Total admins'),
                trailing: Text('$_totalAdmins'))),
        Card(
            child: ListTile(
                title: const Text('Total uploads'),
                trailing: Text('$_totalUploads'))),
      ],
    );
  }
}

//
// ---------------- Notifications Page ----------------
//
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _titleCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  bool _sending = false;

  Future<void> _sendNotification() async {
    if (_titleCtl.text.trim().isEmpty || _bodyCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill title & body')));
      return;
    }

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleCtl.text.trim(),
        'body': _bodyCtl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _titleCtl.clear();
      _bodyCtl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Notification saved (server must send it)')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Failed to enqueue: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(
              controller: _bodyCtl,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: _sending ? null : _sendNotification,
              child: _sending
                  ? const CircularProgressIndicator()
                  : const Text('Enqueue Notification')),
          const SizedBox(height: 24),
          const Text(
              '⚠️ Note: To actually deliver push notifications to devices you must run a Cloud Function or server-side script that reads Firestore "notifications" and sends via FCM.'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticateAdmin();
  }

  Future<void> _authenticateAdmin() async {
    try {
      // Sign in anonymously to get Firebase Auth token for Firestore access
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('✅ Admin authenticated with Firebase Auth (anonymous)');
      }
      setState(() {
        _isAuthenticated = true;
      });
    } catch (e) {
      print('❌ Firebase Auth failed: $e');
      // Continue without auth - will show sample data
      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  final List<Widget> _pages = [
    const UserManagementPage(),
    const ContentModerationPage(),
    const AnalyticsScreen(), // Moved from index 3 to index 2 (Analytics tab)
    const ReportsPage(), // Moved from index 2 to index 3 (Alerts tab)
    const NotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Authenticating admin access...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep blue
                Color(0xFF3F51B5), // Indigo
                Color(0xFF009688), // Teal
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RapidWarn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Notification Bell
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Notification action - UI only
                  },
                ),
              ),
              // Profile Menu
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[700]),
                          const SizedBox(width: 12),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey[700]),
                          const SizedBox(width: 12),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          const Text(
                            'Logout',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        // Profile action - UI only
                        break;
                      case 'settings':
                        // Settings action - UI only
                        break;
                      case 'logout':
                        // Logout action - UI only
                        break;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF3F51B5), // Indigo
              Color(0xFF009688), // Teal
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: "Users",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article_outlined),
                activeIcon: Icon(Icons.article),
                label: "Content",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: "Analytics",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: "Alerts",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ---------------- Users Page ----------------
//
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final usersRef = FirebaseFirestore.instance.collection('users');
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  List<Map<String, dynamic>> _cachedUsers = [];
  bool _isOnline = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _initializeOfflineSupport();
    _createTestUser(); // Add a test user to verify the system works
    _setupRealtimeListener();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  // Initialize offline support and load cached data
  Future<void> _initializeOfflineSupport() async {
    try {
      // Enable Firestore offline persistence
      await FirebaseFirestore.instance.enablePersistence();
      print('✅ Firestore offline persistence enabled');

      // Load cached users from previous session
      await _loadCachedUsers();
    } catch (e) {
      print('⚠️ Offline persistence setup: $e');
    }
  }

  // Setup real-time listener for user changes
  void _setupRealtimeListener() {
    print('🔄 Setting up real-time user listener...');
    _usersSubscription =
        usersRef.snapshots(includeMetadataChanges: true).listen(
      (snapshot) {
        print(
            '📡 Received real-time user update: ${snapshot.docs.length} users');
        _handleUserUpdates(snapshot);
      },
      onError: (error) {
        print('❌ Real-time listener error: $error');
        setState(() => _isOnline = false);
      },
    );
  }

  // Handle real-time user updates
  void _handleUserUpdates(QuerySnapshot snapshot) {
    try {
      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['doc_id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _cachedUsers = users;
        _isOnline = !snapshot.metadata.isFromCache;
        _lastSyncTime = DateTime.now();
      });

      // Save to local cache for offline access
      _saveCachedUsers(users);

      print('✅ User data updated: ${users.length} users, Online: $_isOnline');
    } catch (e) {
      print('❌ Error handling user updates: $e');
    }
  }

  // Save users to local cache
  Future<void> _saveCachedUsers(List<Map<String, dynamic>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((user) => jsonEncode(user)).toList();
      await prefs.setStringList('cached_users', usersJson);
      await prefs.setInt(
          'last_sync_time', DateTime.now().millisecondsSinceEpoch);
      print('💾 Users cached locally: ${users.length} users');
    } catch (e) {
      print('❌ Error saving cached users: $e');
    }
  }

  // Load users from local cache
  Future<void> _loadCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsersJson = prefs.getStringList('cached_users') ?? [];
      final lastSyncMs = prefs.getInt('last_sync_time') ?? 0;

      if (cachedUsersJson.isNotEmpty) {
        final users = cachedUsersJson.map((userJson) {
          return Map<String, dynamic>.from(jsonDecode(userJson));
        }).toList();

        setState(() {
          _cachedUsers = users;
          _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
        });

        print('📁 Loaded ${users.length} users from cache');
      }
    } catch (e) {
      print('❌ Error loading cached users: $e');
    }
  }

  // Check connectivity status
  void _checkConnectivity() {
    // Simple connectivity check using Firestore metadata
    FirebaseFirestore.instance.collection('users').limit(1).get().then((_) {
      setState(() => _isOnline = true);
    }).catchError((error) {
      setState(() => _isOnline = false);
    });
  }

  Future<void> _createTestUser() async {
    try {
      // Check if test user already exists
      final existingUser = await usersRef.doc('test-user-123').get();
      if (!existingUser.exists) {
        await usersRef.doc('test-user-123').set({
          'uid': 'test-user-123',
          'email': 'testuser@rapidwarn.com',
          'displayName': 'Test User',
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'status': 'active',
          'role': 'user',
          'phone': '+1234567890',
          'profile_image': null,
        });
        print('✅ Test user created successfully!');
      } else {
        print('✅ Test user already exists');
      }

      // Also create the real user that registered
      final realUserDoc =
          await usersRef.doc('3NarW6coPHd07Gek5bfK1gHWJZO2').get();
      if (!realUserDoc.exists) {
        await usersRef.doc('3NarW6coPHd07Gek5bfK1gHWJZO2').set({
          'uid': '3NarW6coPHd07Gek5bfK1gHWJZO2',
          'email': 'harshal2007@gmail.com',
          'displayName': 'Harshal',
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'status': 'active',
          'role': 'user',
          'phone': null,
          'profile_image': null,
        });
        print('✅ Real user document created for harshal2007@gmail.com');
      } else {
        print('✅ Real user document already exists');
      }
    } catch (e) {
      print('❌ Failed to create test user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline/Online Status Header
        _buildSyncStatusHeader(),
        // Users List
        Expanded(
          child: _cachedUsers.isEmpty
              ? _buildLoadingOrEmptyState()
              : _buildUsersListView(),
        ),
      ],
    );
  }

  // Build sync status header
  Widget _buildSyncStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOnline
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _isOnline
                ? Colors.green.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: _isOnline ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Real-time Sync Active' : 'Offline Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
                if (_lastSyncTime != null)
                  Text(
                    'Last updated: ${_formatSyncTime(_lastSyncTime!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${_cachedUsers.length} users',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Force refresh',
          ),
        ],
      ),
    );
  }

  // Build loading or empty state
  Widget _buildLoadingOrEmptyState() {
    if (_isOnline) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading users...'),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Offline Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No cached user data available',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _forceRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  // Build users list view
  Widget _buildUsersListView() {
    return ListView.builder(
      itemCount: _cachedUsers.length,
      itemBuilder: (context, index) {
        final userData = _cachedUsers[index];
        final docId = userData['doc_id'] ?? 'unknown_$index';
        return _buildUserTile(userData, docId);
      },
    );
  }

  // Force refresh data
  Future<void> _forceRefresh() async {
    setState(() => _isOnline = true);
    _checkConnectivity();

    try {
      // Try to fetch fresh data
      final snapshot =
          await usersRef.orderBy('created_at', descending: true).get();
      _handleUserUpdates(snapshot);
    } catch (e) {
      setState(() => _isOnline = false);
      print('❌ Force refresh failed: $e');
    }
  }

  // Format sync time
  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(time);
    }
  }

  Widget _buildUserTile(Map<String, dynamic> userData, String userId) {
    final email = userData['email'] ?? 'unknown';
    final displayName =
        userData['displayName'] ?? userData['display_name'] ?? 'No name';
    final role = userData['role'] ?? 'user';
    final status = userData['status'] ?? 'unknown';
    final createdAt = userData['created_at'];
    final lastLogin = userData['last_login'];
    final phone = userData['phone'];

    // Calculate if user is recently active (within last 24 hours)
    bool isRecentlyActive = false;
    if (lastLogin != null) {
      try {
        final loginTime = lastLogin is Timestamp
            ? lastLogin.toDate()
            : DateTime.parse(lastLogin.toString());
        isRecentlyActive = DateTime.now().difference(loginTime).inHours < 24;
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(role),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (isRecentlyActive)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(color: Colors.blue)),
            Row(
              children: [
                _buildStatusChip(role, _getRoleColor(role)),
                const SizedBox(width: 8),
                _buildStatusChip(status, _getStatusColor(status)),
                if (isRecentlyActive) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip('Active', Colors.green),
                ],
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User Details
                _buildDetailRow('User ID', userId),
                _buildDetailRow('Email', email),
                if (phone != null) _buildDetailRow('Phone', phone),
                _buildDetailRow('Role', role),
                _buildDetailRow('Status', status),
                if (createdAt != null)
                  _buildDetailRow('Joined', _formatTimestamp(createdAt)),
                if (lastLogin != null)
                  _buildDetailRow('Last Login', _formatTimestamp(lastLogin)),

                const SizedBox(height: 16),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  children: [
                    _buildActionButton('Promote', Icons.arrow_upward,
                        () => _setRole(userId, 'admin')),
                    _buildActionButton('Demote', Icons.arrow_downward,
                        () => _setRole(userId, 'user')),
                    _buildActionButton(
                        'Ban', Icons.block, () => _setRole(userId, 'banned')),
                    _buildActionButton(
                        'Delete', Icons.delete, () => _deleteUser(userId)),
                  ],
                ),
              ],
            ),
          ),
        ],
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'promote') await _setRole(userId, 'admin');
            if (value == 'demote') await _setRole(userId, 'user');
            if (value == 'ban') await _setRole(userId, 'banned');
            if (value == 'unban') await _setRole(userId, 'user');
            if (value == 'delete') await _deleteUser(userId);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'promote', child: Text('Promote → admin')),
            const PopupMenuItem(value: 'demote', child: Text('Demote → user')),
            const PopupMenuItem(value: 'ban', child: Text('Ban user')),
            const PopupMenuItem(value: 'unban', child: Text('Unban user')),
            const PopupMenuItem(
                value: 'delete', child: Text('🗑️ Delete user')),
          ],
        ),
      ),
    );
  }

  // Helper methods for enhanced user tile
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _setRole(String userId, String role) async {
    try {
      await usersRef.doc(userId).update({'role': role});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User role updated to $role")),
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
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await usersRef.doc(userId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }
}

//
// ---------------- Content Moderation Page ----------------
//
class ContentModerationPage extends StatefulWidget {
  const ContentModerationPage({Key? key}) : super(key: key);

  @override
  State<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends State<ContentModerationPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      print('📊 Fetched ${_reports.length} reports for content moderation');
    } catch (e) {
      print('❌ Error fetching reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.article, color: Colors.tealAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Content Moderation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.tealAccent),
                  onPressed: _fetchReports,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : _reports.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No reports submitted yet',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Reports will appear here when users submit them',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildReportCard(report);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final disasterType = report['type'] ?? 'Unknown';
    final mediaPath = report['media_path'] ?? '';
    final latitude = report['latitude']?.toString() ?? 'N/A';
    final longitude = report['longitude']?.toString() ?? 'N/A';
    final createdAt = report['created_at'] ?? '';

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with disaster type and timestamp
            Row(
              children: [
                _getDisasterIcon(disasterType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disasterType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _formatDateTime(createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip('PENDING'),
              ],
            ),

            const SizedBox(height: 12),

            // Media preview
            if (mediaPath.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[700],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    Supabase.instance.client.storage
                        .from('media')
                        .getPublicUrl(mediaPath),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child:
                            CircularProgressIndicator(color: Colors.tealAccent),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 32),
                            SizedBox(height: 8),
                            Text('Failed to load media',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Location info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: $latitude, $longitude',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveReport(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectReport(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDisasterIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'fire':
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'accident':
        icon = Icons.car_crash;
        color = Colors.red;
        break;
      case 'riot':
        icon = Icons.group;
        color = Colors.purple;
        break;
      case 'stampede':
        icon = Icons.groups;
        color = Colors.blue;
        break;
      default:
        icon = Icons.warning;
        color = Colors.yellow;
    }

    return Icon(icon, color: color, size: 32);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'Unknown time';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _approveReport(Map<String, dynamic> report) async {
    try {
      // Update report status in database
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'approved'}).eq('id', report['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchReports(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReport(Map<String, dynamic> report) async {
    try {
      // Update report status in database
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'rejected'}).eq('id', report['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _fetchReports(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

//
// ---------------- Reports Page ----------------
//
class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insights')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final reports = snapshot.data?.docs ?? [];
        if (reports.isEmpty) {
          return const Center(child: Text("📊 No reports found."));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index].data() as Map<String, dynamic>;
            final timestamp = report['timestamp'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate())
                : 'Unknown';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: Text(report['location'] ?? 'Unknown Location'),
                subtitle: Text(
                    'Classification: ${report['classification']}\n$dateStr'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

//
// ---------------- Notifications Page ----------------
//
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Push Notifications\nComing Soon",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

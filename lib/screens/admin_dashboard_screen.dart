import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'analytics_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng2;
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';

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

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Color(0xFF5E35B1), size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.red),
                  title: Text('Emergency Alert'),
                  subtitle: Text('Send emergency alert to all users'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _sendEmergencyAlertFromHeader();
                  },
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.notifications_active, color: Colors.purple),
                  title: Text('Open Notifications Tab'),
                  subtitle: Text('Go to full notification management'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedIndex =
                          4; // Navigate to notifications tab (index 4)
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmergencyAlertFromHeader() async {
    try {
      final notificationService = NotificationService();
      await notificationService.showLocalNotification(
        title: '🚨 EMERGENCY ALERT',
        body:
            'URGENT: Emergency situation detected. Please follow safety protocols.',
        channelId: 'emergency_alerts',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 Emergency alert sent successfully'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to send emergency alert: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  final List<Widget> _pages = [
    const UserManagementPage(),
    const AdminMapPage(),
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
          backgroundColor: const Color(0xFF5E35B1),
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
                Color(0xFF5E35B1), // Deep purple
                Color(0xFF7E57C2), // Medium purple
                Color(0xFF9575CD), // Light purple
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RapidWarn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
                    // Show notification dialog or bottom sheet
                    _showNotificationDialog(context);
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
              Color(0xFF5E35B1), // Deep purple
              Color(0xFF7E57C2), // Medium purple
              Color(0xFF9575CD), // Light purple
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
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: "Map",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: "Analytics",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: "Status",
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
    // Removed automatic user creation - only manual creation via buttons now
    _syncFirebaseAuthUsers(); // Sync existing Firebase Auth users to Firestore
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

  // Sync existing Firebase Auth users to Firestore for admin dashboard
  Future<void> _syncFirebaseAuthUsers() async {
    try {
      print('🔄 Syncing Firebase Auth users to Firestore...');

      // Get current Firebase Auth user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('Found current user: ${currentUser.email} (${currentUser.uid})');

        // Check if user document exists in Firestore
        final userDoc = await usersRef.doc(currentUser.uid).get();
        if (!userDoc.exists) {
          // Create user document in Firestore
          await usersRef.doc(currentUser.uid).set({
            'uid': currentUser.uid,
            'email': currentUser.email ?? 'unknown@example.com',
            'displayName': currentUser.displayName ?? 'User',
            'created_at': FieldValue.serverTimestamp(),
            'last_login': FieldValue.serverTimestamp(),
            'status': 'active',
            'role': 'user',
            'phone': currentUser.phoneNumber,
            'profile_image': currentUser.photoURL,
            'email_verified': currentUser.emailVerified,
          });
          print('✅ Synced user ${currentUser.email} to Firestore');
        } else {
          // Update last login time
          await usersRef.doc(currentUser.uid).update({
            'last_login': FieldValue.serverTimestamp(),
            'email_verified': currentUser.emailVerified,
          });
          print('✅ Updated existing user ${currentUser.email} in Firestore');
        }
      }

      // Also check Supabase for any users that might not be in Firestore
      final supabase = Supabase.instance.client;
      try {
        final supabaseUsers = await supabase
            .from('users')
            .select('firebase_uid, email, created_at')
            .limit(50);

        print('Found ${supabaseUsers.length} users in Supabase');

        for (final supabaseUser in supabaseUsers) {
          final firebaseUid = supabaseUser['firebase_uid'] as String?;
          final email = supabaseUser['email'] as String?;

          if (firebaseUid != null && email != null) {
            final firestoreDoc = await usersRef.doc(firebaseUid).get();
            if (!firestoreDoc.exists) {
              await usersRef.doc(firebaseUid).set({
                'uid': firebaseUid,
                'email': email,
                'displayName':
                    email.split('@')[0], // Use email prefix as display name
                'created_at': FieldValue.serverTimestamp(),
                'last_login': FieldValue.serverTimestamp(),
                'status': 'active',
                'role': 'user',
                'phone': null,
                'profile_image': null,
                'email_verified': true,
                'synced_from': 'supabase',
              });
              print('✅ Synced user $email from Supabase to Firestore');
            }
          }
        }
      } catch (supabaseError) {
        final errorMessage = supabaseError.toString();
        if (errorMessage.contains('relation "public.users" does not exist')) {
          print(
              '⚠️ Supabase users table does not exist yet. Please run the migration:');
          print('   1. Navigate to your Supabase project dashboard');
          print('   2. Go to SQL Editor');
          print(
              '   3. Run the migration from supabase/migrations/001_create_users_table.sql');
          print('   Or use Supabase CLI: supabase db push');
        } else {
          print('⚠️ Supabase sync error (continuing): $supabaseError');
        }
      }
    } catch (e) {
      print('❌ Failed to sync Firebase Auth users: $e');
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
            size: 18, // Reduced size
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Sync Active' : 'Offline', // Shorter text
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green : Colors.orange,
                    fontSize: 12, // Reduced font size
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_lastSyncTime != null)
                  Text(
                    'Updated: ${_formatSyncTime(_lastSyncTime!)}',
                    style: const TextStyle(
                      fontSize: 10, // Reduced font size
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${_cachedUsers.length} users',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11, // Reduced font size
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync, size: 16),
            onPressed: _syncFirebaseAuthUsers,
            tooltip: 'Sync users',
            color: Colors.blue,
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: _forceRefresh,
            tooltip: 'Refresh',
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
// ---------------- Admin Map Page ----------------
//
class AdminMapPage extends StatefulWidget {
  const AdminMapPage({Key? key}) : super(key: key);

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();
  Marker? _currentLocationMarker;
  final List<Marker> _disasterMarkers = [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _determinePositionAndMove();
    _loadDisasterAlerts();
  }

  Future<void> _determinePositionAndMove() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final latLng = latLng2.LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLocationMarker = Marker(
          point: latLng,
          width: 44,
          height: 44,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
        );
        _locating = false;
      });
      _mapController.move(latLng, 13.0);
    } catch (e) {
      setState(() => _locating = false);
    }
  }

  Future<void> _loadDisasterAlerts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      setState(() {
        _disasterMarkers.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;

          // Try multiple possible field names for disaster type
          final type = data['type'] as String? ??
              data['disaster_type'] as String? ??
              data['disasterType'] as String? ??
              data['classification'] as String?;

          print('🗺️ Loading marker - Type: $type, Lat: $lat, Lng: $lng');

          if (lat != null && lng != null) {
            _disasterMarkers.add(
              Marker(
                point: latLng2.LatLng(lat, lng),
                width: 44,
                height: 44,
                child: _buildDisasterMarkerChild(type),
              ),
            );
          }
        }
        print('✅ Loaded ${_disasterMarkers.length} disaster markers');
      });
    } catch (e) {
      print('❌ Error loading disaster alerts: $e');
    }
  }

  Widget _buildDisasterMarkerChild(String? type) {
    if (type == null) {
      print('⚠️ Marker has no type, using default red pin');
      return const Icon(Icons.location_on, color: Colors.red, size: 36);
    }

    final normalizedType = type.toLowerCase().trim();
    print('🎨 Building marker for type: "$normalizedType"');

    final iconMap = {
      "fire": "assets/icons/fire.png",
      "riot": "assets/icons/riot.png",
      "accident": "assets/icons/accident.png",
      "accidents": "assets/icons/accident.png",
      "stampede": "assets/icons/stampede.png",
    };

    final iconPath = iconMap[normalizedType];
    print('📍 Icon path for "$normalizedType": $iconPath');

    if (iconPath == null) {
      // Fallback for types without custom icons
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _getIconForType(normalizedType),
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // Use asset image with shadow and border
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.red,
              child: const Icon(Icons.emergency, color: Colors.white, size: 24),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department;
      case 'accident':
        return Icons.car_crash;
      case 'stampede':
        return Icons.group;
      case 'flood':
        return Icons.water;
      case 'earthquake':
        return Icons.terrain;
      case 'riot':
        return Icons.warning;
      default:
        return Icons.emergency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const latLng2.LatLng(19.0760, 72.8777), // Mumbai
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.rapidwarn',
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocationMarker != null) _currentLocationMarker!,
                  ..._disasterMarkers,
                ],
              ),
            ],
          ),
          if (_locating)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'locate',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _determinePositionAndMove,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'refresh',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _loadDisasterAlerts,
                  child: const Icon(Icons.refresh, color: Colors.blue),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Disaster Alerts Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_disasterMarkers.length} active alerts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                const Icon(Icons.article, color: Color(0xFFB39DDB), size: 28),
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
                  icon: const Icon(Icons.refresh, color: Color(0xFFB39DDB)),
                  onPressed: _fetchReports,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB39DDB)),
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
                            CircularProgressIndicator(color: Color(0xFFB39DDB)),
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
                      color: Color(0xFFB39DDB), size: 20),
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
class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF2A2D36),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF9575CD),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Pending Approval',
              ),
              Tab(
                icon: Icon(Icons.warning_amber_rounded),
                text: 'Active Alerts',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Resolved',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PendingApprovalsTab(),
              _ActiveAlertsTab(),
              _ResolvedAlertsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Pending Approvals Tab
class _PendingApprovalsTab extends StatelessWidget {
  const _PendingApprovalsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disaster_alerts')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9575CD)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading pending reports: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pendingAlerts = snapshot.data?.docs ?? [];
        debugPrint('🔍 Pending Alerts found: ${pendingAlerts.length}');

        // Log each alert for debugging
        for (int i = 0; i < pendingAlerts.length; i++) {
          final alertData = pendingAlerts[i].data() as Map<String, dynamic>;
          debugPrint(
              '📋 Alert $i: ${alertData['disaster_type']} by ${alertData['uploader_name']} at ${alertData['latitude']}, ${alertData['longitude']}');
        }

        // Sort manually by timestamp (descending)
        pendingAlerts.sort((a, b) {
          final aTime =
              (a.data() as Map)['timestamp'] as Timestamp? ?? Timestamp.now();
          final bTime =
              (b.data() as Map)['timestamp'] as Timestamp? ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });
        if (pendingAlerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, color: Colors.grey, size: 64),
                SizedBox(height: 16),
                Text(
                  'No Pending Approvals',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All disaster reports have been reviewed',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pendingAlerts.length,
          itemBuilder: (context, index) {
            final alert = pendingAlerts[index].data() as Map<String, dynamic>;
            final alertId = pendingAlerts[index].id;
            alert['id'] = alertId; // Add ID for reference

            final disasterType =
                (alert['disaster_type'] ?? 'unknown').toString().toLowerCase();
            final timestamp = alert['timestamp'] as Timestamp?;
            final uploaderName = alert['uploader_name'] ?? 'Unknown User';
            final latitude = alert['latitude']?.toString() ?? '0.0';
            final longitude = alert['longitude']?.toString() ?? '0.0';

            return Card(
              color: const Color(0xFF3A3E47),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getDisasterIconForType(disasterType),
                          color: _getDisasterColorForType(disasterType),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisasterTitleForType(disasterType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Reported by: $uploaderName',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  DateFormat('MMM dd, yyyy • HH:mm')
                                      .format(timestamp.toDate()),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Lat: $latitude, Lng: $longitude',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _approveAlert(context, alertId, alert),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _rejectAlert(context, alertId, alert),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showPendingDisasterDetails(context, alert),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveAlert(
      BuildContext context, String alertId, Map<String, dynamic> alert) async {
    try {
      // Update status to active
      await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(alertId)
          .update({
        'status': 'active',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': 'admin', // You can get current user info here
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Disaster report approved and activated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAlert(
      BuildContext context, String alertId, Map<String, dynamic> alert) async {
    try {
      // Update status to rejected
      await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(alertId)
          .update({
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
        'rejected_by': 'admin', // You can get current user info here
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Disaster report rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPendingDisasterDetails(
      BuildContext context, Map<String, dynamic> alert) {
    final timestamp = alert['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('MMMM dd, yyyy • HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final disasterType =
        (alert['disaster_type'] ?? 'unknown').toString().toLowerCase();
    final latitude = alert['latitude'];
    final longitude = alert['longitude'];
    final mediaUrl = alert['media_url'] ?? alert['photo_url'];
    final uploaderName = alert['uploader_name'] ?? 'Unknown User';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getDisasterIconForType(disasterType),
              color: _getDisasterColorForType(disasterType),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pending: ${_getDisasterTitleForType(disasterType)}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRowForPending(
                  Icons.person, 'Reported by', uploaderName),
              _buildDetailRowForPending(Icons.access_time, 'Time', dateStr),
              _buildDetailRowForPending(Icons.location_on, 'Location',
                  'Lat: ${latitude?.toStringAsFixed(4) ?? 'N/A'}, Lng: ${longitude?.toStringAsFixed(4) ?? 'N/A'}'),
              _buildDetailRowForPending(
                  Icons.category, 'Type', disasterType.toUpperCase()),
              _buildDetailRowForPending(
                  Icons.info, 'Status', 'PENDING APPROVAL'),
              if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Media:',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 32),
                              SizedBox(height: 8),
                              Text('Failed to load image',
                                  style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF9575CD))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowForPending(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDisasterColorForType(String type) {
    switch (type) {
      case 'fire':
        return const Color(0xFFFF4444);
      case 'accident':
        return const Color(0xFFFFA726);
      case 'stampede':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getDisasterIconForType(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department;
      case 'accident':
        return Icons.car_crash;
      case 'stampede':
        return Icons.groups;
      default:
        return Icons.info_outline;
    }
  }

  String _getDisasterTitleForType(String type) {
    switch (type) {
      case 'fire':
        return 'Fire Emergency';
      case 'accident':
        return 'Accident Reported';
      case 'stampede':
        return 'Stampede Alert';
      default:
        return 'General Alert';
    }
  }
}

// Active Alerts Tab
class _ActiveAlertsTab extends StatelessWidget {
  const _ActiveAlertsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disaster_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9575CD)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Error loading alerts",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "${snapshot.error}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final alerts = snapshot.data?.docs ?? [];
        // Sort manually by timestamp (descending)
        alerts.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[300], size: 64),
                const SizedBox(height: 16),
                const Text(
                  "🎉 No Active Alerts",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "All disasters have been resolved",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index].data() as Map<String, dynamic>;
            final timestamp = alert['timestamp'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('MMM dd, yyyy • HH:mm').format(timestamp.toDate())
                : 'Unknown';
            final disasterType =
                (alert['disaster_type'] ?? 'normal').toString().toLowerCase();

            // Skip "normal" disasters - only show fire, accident, stampede
            if (disasterType == 'normal') {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _getDisasterColor(disasterType).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _showDisasterDetails(context, alert),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _getDisasterColor(disasterType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getDisasterIcon(disasterType),
                          color: _getDisasterColor(disasterType),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisasterTitle(disasterType),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alert['location'] ?? 'Unknown Location',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pending_actions,
                                      size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'Awaiting Rescue Team',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getDisasterColor(String type) {
    switch (type) {
      case 'fire':
        return const Color(0xFFFF4444);
      case 'accident':
        return const Color(0xFFFFA726);
      case 'stampede':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getDisasterIcon(String type) {
    switch (type) {
      case 'fire':
        return Icons.local_fire_department;
      case 'accident':
        return Icons.car_crash;
      case 'stampede':
        return Icons.groups;
      default:
        return Icons.info_outline;
    }
  }

  String _getDisasterTitle(String type) {
    switch (type) {
      case 'fire':
        return 'Fire Emergency';
      case 'accident':
        return 'Accident Reported';
      case 'stampede':
        return 'Stampede Alert';
      default:
        return 'General Alert';
    }
  }

  void _showDisasterDetails(
      BuildContext context, Map<String, dynamic> alert) async {
    final timestamp = alert['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('MMMM dd, yyyy • HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final disasterType =
        (alert['disaster_type'] ?? 'normal').toString().toLowerCase();
    final latitude = alert['latitude'];
    final longitude = alert['longitude'];
    final mediaUrl = alert['media_url'] ?? alert['photo_url'];

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF9575CD)),
      ),
    );

    // Try to fetch additional data from Supabase
    String description = 'No description available';
    String? supabaseImageUrl;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('insights')
          .select(
              'description, user_description, media_url, latitude, longitude')
          .eq('latitude', latitude)
          .eq('longitude', longitude)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        description = response['description'] ??
            response['user_description'] ??
            'No description available';
        supabaseImageUrl = response['media_url'];
      }
    } catch (e) {
      print('⚠️ Could not fetch from Supabase: $e');
    }

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show actual details dialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDisasterColor(disasterType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDisasterIcon(disasterType),
                color: _getDisasterColor(disasterType),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisasterTitle(disasterType),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.location_on, 'Location',
                  alert['location'] ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.my_location, 'Latitude',
                  latitude?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.my_location, 'Longitude',
                  longitude?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Reported', dateStr),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (supabaseImageUrl != null || mediaUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    supabaseImageUrl ?? mediaUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF9575CD)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF9575CD))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Resolved Alerts Tab
class _ResolvedAlertsTab extends StatelessWidget {
  const _ResolvedAlertsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disaster_alerts')
          .where('status', isEqualTo: 'resolved')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9575CD)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Error loading resolved alerts",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final resolvedAlerts = snapshot.data?.docs ?? [];
        // Sort manually by resolved_at (descending)
        resolvedAlerts.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['resolved_at'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['resolved_at'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        if (resolvedAlerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: Colors.grey[400], size: 64),
                const SizedBox(height: 16),
                const Text(
                  "No Resolved Alerts Yet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Resolved disasters will appear here",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: resolvedAlerts.length,
          itemBuilder: (context, index) {
            final alert = resolvedAlerts[index].data() as Map<String, dynamic>;
            final timestamp = alert['timestamp'] as Timestamp?;
            final resolvedAt = alert['resolved_at'] as Timestamp?;
            final reportedStr = timestamp != null
                ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
                : 'Unknown';
            final resolvedStr = resolvedAt != null
                ? DateFormat('MMM dd, HH:mm').format(resolvedAt.toDate())
                : 'Unknown';
            final resolvedBy = alert['resolved_by'] ?? 'Rescue Team';
            final disasterType =
                (alert['disaster_type'] ?? 'normal').toString().toLowerCase();

            // Calculate response time
            String responseTime = 'N/A';
            if (timestamp != null && resolvedAt != null) {
              final duration =
                  resolvedAt.toDate().difference(timestamp.toDate());
              if (duration.inHours > 0) {
                responseTime =
                    '${duration.inHours}h ${duration.inMinutes % 60}m';
              } else {
                responseTime = '${duration.inMinutes}m';
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: Colors.green.withOpacity(0.2), width: 2),
              ),
              child: InkWell(
                onTap: () => _showDisasterDetails(context, alert),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisasterTitle(disasterType) + ' - Resolved',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    alert['location'] ?? 'Unknown Location',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'By: $resolvedBy',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$reportedStr → $resolvedStr',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer,
                                      size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Response: $responseTime',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDisasterTitle(String type) {
    switch (type) {
      case 'fire':
        return 'Fire Emergency';
      case 'accident':
        return 'Accident';
      case 'stampede':
        return 'Stampede';
      default:
        return 'General Alert';
    }
  }

  void _showDisasterDetails(
      BuildContext context, Map<String, dynamic> alert) async {
    final timestamp = alert['timestamp'] as Timestamp?;
    final resolvedAt = alert['resolved_at'] as Timestamp?;
    final reportedStr = timestamp != null
        ? DateFormat('MMMM dd, yyyy • HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final resolvedStr = resolvedAt != null
        ? DateFormat('MMMM dd, yyyy • HH:mm').format(resolvedAt.toDate())
        : 'Unknown';
    final disasterType =
        (alert['disaster_type'] ?? 'normal').toString().toLowerCase();
    final resolvedBy = alert['resolved_by'] ?? 'Rescue Team';
    final latitude = alert['latitude'];
    final longitude = alert['longitude'];
    final mediaUrl = alert['media_url'] ?? alert['photo_url'];

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF9575CD)),
      ),
    );

    // Fetch from Supabase
    String description = 'No description available';
    String? supabaseImageUrl;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('insights')
          .select('description, user_description, media_url')
          .eq('latitude', latitude)
          .eq('longitude', longitude)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        description = response['description'] ??
            response['user_description'] ??
            'No description available';
        supabaseImageUrl = response['media_url'];
      }
    } catch (e) {
      print('⚠️ Could not fetch from Supabase: $e');
    }

    // Close loading
    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisasterTitle(disasterType) + ' - Resolved',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.location_on, 'Location',
                  alert['location'] ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.my_location, 'Latitude',
                  latitude?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.my_location, 'Longitude',
                  longitude?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Reported', reportedStr),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.check_circle_outline, 'Resolved', resolvedStr),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.person_outline, 'Resolved By', resolvedBy),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (supabaseImageUrl != null || mediaUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    supabaseImageUrl ?? mediaUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF9575CD)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF9575CD))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//
// ---------------- Notifications Page ----------------
//
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _sendingNotification = false;
  List<Map<String, dynamic>> _recentNotifications = [];
  NotificationService? _notificationService;
  int _tapCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
    _loadRecentNotifications();
  }

  Future<void> _initializeNotificationService() async {
    try {
      _notificationService = NotificationService();
      await _notificationService!.initialize();
      debugPrint('✅ Admin notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  Future<void> _loadRecentNotifications() async {
    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      setState(() {
        _recentNotifications = notificationsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _sendingNotification = true);

    try {
      debugPrint('🔔 Admin test notification button pressed');

      // Ensure notification service is initialized
      if (_notificationService == null) {
        await _initializeNotificationService();
      }

      // Use NotificationService for local notification
      if (_notificationService != null) {
        await _notificationService!.sendTestNotification();
        debugPrint('✅ Test notification sent via service');
      } else {
        debugPrint(
            '⚠️ Notification service not available, showing snackbar only');
      }

      // Also save to Firestore for history
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'admin_test',
        'title': '🔔 Admin Test Notification',
        'message':
            'This is a test notification from the admin dashboard. All systems are working correctly.',
        'recipient_type': 'all',
        'timestamp': FieldValue.serverTimestamp(),
        'sent_by': 'admin',
        'read': false,
        'priority': 'normal',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      _loadRecentNotifications(); // Refresh the list
    } catch (e) {
      debugPrint('❌ Failed to send notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send notification: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _sendingNotification = false);
    }
  }

  Future<void> _sendEmergencyAlert() async {
    setState(() => _sendingNotification = true);

    try {
      debugPrint('🚨 Admin emergency alert button pressed');

      // Ensure notification service is initialized
      if (_notificationService == null) {
        await _initializeNotificationService();
      }

      // Use NotificationService for local notification
      if (_notificationService != null) {
        await _notificationService!.showLocalNotification(
          title: '🚨 EMERGENCY ALERT',
          body:
              'URGENT: Emergency situation detected. Please follow safety protocols and stay alert.',
          channelId: 'emergency_alerts',
        );
        debugPrint('✅ Emergency alert sent via service');
      } else {
        debugPrint(
            '⚠️ Notification service not available, showing snackbar only');
      }

      // Also save to Firestore for history
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'emergency_alert',
        'title': '🚨 EMERGENCY ALERT',
        'message':
            'URGENT: Emergency situation detected. Please follow safety protocols and stay alert.',
        'recipient_type': 'all',
        'timestamp': FieldValue.serverTimestamp(),
        'sent_by': 'admin',
        'read': false,
        'priority': 'critical',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency alert sent successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      _loadRecentNotifications(); // Refresh the list
    } catch (e) {
      debugPrint('❌ Failed to send emergency alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send emergency alert: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _sendingNotification = false);
    }
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final timestamp = notification['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
        : 'Unknown time';

    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'emergency_alert':
        icon = Icons.warning;
        iconColor = Colors.red;
        break;
      case 'admin_test':
        icon = Icons.notifications;
        iconColor = Colors.blue;
        break;
      case 'disaster_approved':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          notification['title'] ?? 'No title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? 'No message'),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification['priority'] == 'critical'
            ? const Icon(Icons.priority_high, color: Colors.red)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Simple Test Button (for debugging)
          Center(
            child: Column(
              children: [
                Text('Debug: Tap counter: $_tapCounter',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    print('🚀 Button tapped! Counter: $_tapCounter');
                    setState(() {
                      _tapCounter++;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🚀 Button tapped $_tapCounter times!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('DEBUG: Tap Me!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notification Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendingNotification
                      ? null
                      : () => _sendTestNotification(),
                  icon: _sendingNotification
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications),
                  label: const Text('Send Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _sendingNotification ? null : () => _sendEmergencyAlert(),
                  icon: _sendingNotification
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.warning),
                  label: const Text('Emergency Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Notifications Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadRecentNotifications,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh notifications',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Notifications List
          Expanded(
            child: _recentNotifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationTile(
                          _recentNotifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

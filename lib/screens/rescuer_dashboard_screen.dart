import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng2;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class RescuerDashboardScreen extends StatefulWidget {
  final String rescuerEmail;

  const RescuerDashboardScreen({
    Key? key,
    required this.rescuerEmail,
  }) : super(key: key);

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  final MapController _mapController = MapController();
  Marker? _currentLocationMarker;
  final List<Marker> _disasterMarkers = [];
  List<Map<String, dynamic>> _disasters = [];
  Map<String, dynamic>? _selectedDisaster;
  bool _locating = false;
  int _currentTabIndex = 0; // 0 = Map, 1 = Details

  @override
  void initState() {
    super.initState();
    _determinePositionAndMove();
    _loadActiveDisasters();

    // Listen for real-time updates
    _listenToDisasterUpdates();
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
          child: const Icon(Icons.person_pin_circle,
              color: Colors.green, size: 40),
        );
        _locating = false;
      });
      _mapController.move(latLng, 13.0);
    } catch (e) {
      setState(() => _locating = false);
    }
  }

  void _listenToDisasterUpdates() {
    // Listen to ALL disasters (no status filter) for real-time updates
    FirebaseFirestore.instance
        .collection('disaster_alerts')
        .snapshots()
        .listen((snapshot) {
      print('🔔 Real-time update received: ${snapshot.docs.length} documents');
      _loadActiveDisasters();
    });
  }

  Future<void> _loadActiveDisasters() async {
    try {
      print('🔍 Starting to load disasters from Firestore...');

      // ✅ Try to load ALL disasters first (no status filter) to debug
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('disaster_alerts')
            .get();
        print(
            '📊 Total documents in disaster_alerts collection: ${snapshot.docs.length}');

        // If we got documents, filter by status in code
        if (snapshot.docs.isNotEmpty) {
          print('🔍 Checking status of each document...');
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final status = data?['status'];
            print('  - Doc ${doc.id}: status = "$status"');
          }
        }
      } catch (e) {
        print('❌ Error fetching all documents: $e');
        // Fallback to status filter - include both pending and active
        snapshot = await FirebaseFirestore.instance
            .collection('disaster_alerts')
            .where('status', whereIn: ['pending', 'active']).get();
      }

      print('📊 Documents to process: ${snapshot.docs.length}');

      setState(() {
        _disasters.clear();
        _disasterMarkers.clear();

        // Get all docs and sort manually
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          final aTime = (aData?['timestamp'] as Timestamp?)?.toDate();
          final bTime = (bData?['timestamp'] as Timestamp?)?.toDate();
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending
        });

        int totalCount = 0;
        int filteredCount = 0;
        int addedCount = 0;

        for (var doc in docs) {
          totalCount++;
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('⚠️ Doc ${doc.id} has null data');
            continue;
          }

          data['id'] = doc.id;

          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;
          final type = data['type'] as String? ??
              data['disaster_type'] as String? ??
              data['disasterType'] as String?;

          print(
              '📍 Doc ${doc.id}: type="$type", lat=$lat, lng=$lng, status=${data['status']}');

          // ✅ TEMPORARILY SHOW ALL - FOR DEBUGGING
          // TODO: Re-enable filter after testing
          /*
          final normalizedType = type?.toLowerCase().trim() ?? '';
          if (normalizedType != 'fire' && 
              normalizedType != 'accident' && 
              normalizedType != 'accidents' &&
              normalizedType != 'stampede') {
            print('⏭️ Skipping disaster type: "$type" (normalized: "$normalizedType")');
            filteredCount++;
            continue; // Skip this disaster
          }
          */
          print('✅ Accepting disaster type: "$type"');

          if (lat != null && lng != null) {
            print('✅ Adding disaster: $type at ($lat, $lng)');
            _disasters.add(data);

            _disasterMarkers.add(
              Marker(
                point: latLng2.LatLng(lat, lng),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDisaster = data;
                      _currentTabIndex = 1; // Switch to Details tab
                    });
                    _mapController.move(latLng2.LatLng(lat, lng), 15.0);
                  },
                  child: _buildDisasterMarkerChild(type),
                ),
              ),
            );
            addedCount++;
          } else {
            print(
                '⚠️ Skipping disaster with null coordinates: lat=$lat, lng=$lng');
          }
        }

        print(
            '📊 SUMMARY: Total=$totalCount, Filtered=$filteredCount, Added=$addedCount, Final=${_disasters.length}');
        if (_disasters.isEmpty) {
          print('⚠️ No fire/accident/stampede disasters found in database');
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error loading disasters: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Widget _buildDisasterMarkerChild(String? type) {
    if (type == null) {
      return const Icon(Icons.warning_amber_rounded,
          color: Colors.red, size: 50);
    }

    final normalizedType = type.toLowerCase().trim();
    final iconMap = {
      "fire": "assets/icons/fire.png",
      "riot": "assets/icons/riot.png",
      "accident": "assets/icons/accident.png",
      "accidents": "assets/icons/accident.png",
      "stampede": "assets/icons/stampede.png",
    };

    final iconPath = iconMap[normalizedType];

    if (iconPath == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.emergency, color: Colors.white, size: 32),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          iconPath,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.red,
              child: const Icon(Icons.emergency, color: Colors.white, size: 32),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAsResolved(String disasterId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF252A34),
          title: const Text(
            'Confirm Resolution',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to mark this disaster as resolved? '
            'This will notify all users and admins.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A085),
              ),
              child: const Text('Confirm Resolution'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Get disaster details before updating
      final disasterDoc = await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(disasterId)
          .get();

      final disasterData = disasterDoc.data();
      final disasterType =
          disasterData?['type'] ?? disasterData?['disaster_type'] ?? 'Unknown';
      final location = disasterData?['location'] ?? 'Unknown location';
      final uploaderId =
          disasterData?['uploader_id'] ?? disasterData?['user_id'];

      // Update disaster status in Firestore
      await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(disasterId)
          .update({
        'status': 'resolved',
        'resolved_at': FieldValue.serverTimestamp(),
        'resolved_by': widget.rescuerEmail,
        'resolved_by_rescuer': true,
      });

      // Send notifications to all users and admins
      await _sendResolvedNotifications(
        disasterId: disasterId,
        disasterType: disasterType,
        location: location,
        uploaderId: uploaderId,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '✅ Disaster marked as resolved!\nNotifications sent to users and admins.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF16A085),
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Clear selection and reload
      setState(() {
        _selectedDisaster = null;
      });
      _loadActiveDisasters();
    } catch (e) {
      print('❌ Error marking disaster as resolved: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as resolved: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ New function to approve/verify pending disasters
  Future<void> _approveDisaster(String disasterId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF252A34),
          title: const Text(
            'Approve & Verify Disaster',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to approve and verify this disaster alert? '
            'This will notify all admins and users in the area about the confirmed emergency.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: const Text('Approve & Verify'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Get disaster details before updating
      final disasterDoc = await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(disasterId)
          .get();

      final disasterData = disasterDoc.data();
      final disasterType =
          disasterData?['type'] ?? disasterData?['disaster_type'] ?? 'Unknown';
      final location = disasterData?['location'] ?? 'Unknown location';
      final latitude = disasterData?['latitude'];
      final longitude = disasterData?['longitude'];
      final uploaderId =
          disasterData?['uploader_id'] ?? disasterData?['user_id'];

      // Update disaster status to "active" (approved and verified)
      await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(disasterId)
          .update({
        'status': 'active',
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': widget.rescuerEmail,
        'verified_by_rescuer': true,
        'rescuer_verified': true,
      });

      // Send notifications to admins and all users
      await _sendApprovalNotifications(
        disasterId: disasterId,
        disasterType: disasterType,
        location: location,
        latitude: latitude,
        longitude: longitude,
        uploaderId: uploaderId,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.verified, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      '✅ Disaster approved and verified!\nNotifications sent to admins and all users.'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2196F3),
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Refresh the list
      _loadActiveDisasters();
    } catch (e) {
      print('❌ Error approving disaster: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve disaster: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendResolvedNotifications({
    required String disasterId,
    required String disasterType,
    required String location,
    String? uploaderId,
  }) async {
    try {
      print('📤 Sending resolution notifications...');

      // 1. Notify the user who reported the disaster
      if (uploaderId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'disaster_resolved',
          'disaster_id': disasterId,
          'disaster_type': disasterType,
          'location': location,
          'title': '✅ Disaster Resolved',
          'message':
              'Your reported $disasterType at $location has been resolved by the rescue team.',
          'recipient_id': uploaderId,
          'recipient_type': 'user',
          'timestamp': FieldValue.serverTimestamp(),
          'resolved_by': widget.rescuerEmail,
          'read': false,
        });
        print('✅ Notified uploader: $uploaderId');
      }

      // 2. Notify all admins
      final admins = await FirebaseFirestore.instance
          .collection('admin_sessions')
          .where('isActive', isEqualTo: true)
          .get();

      for (var admin in admins.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'disaster_resolved',
          'disaster_id': disasterId,
          'disaster_type': disasterType,
          'location': location,
          'title': '✅ Disaster Resolved by Rescue Team',
          'message':
              'A $disasterType at $location has been successfully resolved.',
          'recipient_id': admin.id,
          'recipient_type': 'admin',
          'timestamp': FieldValue.serverTimestamp(),
          'resolved_by': widget.rescuerEmail,
          'read': false,
        });
      }
      print('✅ Notified ${admins.docs.length} admins');

      // 3. Notify all nearby users who were alerted
      final disasterDoc = await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(disasterId)
          .get();

      final notifiedUsers =
          disasterDoc.data()?['notified_users'] as List<dynamic>? ?? [];

      for (var userId in notifiedUsers) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'disaster_resolved',
          'disaster_id': disasterId,
          'disaster_type': disasterType,
          'location': location,
          'title': '✅ Disaster Alert Resolved',
          'message':
              'The $disasterType at $location has been resolved. You are now safe.',
          'recipient_id': userId,
          'recipient_type': 'user',
          'timestamp': FieldValue.serverTimestamp(),
          'resolved_by': widget.rescuerEmail,
          'read': false,
        });
      }
      print('✅ Notified ${notifiedUsers.length} alerted users');

      // 4. Create a general notification for all users
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'disaster_resolved',
        'disaster_id': disasterId,
        'disaster_type': disasterType,
        'location': location,
        'title': '✅ Emergency Resolved',
        'message':
            'A $disasterType emergency at $location has been successfully resolved by our rescue team.',
        'recipient_type': 'all',
        'timestamp': FieldValue.serverTimestamp(),
        'resolved_by': widget.rescuerEmail,
        'read': false,
      });

      print('✅ All resolution notifications sent successfully');
    } catch (e) {
      print('❌ Error sending notifications: $e');
    }
  }

  // ✅ Send approval notifications to admins and all users
  Future<void> _sendApprovalNotifications({
    required String disasterId,
    required String disasterType,
    required String location,
    double? latitude,
    double? longitude,
    String? uploaderId,
  }) async {
    try {
      print('📤 Sending approval notifications using enhanced system...');

      // ✅ Use the new enhanced notification system
      if (latitude != null && longitude != null && uploaderId != null) {
        final notificationService = NotificationService();

        // Get current rescuer ID
        final currentUser = FirebaseAuth.instance.currentUser;
        final rescuerId = currentUser?.uid ?? 'unknown';

        // Send comprehensive approval notifications
        await notificationService.notifyOnDisasterApproval(
          disasterType: disasterType,
          latitude: latitude,
          longitude: longitude,
          uploaderId: uploaderId,
          rescuerId: rescuerId,
        );

        // Also send area-wide emergency notifications to nearby users
        await notificationService.sendDisasterAlert(
          disasterType: disasterType,
          latitude: latitude,
          longitude: longitude,
          location: location,
          uploaderId: uploaderId,
        );

        print('✅ Enhanced approval notifications sent successfully');
      } else {
        print(
            '⚠️ Missing required data for enhanced notifications, using fallback...');

        // Fallback: Basic notification for incomplete data
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'disaster_approved',
          'disaster_id': disasterId,
          'disaster_type': disasterType,
          'location': location,
          'title': '🚨 EMERGENCY ALERT - VERIFIED',
          'message':
              'CONFIRMED: $disasterType emergency at $location has been verified by rescue team.',
          'recipient_type': 'all',
          'timestamp': FieldValue.serverTimestamp(),
          'approved_by': widget.rescuerEmail,
          'read': false,
          'priority': 'critical',
        });
        print('✅ Fallback notification sent');
      }
    } catch (e) {
      print('❌ Error sending approval notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2028),
      appBar: AppBar(
        title: const Text('Rescuer Dashboard'),
        backgroundColor: const Color(0xFF16A085),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveDisasters,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildMapView(),
          _buildDetailsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        backgroundColor: const Color(0xFF252A34),
        selectedItemColor: const Color(0xFF16A085),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Details',
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const latLng2.LatLng(19.0760, 72.8777),
            initialZoom: 12.0,
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
        if (_locating) const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _determinePositionAndMove,
            child: const Icon(Icons.my_location, color: Color(0xFF16A085)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsView() {
    if (_selectedDisaster == null) {
      return _buildDisasterList();
    }
    return _buildDisasterDetails();
  }

  Widget _buildDisasterList() {
    if (_disasters.isEmpty) {
      return Container(
        color: const Color(0xFF1B2028),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 100, color: Colors.green.shade300),
              const SizedBox(height: 24),
              const Text(
                'No Active Disasters',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All clear! No disasters to handle.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1B2028),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16A085), Color(0xFF2ECC71)],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Active Disasters (${_disasters.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _disasters.length,
              itemBuilder: (context, index) {
                final disaster = _disasters[index];
                final type =
                    disaster['type'] ?? disaster['disaster_type'] ?? 'Unknown';
                final location = disaster['location'] ?? 'Unknown location';
                final timestamp = disaster['timestamp'] as Timestamp?;
                final timeStr = timestamp != null
                    ? DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(timestamp.toDate())
                    : 'Unknown time';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                  color: const Color(0xFF252A34),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDisaster = disaster;
                      });
                      final lat = disaster['latitude'] as double?;
                      final lng = disaster['longitude'] as double?;
                      if (lat != null && lng != null) {
                        _mapController.move(latLng2.LatLng(lat, lng), 15.0);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getColorForType(type),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconForType(type),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.grey, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.grey, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF16A085),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterDetails() {
    final disaster = _selectedDisaster!;
    final type = disaster['type'] ?? disaster['disaster_type'] ?? 'Unknown';
    final description = disaster['description'] ??
        disaster['userDescription'] ??
        disaster['user_description'] ??
        'No description provided by user';
    final intensity =
        disaster['intensity'] ?? disaster['severity'] ?? 'Unknown';
    final location = disaster['location'] ?? 'Unknown location';
    final mediaUrl = disaster['media_url'] ??
        disaster['mediaUrl'] ??
        disaster['photo_url'] ??
        disaster['photoUrl'];
    final timestamp = disaster['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('EEEE, MMM dd, yyyy at hh:mm a').format(timestamp.toDate())
        : 'Unknown time';

    return Container(
      color: const Color(0xFF1B2028),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16A085), Color(0xFF2ECC71)],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedDisaster = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disaster Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Image
                  if (mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        mediaUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 80, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ✅ Status Badge (NEW)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: disaster['status'] == 'pending'
                          ? Colors.orange
                          : const Color(0xFF16A085),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (disaster['status'] == 'pending'
                                  ? Colors.orange
                                  : const Color(0xFF16A085))
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          disaster['status'] == 'pending'
                              ? Icons.hourglass_empty
                              : Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disaster['status'] == 'pending'
                              ? 'PENDING APPROVAL'
                              : 'VERIFIED & ACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _getColorForType(type),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _getColorForType(type).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIconForType(type),
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252A34),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF16A085).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.access_time, 'Time', timeStr),
                        const Divider(height: 24, color: Colors.white24),
                        _buildDetailRow(
                            Icons.location_on, 'Location', location),
                        const Divider(height: 24, color: Colors.white24),
                        _buildDetailRow(Icons.warning_amber, 'Intensity',
                            intensity.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252A34),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ✅ Conditional buttons based on disaster status
                  if (disaster['status'] == 'pending') ...[
                    // Approve/Verify Button for pending disasters
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveDisaster(disaster['id']),
                        icon: const Icon(Icons.verified, size: 32),
                        label: const Text(
                          'APPROVE & VERIFY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF2196F3).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ] else if (disaster['status'] == 'active') ...[
                    // Mark as Resolved Button for active disasters
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsResolved(disaster['id']),
                        icon: const Icon(Icons.check_circle, size: 32),
                        label: const Text(
                          'MARK AS RESCUED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A085),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF16A085).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF16A085), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
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

  Color _getColorForType(String type) {
    final normalizedType = type.toLowerCase();
    switch (normalizedType) {
      case 'fire':
        return Colors.red;
      case 'accident':
      case 'accidents':
        return Colors.orange;
      case 'stampede':
        return Colors.purple;
      case 'flood':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    final normalizedType = type.toLowerCase();
    switch (normalizedType) {
      case 'fire':
        return Icons.local_fire_department;
      case 'accident':
      case 'accidents':
        return Icons.car_crash;
      case 'stampede':
        return Icons.group;
      case 'flood':
        return Icons.water;
      default:
        return Icons.warning;
    }
  }
}

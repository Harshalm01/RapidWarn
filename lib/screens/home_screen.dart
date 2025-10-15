// lib/screens/home_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng2;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_alerts_service.dart';
import '../services/offline_mode_service.dart';
import '../screens/more_screen.dart';
import '../main.dart' show notificationHistory, AppNotification;

// Supabase table used for saving user-submitted entries. Updated to 'insights'
// to match newly added RLS policies.
const String kInsightsTable = 'insights';

// ------------------ NOTIFICATION SCREEN ------------------
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear all',
            onPressed: () {
              notificationHistory.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: notificationHistory.isEmpty
          ? const Center(
              child: Text("No notifications yet",
                  style: TextStyle(color: Colors.white70)),
            )
          : ListView.separated(
              itemCount: notificationHistory.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final notif = notificationHistory[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2F36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.notifications, color: Colors.white70),
                  ),
                  title: Text(notif.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(notif.body,
                      style: const TextStyle(color: Colors.white70)),
                  trailing: Text(_formatTime(notif.timestamp),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                );
              },
            ),
    );
  }
}

// ------------------ MEDIA SCREEN ------------------
class MediaScreen extends StatelessWidget {
  final supabase = Supabase.instance.client;
  MediaScreen({Key? key}) : super(key: key);

  Future<List<String>> _fetchMedia() async {
    final res = await supabase.storage.from("media").list();
    return res.map((f) => f.name).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      body: FutureBuilder<List<String>>(
        future: _fetchMedia(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text("Error: ${snap.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final files = snap.data ?? [];
          if (files.isEmpty) {
            return const Center(
              child: Text("No media uploaded yet",
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: const Icon(Icons.image, color: Colors.white70),
              title:
                  Text(files[i], style: const TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }
}

// ------------------ ABOUT US SCREEN ------------------
class AboutUsScreen extends StatelessWidget {
  final VoidCallback onStartMap;
  const AboutUsScreen({Key? key, required this.onStartMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF16A085), Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -30,
                      child: Opacity(
                        opacity: 0.15,
                        child:
                            Icon(Icons.sensors, color: Colors.white, size: 180),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/icon.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'RapidWarn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Real-time disaster alerts and reporting to keep communities safe.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feature highlights
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why RapidWarn?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _FeatureChip(
                            icon: Icons.location_on,
                            title: 'Live location reporting'),
                        _FeatureChip(
                            icon: Icons.image_outlined, title: 'Media uploads'),
                        _FeatureChip(
                            icon: Icons.notifications_active,
                            title: 'Instant alerts'),
                        _FeatureChip(
                            icon: Icons.group, title: 'Community safety'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Value section card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2028),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Text(
                    'RapidWarn helps you report incidents with precise locations and media, and receive timely notifications to stay aware. Together, we can act faster and safer.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onStartMap,
                  icon: const Icon(Icons.map_outlined, color: Colors.white),
                  label: const Text('Start Exploring the Map',
                      style: TextStyle(color: Colors.white)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String title;
  const _FeatureChip({Key? key, required this.icon, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF262C36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

// ------------------ PROFILE SCREEN ------------------
class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;

  void _logout(BuildContext context) async {
    await fb_auth.FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _changeNameDialog(BuildContext context) async {
    final controller = TextEditingController(text: user?.displayName ?? "");
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Your Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text("Update"),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != user?.displayName) {
      try {
        await user?.updateDisplayName(newName);
        await fb_auth.FirebaseAuth.instance.currentUser?.reload();
        setState(() {
          user = fb_auth.FirebaseAuth.instance.currentUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name updated!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // Removed Change Email flow per request

  // Try to extract the storage object path from a Supabase public/signed URL
  String? _extractMediaObjectPathFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final segments =
          uri.pathSegments; // e.g. storage/v1/object/public/media/uploads/...
      final idxObject = segments.indexOf('object');
      if (idxObject == -1 || idxObject + 3 >= segments.length) return null;
      final bucket = segments[idxObject + 2]; // 'media'
      if (bucket != 'media') return null;
      final pathSegments = segments.sublist(idxObject + 3);
      if (pathSegments.isEmpty) return null;
      return pathSegments.join('/');
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteProfilePicture(BuildContext context) async {
    final u = fb_auth.FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final supabase = Supabase.instance.client;
    String? pathToDelete;
    if (u.photoURL != null) {
      final parsed = _extractMediaObjectPathFromUrl(u.photoURL!);
      // Only allow delete if path belongs to this user's profile picture
      if (parsed != null && parsed.startsWith('profile_${u.uid}_avatar_')) {
        pathToDelete = parsed;
      }
    }

    // Best-effort delete in storage (will require a delete policy)
    if (pathToDelete != null) {
      try {
        await supabase.storage.from('media').remove([pathToDelete]);
      } on StorageException catch (_) {
        // ignore storage delete failures; we still remove the profile photo URL
      } catch (_) {}
    }

    // Remove avatar from Firebase profile
    try {
      await u.updatePhotoURL(null);
      await fb_auth.FirebaseAuth.instance.currentUser?.reload();
      setState(() {
        user = fb_auth.FirebaseAuth.instance.currentUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture removed.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleChangeProfilePicture(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final u = fb_auth.FirebaseAuth.instance.currentUser;
      if (u == null) return;
      final ext = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final file = File(picked.path);
      final supabase = Supabase.instance.client;

      // Do not attempt Supabase anonymous sign-in; rely on RLS policies

      // Upload to media bucket root with unique filename to avoid updates.
      final ts = DateTime.now().microsecondsSinceEpoch;
      final uploadedPath = 'profile_${u.uid}_avatar_$ts.$ext';
      final bytes = await file.readAsBytes();
      try {
        await supabase.storage.from('media').uploadBinary(
              uploadedPath,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false),
            );
      } on StorageException catch (e) {
        throw StorageException(
            "${e.message} (bucket=media, path=$uploadedPath)");
      }

      // Build a URL for the uploaded avatar
      // Prefer a public URL if policies allow; otherwise fall back to a 7-day signed URL.
      // Generate a signed URL (expires in 7 days). Public URL may not work if bucket isn't public.
      String avatarUrl;
      try {
        avatarUrl = await supabase.storage
            .from('media')
            .createSignedUrl(uploadedPath, 60 * 60 * 24 * 7);
      } catch (_) {
        avatarUrl = supabase.storage.from('media').getPublicUrl(uploadedPath);
      }

      await u.updatePhotoURL(avatarUrl);
      await fb_auth.FirebaseAuth.instance.currentUser?.reload();
      setState(() {
        user = fb_auth.FirebaseAuth.instance.currentUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        title: const Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blueGrey,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user?.displayName ?? "Anonymous User",
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  tooltip: "Edit Name",
                  onPressed: () => _changeNameDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(user?.email ?? "No email",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Divider(height: 30, color: Colors.white24),
            // Change Email removed
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white70),
              title: const Text("Change Profile Picture",
                  style: TextStyle(color: Colors.white)),
              onTap: () => _handleChangeProfilePicture(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.white70),
              title: const Text("Delete Profile Picture",
                  style: TextStyle(color: Colors.white)),
              onTap: () => _deleteProfilePicture(context),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.white70),
              title: const Text("My Media Uploads",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => MediaScreen()));
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ MAP HOME SCREEN ------------------
class MapHomeScreen extends StatefulWidget {
  final bool addMarkerMode;
  final Function(latLng2.LatLng) onAddDisasterMarker;
  final String? pendingDisasterType;

  const MapHomeScreen({
    Key? key,
    required this.addMarkerMode,
    required this.onAddDisasterMarker,
    this.pendingDisasterType,
  }) : super(key: key);

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  final MapController _mapController = MapController();
  Marker? _currentLocationMarker;
  final List<Marker> _disasterMarkers = [];
  bool _locating = false;
  final LocationAlertsService _locationAlertsService = LocationAlertsService();
  final OfflineModeService _offlineService = OfflineModeService();

  @override
  void initState() {
    super.initState();
    _determinePositionAndMove();
    _initializeLocationAlerts();
  }

  Future<void> _determinePositionAndMove() async {
    setState(() => _locating = true);
    try {
      // Ensure location services enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        return;
      }

      // Check permission
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
          child: const Icon(Icons.my_location,
              color: Color.fromARGB(255, 243, 33, 33), size: 36),
        );
        _locating = false;
      });
      _mapController.move(latLng, 15.0);
    } catch (e) {
      setState(() => _locating = false);
    }
  }

  Widget _buildDisasterMarkerChild(String? type) {
    if (type == null) {
      return const Icon(Icons.location_on, color: Colors.red, size: 36);
    }
    final map = {
      "Fire": "assets/icons/fire.png",
      "Riot": "assets/icons/riot.png",
      "Accident": "assets/icons/accident.png",
      "Stampede": "assets/icons/stampede.png",
    };
    final path = map[type];
    if (path == null) {
      return const Icon(Icons.location_on, color: Colors.red, size: 36);
    }
    return Image.asset(path, width: 44, height: 44, fit: BoxFit.contain);
  }

  // New: allow HomeScreen to add a disaster marker programmatically
  void addDisasterMarker(latLng2.LatLng pos, [String? type]) {
    setState(() {
      _disasterMarkers.add(
        Marker(
          point: pos,
          width: 44,
          height: 44,
          child: _buildDisasterMarkerChild(type),
        ),
      );
    });
  }

  // Update existing marker at the same location with new disaster type
  void updateDisasterMarker(latLng2.LatLng pos, String disasterType) {
    setState(() {
      // Find and update marker at the same location (within small tolerance)
      for (int i = 0; i < _disasterMarkers.length; i++) {
        final marker = _disasterMarkers[i];
        final distance = _calculateDistance(marker.point, pos);

        // If marker is within 50 meters of the position, update it
        if (distance < 0.05) {
          // ~50 meters tolerance
          _disasterMarkers[i] = Marker(
            point: pos,
            width: 44,
            height: 44,
            child: _buildDisasterMarkerChild(disasterType),
          );
          return; // Exit after updating the first matching marker
        }
      }

      // If no existing marker found, add a new one
      addDisasterMarker(pos, disasterType);
    });
  }

  // Calculate approximate distance between two points in degrees
  double _calculateDistance(latLng2.LatLng point1, latLng2.LatLng point2) {
    final latDiff = point1.latitude - point2.latitude;
    final lngDiff = point1.longitude - point2.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff);
  }

  // New: allow HomeScreen to center the map
  void moveTo(latLng2.LatLng pos, [double zoom = 15]) {
    _mapController.move(pos, zoom);
  }

  Future<void> _initializeLocationAlerts() async {
    await _locationAlertsService.initialize();
    await _locationAlertsService.startLocationMonitoring();
    await _offlineService.initialize();
  }

  @override
  void dispose() {
    _locationAlertsService.dispose();
    _offlineService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: MapHomeScreen build() called');
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latLng2.LatLng(20.5937, 78.9629),
            initialZoom: 5,
            // Pointer mode removed: do nothing on tap.
            onTap: (tapPosition, latLng) {},
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: [
              ..._disasterMarkers,
              if (_currentLocationMarker != null) _currentLocationMarker!,
            ]),
          ],
        ),
        if (_locating)
          const Center(
            child: CircularProgressIndicator(
                color: Color.fromARGB(255, 243, 33, 33)),
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 244, 4, 4),
            child: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _determinePositionAndMove,
          ),
        ),
      ],
    );
  }
}

// ------------------ HOME SCREEN ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  bool _addMarkerMode = false; // retained for UI color state but no taps
  String? _pendingDisasterType;
  XFile? _pendingMedia;
  int _selectedIndex = 0;
  final GlobalKey<_MapHomeScreenState> _mapKey =
      GlobalKey<_MapHomeScreenState>();

  // Real-time subscription for ML classification updates
  RealtimeChannel? _insightsSubscription;

  // Getter for tabs to ensure stable widget references
  List<Widget> get _tabs => [
        MapHomeScreen(
          key: _mapKey,
          addMarkerMode: _addMarkerMode,
          pendingDisasterType: _pendingDisasterType,
          onAddDisasterMarker: (latLng) {}, // pointer flow removed
        ),
        MediaScreen(),
        AboutUsScreen(onStartMap: () {
          setState(() {
            _selectedIndex = 0;
          });
        }),
        const MoreScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _insightsSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    print('DEBUG: Setting up real-time subscription...');
    _insightsSubscription = supabase
        .channel('insights_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'insights',
          // Remove filter temporarily to catch ALL updates
          callback: _handleInsightUpdate,
        )
        .subscribe((status, error) {
      print('DEBUG: Real-time subscription status: $status');
      if (error != null) {
        print('DEBUG: Subscription error: $error');
      }
    });
  }

  void _handleInsightUpdate(PostgresChangePayload payload) {
    print('DEBUG: Received real-time update!');
    print('DEBUG: Payload: ${payload.toString()}');
    print('DEBUG: Old record: ${payload.oldRecord}');
    print('DEBUG: New record: ${payload.newRecord}');

    final newRecord = payload.newRecord;
    if (newRecord.containsKey('disaster_type') &&
        newRecord.containsKey('latitude') &&
        newRecord.containsKey('longitude')) {
      final disasterType = newRecord['disaster_type'] as String?;
      final latitude = newRecord['latitude'] as double?;
      final longitude = newRecord['longitude'] as double?;

      print(
          'DEBUG: Extracted values - Type: $disasterType, Lat: $latitude, Lng: $longitude');

      if (disasterType != null && latitude != null && longitude != null) {
        print(
            'DEBUG: Processing notification for $disasterType at $latitude, $longitude');

        // Add notification for classified disaster
        notificationHistory.insert(
          0,
          AppNotification(
            title: "Disaster Classified",
            body:
                "A $disasterType has been detected at your location based on your uploaded media.",
            timestamp: DateTime.now(),
          ),
        );

        // Update map marker with classified type
        final state = _mapKey.currentState;
        if (state != null) {
          print('DEBUG: Updating map marker...');
          state.updateDisasterMarker(
              latLng2.LatLng(latitude, longitude), disasterType);
        } else {
          print('DEBUG: Map state is null!');
        }

        // Show snackbar notification
        if (mounted) {
          print('DEBUG: Showing snackbar notification...');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$disasterType detected at your location!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() {}); // Refresh notification badge
        } else {
          print('DEBUG: Widget not mounted!');
        }
      } else {
        print(
            'DEBUG: Missing required data - Type: $disasterType, Lat: $latitude, Lng: $longitude');
      }
    } else {
      print('DEBUG: Record missing required keys');
      print('DEBUG: Available keys: ${newRecord.keys.toList()}');
    }
  }

  void _showStorageError(String message) {
    notificationHistory.insert(
      0,
      AppNotification(
        title: "Upload Failed",
        body: "Storage error: $message",
        timestamp: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Storage error: $message')));
    }
  }

  void _showDbError(String message) {
    notificationHistory.insert(
      0,
      AppNotification(
        title: "Report Save Failed",
        body: "Database error: $message",
        timestamp: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Database error: $message')));
    }
  }

  // Build a human-friendly message from PostgREST errors. In some versions,
  // `e.message` can be `{}` which is not helpful, so we merge details/hint/code.
  String _formatPostgrestError(PostgrestException e) {
    final parts = <String>[];
    try {
      final dynamic msg = e.message; // may be dynamic in some SDK versions
      final msgStr = msg?.toString();
      if (msgStr != null && msgStr.trim().isNotEmpty && msgStr.trim() != '{}') {
        parts.add(msgStr);
      }
    } catch (_) {
      // ignore
    }
    final details = e.details;
    if (details is String && details.trim().isNotEmpty) {
      parts.add('details: $details');
    }
    final hint = e.hint;
    if (hint is String && hint.trim().isNotEmpty) {
      parts.add('hint: $hint');
    }
    final code = e.code;
    if (code is String && code.trim().isNotEmpty) {
      parts.add('code: $code');
    }
    // Fallback to toString if still empty
    return parts.isEmpty ? e.toString() : parts.join(' | ');
  }

  void _showGenericError(Object e) {
    notificationHistory.insert(
      0,
      AppNotification(
        title: "Report Failed",
        body: "Error: $e",
        timestamp: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _addMarkerMode = false;
      _pendingDisasterType = null;
      _pendingMedia = null;
    });
  }

  Future<String> _tryUploadWithFallbacks({
    required Uint8List bytes,
    required String ext,
    required String contentType,
  }) async {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final name = '$ts.$ext';
    try {
      await supabase.storage.from('media').uploadBinary(
            name,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      return name;
    } on StorageException catch (e) {
      throw StorageException("${e.message} (bucket=media, path=$name)");
    }
  }

  Future<void> _uploadMediaAndReport(latLng2.LatLng latLng) async {
    if (_pendingMedia == null) return;

    final file = File(_pendingMedia!.path);
    // Build a very safe object key and detect content type
    final lowerPath = _pendingMedia!.path.toLowerCase();
    String ext = 'jpg';
    String contentType = 'image/jpeg';
    if (lowerPath.endsWith('.png')) {
      ext = 'png';
      contentType = 'image/png';
    } else if (lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.jpg')) {
      ext = 'jpg';
      contentType = 'image/jpeg';
    } else if (lowerPath.endsWith('.webp')) {
      ext = 'webp';
      contentType = 'image/webp';
    } else if (lowerPath.endsWith('.heic')) {
      ext = 'heic';
      contentType = 'image/heic';
    } else if (lowerPath.endsWith('.heif')) {
      ext = 'heif';
      contentType = 'image/heif';
    } else if (lowerPath.endsWith('.mp4')) {
      ext = 'mp4';
      contentType = 'video/mp4';
    } else if (lowerPath.endsWith('.mov')) {
      ext = 'mov';
      contentType = 'video/quicktime';
    } else if (lowerPath.endsWith('.m4v')) {
      ext = 'm4v';
      contentType = 'video/x-m4v';
    } else if (lowerPath.endsWith('.3gp')) {
      ext = '3gp';
      contentType = 'video/3gpp';
    } else if (lowerPath.endsWith('.webm')) {
      ext = 'webm';
      contentType = 'video/webm';
    }
    final mediaBytes = await file.readAsBytes();

    try {
      // 1) Upload media to Storage with fallbacks for folder and session
      final uploadedPath = await _tryUploadWithFallbacks(
        bytes: mediaBytes,
        ext: ext,
        contentType: contentType,
      );

      // 2) Generate full public URL for the uploaded media
      final publicUrl =
          supabase.storage.from('media').getPublicUrl(uploadedPath);

      // Debug: Print the values to understand what's being stored
      print('DEBUG: uploadedPath = $uploadedPath');
      print('DEBUG: publicUrl = $publicUrl');

      // 3) Insert row into the 'insights' table using your schema
      await _insertInsight(
        mediaUrl: publicUrl,
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      // add success notification
      notificationHistory.insert(
        0,
        AppNotification(
          title: "Report Submitted",
          body:
              "Your media was uploaded. We'll notify you once it's classified.",
          timestamp: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        // After success, show the marker at the same position and center the map
        final state = _mapKey.currentState;
        if (state != null) {
          state.addDisasterMarker(latLng, _pendingDisasterType);
          state.moveTo(latLng, 15);
        }
      }
    } on StorageException catch (e) {
      // Storage RLS or other storage errors
      _showStorageError(e.message);
    } on PostgrestException catch (e) {
      // Database insert RLS or other PostgREST errors
      _showDbError(_formatPostgrestError(e));
    } catch (e) {
      // add error notification (storage or insert). Keep message visible to user.
      _showGenericError(e);
    } finally {
      if (mounted) {
        setState(() {
          _addMarkerMode = false;
          _pendingDisasterType = null;
          _pendingMedia = null;
        });
      }
    }
  }

  // removed _insertInsightWithFallbacks (no longer used)

  // Insert using the actual columns in your `insights` table:
  // id uuid (default), media_url text, latitude float8, longitude float8,
  // location text (optional), processed bool, disaster_type text, created_at timestamp,
  // intensity text (optional), description text (optional)
  Future<void> _insertInsight({
    required String mediaUrl,
    required double latitude,
    required double longitude,
  }) async {
    // Debug: Print what we're inserting into the database
    print('DEBUG: Inserting media_url = $mediaUrl');

    await supabase.from(kInsightsTable).insert({
      // ML will classify disaster_type later
      'media_url': mediaUrl,
      'latitude': latitude,
      'longitude': longitude,
      'processed': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Removed: _chooseDisasterTypeDialog; ML will predict disaster type.

  Future<XFile?> _chooseMediaDialog() async {
    final picker = ImagePicker();
    return showDialog<XFile?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Attach or Capture Media"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose Image from Gallery"),
              onTap: () async {
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                Navigator.of(dialogContext).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text("Choose Video from Gallery"),
              onTap: () async {
                final file =
                    await picker.pickVideo(source: ImageSource.gallery);
                Navigator.of(dialogContext).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Take Picture"),
              onTap: () async {
                final file = await picker.pickImage(source: ImageSource.camera);
                Navigator.of(dialogContext).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Take Video"),
              onTap: () async {
                final file = await picker.pickVideo(source: ImageSource.camera);
                Navigator.of(dialogContext).pop(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDisasterReportFlow() async {
    final media = await _chooseMediaDialog();
    if (media == null) return;

    // Immediately use live location; no pointer mode
    setState(() {
      _pendingMedia = media;
      _addMarkerMode = false;
    });

    try {
      // Get current location and upload the report using it
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final here = latLng2.LatLng(pos.latitude, pos.longitude);
      await _uploadMediaAndReport(here);
    } catch (e) {
      _showGenericError(e);
    }
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await fb_auth.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Widget _notificationBell(BuildContext context) {
    final count = notificationHistory.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationScreen()),
            ).then((_) => setState(() {})); // refresh badge when returning
          },
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    // Debug print to check current tab index
    print('DEBUG: Current _selectedIndex: $_selectedIndex');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E2328), // Same simple dark color
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          padding:
              const EdgeInsets.only(top: 25, left: 24, right: 24, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, color: Colors.grey, size: 30)
                      : null,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hello, ${user?.displayName ?? 'User'} 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              _notificationBell(context),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: Color(0xFFFA7070), size: 26),
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25B050), Color(0xFF1CA847)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25B050).withOpacity(0.4),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _startDisasterReportFlow();
                },
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}

// ------------------ CUSTOM NAV BAR ------------------
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const CustomBottomNavigationBar(
      {Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2328), // Simple dark color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.map_outlined, Icons.map, "Map", 0),
          _buildNavItem(
              Icons.perm_media_outlined, Icons.perm_media, "Media", 1),
          const SizedBox(width: 50), // Space for FAB
          _buildNavItem(Icons.info_outline, Icons.info, "About", 2),
          _buildNavItem(Icons.more_horiz, Icons.more_horiz, "More", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? Colors.orange : Colors.white70,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.orange : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

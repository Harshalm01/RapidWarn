import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng2;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart' show notificationHistory, AppNotification;

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
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "RapidWarn 🚨\n\nA real-time disaster alert and reporting app.\n\n"
            "Features:\n- Live location disaster reporting\n"
            "- Media uploads\n- Notifications\n- Community safety",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
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
            ListTile(
              leading: const Icon(Icons.email, color: Colors.white70),
              title: const Text("Change Email",
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                final controller = TextEditingController();
                final newEmail = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Change Email"),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: "New Email"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(controller.text),
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                );
                if (newEmail != null && newEmail.isNotEmpty) {
                  try {
                    await user?.updateEmail(newEmail);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email updated!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white70),
              title: const Text("Change Profile Picture",
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Profile picture selected! (Upload logic needed)")),
                  );
                }
              },
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

// ------------------ HOME (MAP) SCREEN ------------------
class MapHomeScreen extends StatefulWidget {
  final bool addMarkerMode;
  final Function(latLng2.LatLng) onAddDisasterMarker;
  const MapHomeScreen({
    Key? key,
    required this.addMarkerMode,
    required this.onAddDisasterMarker,
  }) : super(key: key);

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  final MapController _mapController = MapController();
  Marker? _currentLocationMarker;
  List<Marker> _localMarkers = [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _determinePositionAndMove();
  }

  Future<void> _determinePositionAndMove() async {
    setState(() => _locating = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
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
      _mapController.move(latLng, 15.0);
    } catch (e) {
      setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latLng2.LatLng(20.5937, 78.9629),
            initialZoom: 5,
            onTap: (tapPosition, latLng) {
              if (widget.addMarkerMode) {
                widget.onAddDisasterMarker(latLng);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(markers: [
              ..._localMarkers,
              if (_currentLocationMarker != null) _currentLocationMarker!,
            ]),
          ],
        ),
        if (_locating)
          const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _determinePositionAndMove,
          ),
        ),
      ],
    );
  }
}

// ------------------ MAIN HOME SCREEN ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  bool _addMarkerMode = false;
  String? _pendingDisasterType;
  XFile? _pendingMedia;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _addMarkerMode = false;
      _pendingDisasterType = null;
      _pendingMedia = null;
    });
  }

  Future<void> _uploadMediaAndReport(latLng2.LatLng latLng) async {
    if (_pendingDisasterType == null || _pendingMedia == null) return;
    final file = File(_pendingMedia!.path);
    final fileName = '${DateTime.now().toIso8601String()}.jpg';
    final mediaBytes = await file.readAsBytes();
    try {
      await supabase.storage.from('media').uploadBinary(
            fileName,
            mediaBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      final publicUrl = supabase.storage.from('media').getPublicUrl(fileName);
      await supabase.from('disasters').insert({
        'user_id': fb_auth.FirebaseAuth.instance.currentUser!.uid,
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
        'media_url': publicUrl,
        'disaster_type': _pendingDisasterType,
        'created_at': DateTime.now().toIso8601String(),
      });

      // add success notification
      notificationHistory.insert(
        0,
        AppNotification(
          title: "Report Submitted",
          body: "Your $_pendingDisasterType disaster report was uploaded.",
          timestamp: DateTime.now(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disaster reported successfully!')),
      );
    } catch (e) {
      notificationHistory.insert(
        0,
        AppNotification(
          title: "Upload Failed",
          body: "Error uploading media: $e",
          timestamp: DateTime.now(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading media: $e')),
      );
    }
    setState(() {
      _addMarkerMode = false;
      _pendingDisasterType = null;
      _pendingMedia = null;
    });
  }

  Future<void> _startDisasterReportFlow() async {
    String? selectedType;
    await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Select Disaster Type"),
          content: DropdownButtonFormField<String>(
            value: selectedType,
            items: ['Fire', 'Flood', 'Earthquake', 'Other']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              selectedType = value;
            },
            decoration: const InputDecoration(labelText: 'Disaster Type'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedType != null) {
                  Navigator.of(ctx).pop(selectedType);
                }
              },
              child: const Text("Next"),
            ),
          ],
        );
      },
    ).then((type) => selectedType = type);
    if (selectedType == null) return;
    final picker = ImagePicker();
    XFile? media = await showDialog<XFile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Media"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Photo/Video from Gallery"),
              onTap: () async {
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                Navigator.of(ctx).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo/Video"),
              onTap: () async {
                final file = await picker.pickImage(source: ImageSource.camera);
                Navigator.of(ctx).pop(file);
              },
            ),
          ],
        ),
      ),
    );
    if (media == null) return;
    setState(() {
      _pendingDisasterType = selectedType;
      _pendingMedia = media;
      _addMarkerMode = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Pointer mode enabled! Tap on the map to mark the disaster.')),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    bool isCenter = false,
    VoidCallback? onTap,
  }) {
    final bool selected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => _onItemTapped(index),
        child: isCenter
            ? Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFBFE6FB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF232B3E), size: 32),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFBFE6FB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? const Color(0xFF232B3E)
                          : const Color(0xFF8A97A8),
                      size: 28,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
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

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    final List<Widget> _tabs = [
      MapHomeScreen(
        addMarkerMode: _addMarkerMode,
        onAddDisasterMarker: (latLng) {
          if (_addMarkerMode &&
              _pendingDisasterType != null &&
              _pendingMedia != null) {
            _uploadMediaAndReport(latLng);
          }
        },
      ),
      MediaScreen(),
      const AboutUsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding:
              const EdgeInsets.only(top: 36, left: 20, right: 20, bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFFE0E7EF),
                child: user?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hello, ${user?.displayName ?? 'User'} 👋",
                      style: const TextStyle(
                        color: Color(0xFF232B3E),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          color: Color(0xFF8A97A8),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Material(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) {
                            return SizedBox(
                              height: 400,
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  const Text('Notifications',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const Divider(),
                                  Expanded(
                                    child: notificationHistory.isEmpty
                                        ? const Center(
                                            child:
                                                Text('No notifications yet.'))
                                        : ListView.builder(
                                            itemCount:
                                                notificationHistory.length,
                                            itemBuilder: (ctx, i) {
                                              final n = notificationHistory[i];
                                              return ListTile(
                                                leading: const Icon(
                                                    Icons.notifications,
                                                    color: Colors.blue),
                                                title: Text(n.title),
                                                subtitle: Text(n.body),
                                                trailing: Text(
                                                  '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Icon(Icons.notifications_none,
                            color: Color(0xFF232B3E), size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _logout,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Icon(Icons.logout,
                            color: Color(0xFF232B3E), size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: 84,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 25, 30),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(241, 239, 239, 1)
                          .withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(icon: Icons.home, index: 0),
                    _buildNavItem(icon: Icons.calendar_today, index: 1),
                    const Expanded(child: SizedBox(width: 56)),
                    _buildNavItem(icon: Icons.bar_chart, index: 2),
                    _buildNavItem(icon: Icons.person, index: 3),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              child: _buildNavItem(
                icon: Icons.add,
                index: -1,
                isCenter: true,
                onTap: _startDisasterReportFlow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_bubbles/background_bubbles.dart';
import '../main.dart';
import 'notifications_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();
  String? uploadStatus;

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _checkLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showSnack('Enable location first!');
      return false;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) {
        _showSnack('Location permission denied.');
        return false;
      }
    }
    if (p == LocationPermission.deniedForever) {
      _showSnack('Location permanently denied.');
      return false;
    }
    return true;
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.tealAccent))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Log Out',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode.value == ThemeMode.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RapidWarn'),
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : Theme.of(context).cardColor,
        elevation: 2,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()))),
          Builder(
              builder: (c) => IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => Scaffold.of(c).openEndDrawer())),
        ],
      ),
      endDrawer: Drawer(
        child: Container(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : null),
                accountName: Text(user?.displayName ?? 'Guest'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDark,
                onChanged: (on) =>
                    themeMode.value = on ? ThemeMode.dark : ThemeMode.light,
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log out'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          BubblesAnimation(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor!,
            particleColor: (isDark ? Colors.tealAccent : Colors.blueAccent)
                .withOpacity(0.3),
            particleCount: 70,
            particleRadius: 4,
          ),
          _mediaGrid(),
          if (uploadStatus != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Text(uploadStatus!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? const Color(0xFF80CBC4) : Colors.blueAccent,
        onPressed: _showUploadOptions,
        child: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _mediaGrid() {
    final isDark = themeMode.value == ThemeMode.dark;
    final stream = supabase
        .from('media_items')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (c, s) {
        final data = s.data ?? [];
        if (s.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (data.isEmpty)
          return Center(
              child: Text('No uploads yet.',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54)));

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: data.length,
          itemBuilder: (_, i) {
            final item = data[i];
            return GestureDetector(
              onLongPress: () => _showMediaCard(item),
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: isDark ? Colors.grey.shade900 : Colors.white,
                child: item['type'] == 'image'
                    ? Image.network(item['url'], fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.play_circle, size: 50)),
              ),
            );
          },
        );
      },
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick Image'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(isVideo: false);
              }),
          ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Click Image'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(isVideo: false, fromCamera: true);
              }),
          ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(isVideo: true);
              }),
        ]),
      ),
    );
  }

  Future<void> _pickAndUpload(
      {required bool isVideo, bool fromCamera = false}) async {
    if (!await _checkLocation()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? file = isVideo
        ? await picker.pickVideo(source: ImageSource.camera)
        : fromCamera
            ? await picker.pickImage(source: ImageSource.camera)
            : await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final ext = file.name.split('.').last;
    final path = '${isVideo ? 'videos' : 'images'}/${const Uuid().v4()}.$ext';

    setState(() => uploadStatus = 'Uploading...');
    try {
      final bytes = await file.readAsBytes();
      await supabase.storage.from('useruploads').uploadBinary(path, bytes);
      final url = supabase.storage.from('useruploads').getPublicUrl(path);

      await supabase.from('media_items').insert({
        'url': url,
        'type': isVideo ? 'video' : 'image',
        'created_at': DateTime.now().toIso8601String(),
        'comments': <String>[],
      });

      setState(() => uploadStatus = 'Upload done!');
      _showSnack('✅ Uploaded!');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => uploadStatus = null);
      });
    } catch (e) {
      _showSnack('❌ $e');
    }
  }

  void _showMediaCard(Map item) {
    final ctrl = TextEditingController();
    final comments = List<String>.from(item['comments'] ?? []);
    final mediaId = item['id'];
    final url = item['url'] as String;
    final isDark = themeMode.value == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .7,
        maxChildSize: .9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(children: [
                  item['type'] == 'image'
                      ? Image.network(url)
                      : const Icon(Icons.play_circle, size: 100),
                  const SizedBox(height: 12),
                  ...comments.map((c) => ListTile(
                      title: Text(c,
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white70 : Colors.black87)))),
                ]),
              ),
            ),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                    hintText: 'Add comment...',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38)),
              )),
              IconButton(
                  icon: Icon(Icons.send,
                      color: isDark ? Colors.tealAccent : Colors.blueAccent),
                  onPressed: () async {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    comments.add(text);
                    await supabase
                        .from('media_items')
                        .update({'comments': comments}).eq('id', mediaId);
                    Navigator.pop(ctx);
                  }),
            ]),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text('Delete',
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () async {
                final uri = Uri.parse(url);
                final bucketPath = Uri.decodeFull(uri.path.replaceFirst(
                    '/storage/v1/object/public/useruploads/', ''));

                try {
                  await supabase.storage
                      .from('useruploads')
                      .remove([bucketPath]); // may throw
                } catch (e) {
                  _showSnack('Storage delete failed: $e');
                  return;
                }

                await supabase.from('media_items').delete().eq('id', mediaId);
                setState(() {});
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

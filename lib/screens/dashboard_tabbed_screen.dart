import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User, FirebaseAuth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // for themeMode

final supabaseClient = supabase.Supabase.instance.client;

class DashboardTabbedScreen extends StatefulWidget {
  final User user;
  const DashboardTabbedScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<DashboardTabbedScreen> createState() => _DashboardTabbedScreenState();
}

class _DashboardTabbedScreenState extends State<DashboardTabbedScreen> {
  final picker = ImagePicker();
  bool _uploading = false;
  bool _pushEnabled = true;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.displayName ?? '';
  }

  // --- Helpers for uploads / profile photo ---
  Future<void> _changeProfilePhoto(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      Uint8List bytes = await picked.readAsBytes();
      String fileName =
          'profile_${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabaseClient.storage
          .from('useruploads')
          .uploadBinary(fileName, bytes);
      final url =
          supabaseClient.storage.from('useruploads').getPublicUrl(fileName);
      await widget.user.updatePhotoURL(url);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo updated ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo),
          title: const Text("Gallery"),
          onTap: () {
            Navigator.pop(context);
            _changeProfilePhoto(ImageSource.gallery);
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text("Camera"),
          onTap: () {
            Navigator.pop(context);
            _changeProfilePhoto(ImageSource.camera);
          },
        ),
      ]),
    );
  }

  // --- Notifications ---
  Future<void> _togglePush(bool val) async {
    setState(() => _pushEnabled = val);
    try {
      if (val) {
        await FirebaseMessaging.instance.subscribeToTopic('alerts');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('alerts');
      }
    } catch (_) {}
  }

  // --- Account actions ---
  Future<void> _sendPasswordReset() async {
    if (widget.user.email == null) return;
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: widget.user.email!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reset link sent to ${widget.user.email}")),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await widget.user.delete();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Theme',
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                if (themeMode.value == ThemeMode.system) {
                  themeMode.value = ThemeMode.light;
                } else if (themeMode.value == ThemeMode.light) {
                  themeMode.value = ThemeMode.dark;
                } else {
                  themeMode.value = ThemeMode.system;
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Overview"),
              Tab(icon: Icon(Icons.color_lens), text: "UI"),
              Tab(icon: Icon(Icons.cloud), text: "Storage"),
              Tab(icon: Icon(Icons.security), text: "Security"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _overviewTab(),
            _uiTab(),
            _storageTab(),
            _securityTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: Overview ---
  Widget _overviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  child: widget.user.photoURL == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(widget.user.displayName ?? "Guest"),
                Text(widget.user.email ?? ""),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _showPhotoOptions,
                  icon: const Icon(Icons.edit),
                  label: Text(_uploading ? "Uploading..." : "Edit Photo"),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text("Push Notifications"),
              value: _pushEnabled,
              onChanged: _togglePush,
              secondary: const Icon(Icons.notifications),
            ),
          ),
          const SizedBox(height: 12),
          _recentAlerts(),
          const SizedBox(height: 12),
          _uploadHistoryChart(),
        ],
      ),
    );
  }

  // --- TAB 2: UI ---
  Widget _uiTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Theme Mode"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                  onPressed: () => themeMode.value = ThemeMode.system,
                  child: const Text("System")),
              ElevatedButton(
                  onPressed: () => themeMode.value = ThemeMode.light,
                  child: const Text("Light")),
              ElevatedButton(
                  onPressed: () => themeMode.value = ThemeMode.dark,
                  child: const Text("Dark")),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Storage ---
  Widget _storageTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Text("Not logged in");

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabaseClient
          .from('media_items')
          .stream(primaryKey: ['id'])
          .eq('uploaded_by', user.uid)
          .order('created_at', ascending: false),
      builder: (ctx, snap) {
        final data = snap.data ?? [];
        if (data.isEmpty) return const Center(child: Text("No uploads yet."));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) => ListTile(
            leading: Image.network(data[i]['url'],
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(data[i]['category'] ?? "General"),
            subtitle: Text(data[i]['created_at'].toString()),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await supabaseClient
                    .from('media_items')
                    .delete()
                    .eq('id', data[i]['id']);
              },
            ),
          ),
        );
      },
    );
  }

  // --- TAB 4: Security ---
  Widget _securityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _sendPasswordReset,
            icon: const Icon(Icons.lock_reset),
            label: const Text("Send Password Reset"),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete Account"),
          ),
        ],
      ),
    );
  }

  // --- Recent Alerts ---
  Widget _recentAlerts() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabaseClient
          .from('media_analysis')
          .stream(primaryKey: ['file_url'])
          .order('id', ascending: false)
          .limit(10),
      builder: (ctx, snap) {
        final filtered =
            (snap.data ?? []).where((e) => e['status'] == 'unsafe').toList();
        if (filtered.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recent Alerts",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.network(filtered[i]['file_url'],
                      width: 100, height: 100, fit: BoxFit.cover),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  // --- Upload History ---
  Widget _uploadHistoryChart() {
    return FutureBuilder(
      future: supabaseClient.from('media_items').select('created_at'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 120);
        final rows = List<Map<String, dynamic>>.from(snap.data ?? []);
        final counts = <String, int>{};
        for (final r in rows) {
          final date = _parseDate(r['created_at']);
          if (date != null) {
            final key = DateFormat('MM-dd').format(date);
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
        final entries = counts.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        if (entries.isEmpty) return const Text("No uploads found.");
        final spots = List.generate(entries.length,
            (i) => FlSpot(i.toDouble(), entries[i].value.toDouble()));
        return SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

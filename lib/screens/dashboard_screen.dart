import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User, FirebaseAuth;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // for themeMode

final supabaseClient = supabase.Supabase.instance.client;

class DashboardScreen extends StatefulWidget {
  final User user;
  const DashboardScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final picker = ImagePicker();
  bool _uploading = false;

  /// Parse dates for charts
  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    return null;
  }

  /// Profile photo actions
  Future<void> _changeProfilePhoto(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    try {
      setState(() => _uploading = true);
      Uint8List fileBytes = await picked.readAsBytes();

      String fileName =
          'profile_${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabaseClient.storage.from('useruploads').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl =
          supabaseClient.storage.from('useruploads').getPublicUrl(fileName);

      await widget.user.updatePhotoURL(publicUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo updated ✅")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      await widget.user.updatePhotoURL(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo removed")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  void _previewProfilePhoto(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Change from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _changeProfilePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _changeProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Remove Photo"),
              onTap: () {
                Navigator.pop(context);
                _deleteProfilePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _userInfoCard(),
              const SizedBox(height: 20),
              _notificationsCard(),
              const SizedBox(height: 20),
              _securityCard(),
              const SizedBox(height: 20),
              _recentAlertsSection(),
              const SizedBox(height: 20),
              _uploadHistoryChart(),
              const SizedBox(height: 20),
              _profileSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 👤 Profile + Info
  Widget _userInfoCard() => Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              GestureDetector(
                onLongPress: () {
                  if (widget.user.photoURL != null) {
                    _previewProfilePhoto(widget.user.photoURL!);
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  child: widget.user.photoURL == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.user.displayName ?? 'Guest',
                  style: const TextStyle(fontSize: 18)),
              Text(widget.user.email ?? '',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _showPhotoOptions,
                icon: const Icon(Icons.edit),
                label: Text(_uploading ? "Uploading..." : "Edit Profile Photo"),
              ),
            ],
          ),
        ),
      );

  /// 🔔 Notifications
  Widget _notificationsCard() => Card(
        child: ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text("Notifications"),
          subtitle: const Text("Stay updated with latest alerts."),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Navigate to notifications screen
          },
        ),
      );

  /// 🔒 Security
  Widget _securityCard() => Card(
        child: ListTile(
          leading: const Icon(Icons.security),
          title: const Text("Security"),
          subtitle: const Text("Manage biometric / 2FA settings."),
          trailing: Switch(
            value: true,
            onChanged: (v) {
              // TODO: Enable/disable biometric login
            },
          ),
        ),
      );

  /// 🚨 Recent Alerts Section
  Widget _recentAlertsSection() => StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseClient
            .from('media_analysis')
            .stream(primaryKey: ['file_url'])
            .order('id', ascending: false)
            .limit(10),
        builder: (ctx, snap) {
          final allItems = snap.data ?? [];
          final filtered =
              allItems.where((e) => e['status'] == 'unsafe').toList();

          if (filtered.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final url = filtered[i]['file_url'] as String? ?? '';
                    if (url.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );

  /// 📈 Upload History Chart
  Widget _uploadHistoryChart() => FutureBuilder(
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
          final spots = List.generate(
            entries.length,
            (i) => FlSpot(i.toDouble(), entries[i].value.toDouble()),
          );

          if (spots.isEmpty) {
            return const Text("No uploads found.");
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Uploads Over Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) =>
                              v >= 0 && v < entries.length
                                  ? Text(entries[v.toInt()].key,
                                      style: const TextStyle(fontSize: 10))
                                  : const Text(''),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 2,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );

  /// 👤 Profile Section (full details + uploads)
  Widget _profileSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Your Profile",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Email: ${user.email ?? "Unknown"}"),
        const SizedBox(height: 8),
        Text("UID: ${user.uid}"),
        const Divider(),
        const Text("Your Uploads",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabaseClient
                .from('media_items')
                .stream(primaryKey: ['id'])
                .eq('uploaded_by', user.uid)
                .order('created_at', ascending: false),
            builder: (ctx, snap) {
              final data = snap.data ?? [];
              if (data.isEmpty) {
                return const Center(child: Text("No uploads yet."));
              }
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Image.network(
                    data[i]['url'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, _, __) =>
                        const Icon(Icons.error, color: Colors.red),
                    loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2));
                    },
                  ),
                  title: Text(data[i]['category'] ?? "General"),
                  subtitle: Text(data[i]['created_at'].toString()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

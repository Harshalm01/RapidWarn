import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng2;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentStatusScreen extends StatefulWidget {
  const CurrentStatusScreen({super.key});

  @override
  State<CurrentStatusScreen> createState() => _CurrentStatusScreenState();
}

class _CurrentStatusScreenState extends State<CurrentStatusScreen> {
  final supabase = Supabase.instance.client;
  latLng2.LatLng _osmCenter = const latLng2.LatLng(20.5937, 78.9629);
  double _zoom = 5.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool hasPermission = await _checkLocation();
    if (!hasPermission) return;

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _osmCenter = latLng2.LatLng(pos.latitude, pos.longitude);
      _zoom = 14.0;
    });
  }

  Future<bool> _checkLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p != LocationPermission.denied &&
        p != LocationPermission.deniedForever;
  }

  Widget _countsRow() => FutureBuilder(
        future: supabase.from('media_analysis').select('status'),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            );
          }
          final items = snap.data as List<dynamic>;
          final safeCnt = items.where((e) => e['status'] == 'safe').length;
          final unsafeCnt = items.where((e) => e['status'] == 'unsafe').length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statCard('Safe', safeCnt, Colors.green),
              _statCard('Unsafe', unsafeCnt, Colors.red),
            ],
          );
        },
      );

  Widget _statCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              "$label: $count",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Current Status")),
      body: Column(
        children: [
          // Map section
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _osmCenter,
                initialZoom: _zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _osmCenter,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stats section
          _countsRow(),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Map shows your location and overall safety stats.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

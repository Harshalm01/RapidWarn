import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  /// Uploads media and inserts report metadata into 'reports' table
  static Future<void> uploadDisasterReport({
    required File file,
    required String disasterType,
    required LatLng location,
  }) async {
    final fileName = '${DateTime.now().toIso8601String()}.jpg';
    final bytes = await file.readAsBytes();

    // Upload file to 'media' bucket
    await _client.storage.from('media').uploadBinary(fileName, bytes);

    // Insert metadata into 'reports' table
    await _client.from('reports').insert({
      'type': disasterType,
      'media_path': fileName,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch media files from 'media' bucket
  static Future<List<String>> fetchMediaFiles() async {
    final res = await _client.storage.from('media').list();
    return res.map((f) => f.name).toList();
  }

  /// Get public URL for a media file
  static String getMediaPublicUrl(String fileName) {
    // ✅ FIXED: no `.data` (new supabase_flutter returns String directly)
    return _client.storage.from('media').getPublicUrl(fileName);
  }
}

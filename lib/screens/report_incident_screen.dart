// lib/screens/report_incident_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final supabase = Supabase.instance.client;
  final _descController = TextEditingController();
  final picker = ImagePicker();

  File? _mediaFile;
  String? _category;
  String? _severity;
  bool _loading = false;

  // categories
  final List<String> _categories = ["Accident", "Fire", "Flood", "Other"];
  final List<String> _severities = ["Low", "Medium", "High"];

  Future<void> _pickMedia() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _mediaFile = File(picked.path));
    }
  }

  Future<Position?> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enable location first!")));
      return null;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission is required.")));
      return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitReport() async {
    if (_mediaFile == null ||
        _category == null ||
        _severity == null ||
        _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please complete all fields and upload media.")));
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload file to Supabase Storage
      final fileName =
          "incidents/${DateTime.now().millisecondsSinceEpoch}_${_mediaFile!.path.split('/').last}";
      await supabase.storage.from("uploads").upload(fileName, _mediaFile!);
      final publicUrl = supabase.storage.from("uploads").getPublicUrl(fileName);

      // Get location
      final pos = await _getLocation();
      if (pos == null) {
        setState(() => _loading = false);
        return;
      }

      // Insert into incident_reports table
      await supabase.from("incident_reports").insert({
        "category": _category,
        "severity": _severity,
        "description": _descController.text,
        "file_url": publicUrl,
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "status": "pending" // ML model will update later
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Incident reported successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error reporting incident: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Incident")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upload Media
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _mediaFile == null
                    ? const Center(
                        child: Text("Tap to upload photo/video",
                            style: TextStyle(color: Colors.white70)))
                    : Image.file(_mediaFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.toString())))
                  .toList(),
              onChanged: (val) => setState(() => _category = val),
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),

            // Severity dropdown
            DropdownButtonFormField<String>(
              value: _severity,
              items: _severities
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.toString())))
                  .toList(),
              onChanged: (val) => setState(() => _severity = val),
              decoration: const InputDecoration(labelText: "Severity"),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                  labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Submit button
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submitReport,
                    icon: const Icon(Icons.report),
                    label: const Text("Submit Report"),
                  ),
          ],
        ),
      ),
    );
  }
}

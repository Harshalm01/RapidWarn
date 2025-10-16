import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and update user location for disaster alerting
class UserLocationService {
  static final UserLocationService _instance = UserLocationService._internal();
  factory UserLocationService() => _instance;
  UserLocationService._internal();

  Timer? _locationUpdateTimer;
  Position? _lastKnownPosition;
  bool _isTracking = false;

  static const String _lastLocationUpdateKey = 'last_location_update';
  static const Duration _updateInterval =
      Duration(minutes: 5); // Update every 5 minutes

  /// Initialize location tracking service
  Future<void> initialize() async {
    await _loadLastKnownPosition();
    debugPrint('📍 UserLocationService initialized');
  }

  /// Start continuous location tracking
  Future<void> startLocationTracking() async {
    if (_isTracking) return;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      debugPrint('❌ Location permission denied');
      return;
    }

    _isTracking = true;
    debugPrint('🚀 Starting location tracking...');

    // Update location immediately
    await _updateCurrentLocation();

    // Set up periodic updates
    _locationUpdateTimer = Timer.periodic(_updateInterval, (timer) async {
      await _updateCurrentLocation();
    });

    debugPrint(
        '✅ Location tracking started with ${_updateInterval.inMinutes}min intervals');
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTracking = false;
    debugPrint('🛑 Location tracking stopped');
  }

  /// Update current location and store in Firestore
  Future<void> _updateCurrentLocation() async {
    try {
      debugPrint('📡 Getting current location...');

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 30),
      );

      _lastKnownPosition = position;
      debugPrint('📍 Location: ${position.latitude}, ${position.longitude}');

      // Store in Firestore for disaster alerting
      await _storeLocationInFirestore(position);

      // Store locally for offline access
      await _storeLocationLocally(position);
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  /// Store location in Firestore for other users to find nearby
  Future<void> _storeLocationInFirestore(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'current_latitude': position.latitude,
        'current_longitude': position.longitude,
        'location_accuracy': position.accuracy,
        'location_updated_at': FieldValue.serverTimestamp(),
        'location_services_enabled': true,
        'last_location_update': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Location stored in Firestore');
    } catch (e) {
      debugPrint('❌ Error storing location in Firestore: $e');
    }
  }

  /// Store location locally for offline access
  Future<void> _storeLocationLocally(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setInt(
          _lastLocationUpdateKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('💾 Location stored locally');
    } catch (e) {
      debugPrint('❌ Error storing location locally: $e');
    }
  }

  /// Load last known position from local storage
  Future<void> _loadLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lng = prefs.getDouble('last_longitude');

      if (lat != null && lng != null) {
        _lastKnownPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        debugPrint('📍 Loaded last known position: $lat, $lng');
      }
    } catch (e) {
      debugPrint('❌ Error loading last known position: $e');
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Get current position for immediate use
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await _checkLocationPermission()) return _lastKnownPosition;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('❌ Error getting current position: $e');
      return _lastKnownPosition;
    }
  }

  /// Store user's location when they upload media
  Future<void> storeMediaUploadLocation(
      double latitude, double longitude) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'last_known_latitude': latitude,
        'last_known_longitude': longitude,
        'last_media_upload_location': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      debugPrint('📍 Media upload location stored: $latitude, $longitude');
    } catch (e) {
      debugPrint('❌ Error storing media upload location: $e');
    }
  }

  /// Get analytics about location tracking
  Map<String, dynamic> getLocationAnalytics() {
    return {
      'is_tracking': _isTracking,
      'last_position': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
              'timestamp': _lastKnownPosition!.timestamp.toString(),
              'accuracy': _lastKnownPosition!.accuracy,
            }
          : null,
      'update_interval_minutes': _updateInterval.inMinutes,
    };
  }

  /// Cleanup resources
  void dispose() {
    stopLocationTracking();
  }

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if tracking is active
  bool get isTracking => _isTracking;
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationAlertsService {
  static final LocationAlertsService _instance =
      LocationAlertsService._internal();
  factory LocationAlertsService() => _instance;
  LocationAlertsService._internal();

  static const double DEFAULT_ALERT_RADIUS = 5000; // 5km default radius
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _locationTimer;
  Position? _lastKnownPosition;
  bool _isMonitoring = false;

  // Alert zones - disasters within these zones will trigger alerts
  final List<AlertZone> _alertZones = [];

  /// Initialize the location alerts service
  Future<void> initialize() async {
    await _initializeNotifications();
    await _loadUserAlertPreferences();
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Load user's alert preferences from Firestore
  Future<void> _loadUserAlertPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_alert_preferences')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final radius = data['alertRadius']?.toDouble() ?? DEFAULT_ALERT_RADIUS;

        // Update alert zones based on user preferences
        _updateAlertRadius(radius);
      } else {
        // Create default preferences
        await _saveUserAlertPreferences(
            DEFAULT_ALERT_RADIUS, ['fire', 'accident', 'stampede', 'riot']);
      }
    } catch (e) {
      print('Error loading alert preferences: $e');
    }
  }

  /// Save user alert preferences
  Future<void> _saveUserAlertPreferences(
      double radius, List<String> alertTypes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('user_alert_preferences')
          .doc(user.uid)
          .set({
        'alertRadius': radius,
        'alertTypes': alertTypes,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving alert preferences: $e');
    }
  }

  /// Update alert radius
  void _updateAlertRadius(double radius) {
    // Update existing alert zones with new radius
    for (var zone in _alertZones) {
      zone.radius = radius;
    }
  }

  /// Start monitoring location for nearby disasters
  Future<void> startLocationMonitoring({double? customRadius}) async {
    if (_isMonitoring) return;

    final hasPermission = await _checkLocationPermissions();
    if (!hasPermission) return;

    _isMonitoring = true;

    // Get initial position
    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('Error getting initial position: $e');
      return;
    }

    // Start periodic location checks
    _locationTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _checkForNearbyDisasters();
    });

    // Also check immediately
    await _checkForNearbyDisasters();

    print('Location monitoring started');
  }

  /// Stop location monitoring
  void stopLocationMonitoring() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isMonitoring = false;
    print('Location monitoring stopped');
  }

  /// Check location permissions
  Future<bool> _checkLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// Check for nearby disasters and send alerts
  Future<void> _checkForNearbyDisasters() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _lastKnownPosition = position;

      // Get disasters from last 24 hours within alert radius
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('insights')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final latitude = data['latitude']?.toDouble();
        final longitude = data['longitude']?.toDouble();

        if (latitude != null && longitude != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            latitude,
            longitude,
          );

          // Check if disaster is within alert radius (default 5km)
          if (distance <= DEFAULT_ALERT_RADIUS) {
            await _sendLocationAlert(data, distance, doc.id);
          }
        }
      }
    } catch (e) {
      print('Error checking for nearby disasters: $e');
    }
  }

  /// Send location-based alert notification
  Future<void> _sendLocationAlert(Map<String, dynamic> disasterData,
      double distance, String disasterId) async {
    try {
      // Check if we've already alerted about this disaster
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final alertDoc = await FirebaseFirestore.instance
          .collection('user_alerts_sent')
          .doc('${user.uid}_$disasterId')
          .get();

      if (alertDoc.exists) return; // Already sent alert for this disaster

      final type = disasterData['prediction'] ?? 'incident';
      final timestamp = disasterData['timestamp'] as Timestamp?;
      final distanceKm = (distance / 1000).toStringAsFixed(1);

      final title = _getAlertTitle(type);
      final body = _getAlertBody(type, distanceKm, timestamp);

      // Send local notification
      await _notificationsPlugin.show(
        disasterId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'location_alerts',
            'Location-Based Alerts',
            channelDescription: 'Alerts for disasters near your location',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
      );

      // Mark alert as sent
      await FirebaseFirestore.instance
          .collection('user_alerts_sent')
          .doc('${user.uid}_$disasterId')
          .set({
        'disasterId': disasterId,
        'userId': user.uid,
        'alertType': type,
        'distance': distance,
        'sentAt': FieldValue.serverTimestamp(),
      });

      print('Location alert sent for $type at ${distanceKm}km away');
    } catch (e) {
      print('Error sending location alert: $e');
    }
  }

  /// Get alert title based on disaster type
  String _getAlertTitle(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return '🔥 Fire Alert Nearby';
      case 'accident':
        return '🚗 Accident Alert Nearby';
      case 'stampede':
        return '👥 Stampede Alert Nearby';
      case 'riot':
        return '⚠️ Riot Alert Nearby';
      default:
        return '⚠️ Disaster Alert Nearby';
    }
  }

  /// Get alert body message
  String _getAlertBody(String type, String distance, Timestamp? timestamp) {
    final timeStr =
        timestamp != null ? _formatTimeAgo(timestamp.toDate()) : 'recently';

    return 'A $type was reported ${distance}km from your location $timeStr. Stay alert and avoid the area if possible.';
  }

  /// Format time ago string
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Update user alert preferences
  Future<void> updateAlertPreferences({
    double? radius,
    List<String>? alertTypes,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentPrefs = await FirebaseFirestore.instance
          .collection('user_alert_preferences')
          .doc(user.uid)
          .get();

      final currentData = currentPrefs.data() ?? {};

      await FirebaseFirestore.instance
          .collection('user_alert_preferences')
          .doc(user.uid)
          .set({
        'alertRadius':
            radius ?? currentData['alertRadius'] ?? DEFAULT_ALERT_RADIUS,
        'alertTypes': alertTypes ??
            currentData['alertTypes'] ??
            ['fire', 'accident', 'stampede', 'riot'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Reload preferences
      await _loadUserAlertPreferences();

      print('Alert preferences updated');
    } catch (e) {
      print('Error updating alert preferences: $e');
    }
  }

  /// Get current monitoring status
  bool get isMonitoring => _isMonitoring;

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Cleanup resources
  void dispose() {
    stopLocationMonitoring();
  }
}

/// Alert zone model
class AlertZone {
  final String id;
  final double latitude;
  final double longitude;
  double radius;
  final List<String> alertTypes;

  AlertZone({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.alertTypes,
  });
}

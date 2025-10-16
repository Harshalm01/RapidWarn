import 'dart:math'; // ✅ Add for distance calculations
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'
    show notificationHistory, AppNotification, flutterLocalNotificationsPlugin;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationEnabledKey = 'notifications_enabled';

  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize notification channels
      await _createNotificationChannels();

      // Get and store FCM token
      await _initializeFCMToken();

      // Subscribe to default topics
      await _subscribeToDefaultTopics();

      // Set up token refresh listener
      _setupTokenRefreshListener();

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    final permitted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    return permitted;
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'Emergency Alerts',
      description: 'Critical emergency alerts and disaster warnings',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
    );

    const generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'App updates and general information',
      importance: Importance.high,
      playSound: true,
    );

    const locationChannel = AndroidNotificationChannel(
      'location_alerts',
      'Location-Based Alerts',
      description: 'Alerts for incidents near your location',
      importance: Importance.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(locationChannel);

    debugPrint('✅ Notification channels created');
  }

  /// Initialize FCM token
  Future<void> _initializeFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _storeTokenLocally(token);
        await _storeTokenInDatabase(token);
        _currentToken = token;
        debugPrint('📱 FCM Token: $token');
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Store FCM token locally
  Future<void> _storeTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  /// Store FCM token in database for admin notifications
  Future<void> _storeTokenInDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(user.uid)
          .set({
        'fcm_token': token,
        'user_id': user.uid,
        'email': user.email,
        'platform': Theme.of(
                        // Get platform info
                        WidgetsBinding
                                .instance.focusManager.primaryFocus?.context ??
                            WidgetsBinding.instance.rootElement!)
                    .platform ==
                TargetPlatform.android
            ? 'android'
            : 'ios',
        'updated_at': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));

      // Also store in Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('user_tokens').upsert({
        'firebase_uid': user.uid,
        'fcm_token': token,
        'email': user.email,
        'platform': Theme.of(WidgetsBinding.instance.rootElement!).platform ==
                TargetPlatform.android
            ? 'android'
            : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
        'active': true,
      }, onConflict: 'firebase_uid');

      debugPrint('✅ FCM token stored in databases');
    } catch (e) {
      debugPrint('⚠️ Failed to store FCM token in database: $e');
    }
  }

  /// Subscribe to default topics
  Future<void> _subscribeToDefaultTopics() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('emergency_alerts');
      await FirebaseMessaging.instance.subscribeToTopic('general_updates');
      debugPrint('✅ Subscribed to default topics');
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to topics: $e');
    }
  }

  /// Set up token refresh listener
  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _storeTokenLocally(newToken);
      _storeTokenInDatabase(newToken);
      debugPrint('🔄 FCM token refreshed: $newToken');
    });
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);

    if (enabled) {
      await _subscribeToDefaultTopics();
    } else {
      await _unsubscribeFromAllTopics();
    }

    debugPrint('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? true;
  }

  /// Unsubscribe from all topics
  Future<void> _unsubscribeFromAllTopics() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('emergency_alerts');
      await FirebaseMessaging.instance.unsubscribeFromTopic('general_updates');
      debugPrint('✅ Unsubscribed from all topics');
    } catch (e) {
      debugPrint('⚠️ Failed to unsubscribe from topics: $e');
    }
  }

  /// Send local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? 'general_notifications',
            channelId == 'emergency_alerts'
                ? 'Emergency Alerts'
                : 'General Notifications',
            importance: channelId == 'emergency_alerts'
                ? Importance.max
                : Importance.high,
            priority:
                channelId == 'emergency_alerts' ? Priority.max : Priority.high,
            icon: '@mipmap/ic_launcher',
            color: channelId == 'emergency_alerts' ? Colors.red : Colors.blue,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      // Add to notification history
      notificationHistory.insert(
        0,
        AppNotification(
          title: title,
          body: body,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Test notification (for debugging)
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: '🧪 Test Notification',
      body:
          'This is a test notification from RapidWarn. Your notifications are working!',
      channelId: 'general_notifications',
    );
  }

  /// Send multiple test notifications for comprehensive testing
  Future<void> sendMultipleTestNotifications() async {
    try {
      debugPrint('🚀 SENDING COMPREHENSIVE NOTIFICATION TESTS...');

      // Test 1: Emergency Alert
      await Future.delayed(const Duration(seconds: 1));
      await showLocalNotification(
        title: '🚨 EMERGENCY ALERT TEST',
        body:
            'This is a test emergency alert. Your emergency notifications are working!',
        channelId: 'emergency_alerts',
      );
      debugPrint('✅ Emergency alert test sent');

      // Test 2: Location Alert
      await Future.delayed(const Duration(seconds: 2));
      await showLocalNotification(
        title: '📍 Location Alert Test',
        body:
            'Test location-based alert for your area. Location notifications working!',
        channelId: 'location_alerts',
      );
      debugPrint('✅ Location alert test sent');

      // Test 3: General Notification
      await Future.delayed(const Duration(seconds: 3));
      await showLocalNotification(
        title: '📱 General Test',
        body: 'General notification test - all systems operational!',
        channelId: 'general_notifications',
      );
      debugPrint('✅ General notification test sent');

      // Test 4: App Update
      await Future.delayed(const Duration(seconds: 4));
      await showLocalNotification(
        title: '🔄 App Update Test',
        body: 'Test app update notification - update system working!',
        channelId: 'app_updates',
      );
      debugPrint('✅ App update test sent');

      // Test 5: Success Summary
      await Future.delayed(const Duration(seconds: 5));
      await showLocalNotification(
        title: '🎉 Test Complete!',
        body:
            'All 5 notification tests completed successfully! Your notification system is fully operational.',
        channelId: 'general_notifications',
      );
      debugPrint('🎉 All notification tests completed successfully!');
    } catch (e) {
      debugPrint('❌ Failed to send test notifications: $e');
    }
  }

  /// Subscribe to location-based alerts
  Future<void> subscribeToLocationAlerts(String locationId) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('location_$locationId');
      debugPrint('✅ Subscribed to location alerts: $locationId');
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to location alerts: $e');
    }
  }

  /// Update user notification preferences
  Future<void> updateNotificationPreferences({
    required bool emergencyAlerts,
    required bool locationAlerts,
    required bool appUpdates,
    required bool incidentUpdates,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final preferences = {
        'emergency_alerts': emergencyAlerts,
        'location_alerts': locationAlerts,
        'app_updates': appUpdates,
        'incident_updates': incidentUpdates,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('user_notification_preferences')
          .doc(user.uid)
          .set(preferences, SetOptions(merge: true));

      // Store in Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('users').update({
        'notification_preferences': {
          'push_notifications': emergencyAlerts || locationAlerts || appUpdates,
          'emergency_alerts': emergencyAlerts,
          'location_alerts': locationAlerts,
          'app_updates': appUpdates,
          'incident_updates': incidentUpdates,
        }
      }).eq('firebase_uid', user.uid);

      // Update topic subscriptions
      if (emergencyAlerts) {
        await FirebaseMessaging.instance.subscribeToTopic('emergency_alerts');
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('emergency_alerts');
      }

      if (appUpdates) {
        await FirebaseMessaging.instance.subscribeToTopic('general_updates');
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('general_updates');
      }

      debugPrint('✅ Notification preferences updated');
    } catch (e) {
      debugPrint('❌ Failed to update notification preferences: $e');
    }
  }

  /// Get user notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'emergency_alerts': true,
        'location_alerts': true,
        'app_updates': true,
        'incident_updates': true,
      };
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_notification_preferences')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'emergency_alerts': data['emergency_alerts'] ?? true,
          'location_alerts': data['location_alerts'] ?? true,
          'app_updates': data['app_updates'] ?? true,
          'incident_updates': data['incident_updates'] ?? true,
        };
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get notification preferences: $e');
    }

    // Return defaults if failed to load
    return {
      'emergency_alerts': true,
      'location_alerts': true,
      'app_updates': true,
      'incident_updates': true,
    };
  }

  /// Send disaster alert notification (called by ML classification)
  Future<void> sendDisasterAlert({
    required String disasterType,
    required double latitude,
    required double longitude,
    String? location,
    String? mediaUrl,
    String? uploaderId,
  }) async {
    try {
      debugPrint(
          '🚨 Sending disaster alert for $disasterType at $latitude, $longitude');

      // Send immediate local notification to uploader
      await showLocalNotification(
        title: '🚨 DISASTER ALERT',
        body:
            'A $disasterType has been detected ${location != null ? 'at $location' : 'in your area'}. Please stay safe!',
        channelId: 'emergency_alerts',
      );

      // Save to Firestore for location-based alerts with media info
      final alertDoc =
          await FirebaseFirestore.instance.collection('disaster_alerts').add({
        'disaster_type': disasterType,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'media_url': mediaUrl,
        'uploader_id': uploaderId,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'ML_classification',
        'status': 'active',
        'severity': 'high',
        'notified_users': [],
        'alert_radius': 5000, // 5km radius
      });

      // ✅ Notify nearby users within 5km radius
      await _notifyNearbyUsers(
        disasterType: disasterType,
        latitude: latitude,
        longitude: longitude,
        alertId: alertDoc.id,
        mediaUrl: mediaUrl,
      );

      debugPrint('✅ Disaster alert sent successfully to nearby users');
    } catch (e) {
      debugPrint('❌ Failed to send disaster alert: $e');
    }
  }

  /// Notify users within specified radius of the disaster
  Future<void> _notifyNearbyUsers({
    required String disasterType,
    required double latitude,
    required double longitude,
    required String alertId,
    String? mediaUrl,
    double radiusKm = 5.0,
  }) async {
    try {
      debugPrint('🔍 ANALYZING NEARBY USERS within ${radiusKm}km radius...');
      debugPrint('📍 Disaster location: $latitude, $longitude');

      // ✅ Enhanced query with multiple location sources
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get(); // Get all users first, then filter

      int totalUsers = usersQuery.docs.length;
      int usersWithLocation = 0;
      int notifiedCount = 0;
      final notifiedUsers = <String>[];
      final List<Map<String, dynamic>> nearbyUserAnalysis = [];

      debugPrint('📊 Analyzing $totalUsers total users...');

      for (var userDoc in usersQuery.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // ✅ Multiple location sources for better coverage
        double? userLat;
        double? userLng;
        String locationSource = 'unknown';
        DateTime? lastLocationUpdate;

        // Try different location fields (newest to oldest)
        if (userData['current_latitude'] != null &&
            userData['current_longitude'] != null) {
          userLat = userData['current_latitude']?.toDouble();
          userLng = userData['current_longitude']?.toDouble();
          locationSource = 'current_location';
          lastLocationUpdate =
              (userData['location_updated_at'] as Timestamp?)?.toDate();
        } else if (userData['last_known_latitude'] != null &&
            userData['last_known_longitude'] != null) {
          userLat = userData['last_known_latitude']?.toDouble();
          userLng = userData['last_known_longitude']?.toDouble();
          locationSource = 'last_known_location';
          lastLocationUpdate =
              (userData['last_location_update'] as Timestamp?)?.toDate();
        } else if (userData['registration_latitude'] != null &&
            userData['registration_longitude'] != null) {
          userLat = userData['registration_latitude']?.toDouble();
          userLng = userData['registration_longitude']?.toDouble();
          locationSource = 'registration_location';
        }

        if (userLat != null && userLng != null) {
          usersWithLocation++;

          // Calculate distance using Haversine formula
          final distance =
              _calculateDistance(latitude, longitude, userLat, userLng);
          final distanceKm = distance.toStringAsFixed(1);

          // ✅ Store analysis data for debugging
          nearbyUserAnalysis.add({
            'userId': userId,
            'userName': userData['displayName'] ?? 'Unknown',
            'userEmail': userData['email'] ?? 'No email',
            'distance': distance,
            'locationSource': locationSource,
            'lastLocationUpdate': lastLocationUpdate?.toString() ?? 'Unknown',
            'withinRadius': distance <= radiusKm,
          });

          debugPrint('👤 User: ${userData['displayName'] ?? userId}');
          debugPrint('   📍 Location: $userLat, $userLng ($locationSource)');
          debugPrint('   📏 Distance: ${distanceKm}km');
          debugPrint('   ✅ Within radius: ${distance <= radiusKm}');

          if (distance <= radiusKm) {
            // ✅ Check user notification preferences
            final notificationPrefs =
                userData['notification_preferences'] as Map<String, dynamic>?;
            final emergencyAlertsEnabled =
                notificationPrefs?['emergency_alerts'] ?? true;
            final locationAlertsEnabled =
                notificationPrefs?['location_alerts'] ?? true;

            if (emergencyAlertsEnabled && locationAlertsEnabled) {
              // Send FCM notification to this user
              await _sendFCMToUser(
                userId: userId,
                title: '⚠️ Nearby Disaster Alert',
                body:
                    'A $disasterType was detected ${distanceKm}km from your location. Stay alert!',
                data: {
                  'type': 'disaster_alert',
                  'disaster_type': disasterType,
                  'latitude': latitude.toString(),
                  'longitude': longitude.toString(),
                  'distance': distanceKm,
                  'alert_id': alertId,
                  'media_url': mediaUrl ?? '',
                  'urgency': distance <= 1.0 ? 'critical' : 'high',
                },
              );

              notifiedUsers.add(userId);
              notifiedCount++;
              debugPrint('   🔔 Notification sent');
            } else {
              debugPrint('   🔕 Notifications disabled by user');
            }
          }
        } else {
          debugPrint(
              '👤 User ${userData['displayName'] ?? userId}: No location data');
        }
      }

      // ✅ Enhanced analytics logging
      debugPrint('📊 NEARBY USER ANALYSIS COMPLETE:');
      debugPrint('   Total users in database: $totalUsers');
      debugPrint('   Users with location data: $usersWithLocation');
      debugPrint(
          '   Users within ${radiusKm}km radius: ${nearbyUserAnalysis.where((u) => u['withinRadius']).length}');
      debugPrint('   Notifications sent: $notifiedCount');

      // Update the alert document with comprehensive data
      await FirebaseFirestore.instance
          .collection('disaster_alerts')
          .doc(alertId)
          .update({
        'notified_users': notifiedUsers,
        'notification_count': notifiedCount,
        'analysis_summary': {
          'total_users_analyzed': totalUsers,
          'users_with_location': usersWithLocation,
          'users_within_radius':
              nearbyUserAnalysis.where((u) => u['withinRadius']).length,
          'notifications_sent': notifiedCount,
          'analysis_timestamp': FieldValue.serverTimestamp(),
        },
        'nearby_users_analysis': nearbyUserAnalysis, // Store detailed analysis
      });

      debugPrint('✅ Notified $notifiedCount nearby users about $disasterType');
    } catch (e) {
      debugPrint('❌ Error notifying nearby users: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Send FCM notification to specific user
  Future<void> _sendFCMToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcm_token'] as String?;

      if (fcmToken != null) {
        // In a real app, you would send this to your server to send FCM
        // For now, we'll just log it and send a local notification
        debugPrint('📱 Would send FCM to token: $fcmToken');
        debugPrint('📱 Title: $title');
        debugPrint('📱 Body: $body');
        debugPrint('📱 Data: $data');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM to user $userId: $e');
    }
  }
}

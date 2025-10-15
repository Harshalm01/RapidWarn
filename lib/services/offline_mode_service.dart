import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OfflineModeService {
  static final OfflineModeService _instance = OfflineModeService._internal();
  factory OfflineModeService() => _instance;
  OfflineModeService._internal();

  static const String _cachedReportsKey = 'cached_reports';
  static const String _cachedUserDataKey = 'cached_user_data';
  static const String _pendingReportsKey = 'pending_reports';
  static const String _lastSyncKey = 'last_sync_timestamp';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  final List<Function> _onlineCallbacks = [];
  final List<Function> _offlineCallbacks = [];

  /// Initialize offline mode service
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    await _syncPendingReports();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    if (kDebugMode) {
      print('Connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOnline != _isOnline) {
        if (_isOnline) {
          _onConnectivityRestored();
        } else {
          _onConnectivityLost();
        }
      }
    });
  }

  /// Handle connectivity restoration
  void _onConnectivityRestored() async {
    if (kDebugMode) {
      print('Connectivity restored - syncing pending data');
    }

    // Notify callbacks
    for (var callback in _onlineCallbacks) {
      callback();
    }

    // Sync pending reports
    await _syncPendingReports();

    // Refresh cached data
    await _updateCachedData();
  }

  /// Handle connectivity loss
  void _onConnectivityLost() {
    if (kDebugMode) {
      print('Connectivity lost - switching to offline mode');
    }

    // Notify callbacks
    for (var callback in _offlineCallbacks) {
      callback();
    }
  }

  /// Cache disaster reports for offline access
  Future<void> cacheReports(List<Map<String, dynamic>> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((report) => json.encode(report)).toList();
      await prefs.setStringList(_cachedReportsKey, reportsJson);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      if (kDebugMode) {
        print('Cached ${reports.length} reports');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching reports: $e');
      }
    }
  }

  /// Get cached reports for offline viewing
  Future<List<Map<String, dynamic>>> getCachedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_cachedReportsKey) ?? [];

      return reportsJson
          .map((reportStr) {
            try {
              return Map<String, dynamic>.from(json.decode(reportStr));
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing cached report: $e');
              }
              return <String, dynamic>{};
            }
          })
          .where((report) => report.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached reports: $e');
      }
      return [];
    }
  }

  /// Save report for later sync when online
  Future<void> saveReportForLaterSync(Map<String, dynamic> reportData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReportsJson = prefs.getStringList(_pendingReportsKey) ?? [];

      // Add timestamp and unique ID for tracking
      reportData['offlineId'] =
          DateTime.now().millisecondsSinceEpoch.toString();
      reportData['createdOffline'] = true;
      reportData['pendingSyncTimestamp'] = DateTime.now().toIso8601String();

      pendingReportsJson.add(json.encode(reportData));
      await prefs.setStringList(_pendingReportsKey, pendingReportsJson);

      if (kDebugMode) {
        print('Saved report for later sync: ${reportData['offlineId']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving report for sync: $e');
      }
    }
  }

  /// Sync pending reports when connectivity is restored
  Future<void> _syncPendingReports() async {
    if (!_isOnline) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReportsJson = prefs.getStringList(_pendingReportsKey) ?? [];

      if (pendingReportsJson.isEmpty) return;

      if (kDebugMode) {
        print('Syncing ${pendingReportsJson.length} pending reports');
      }

      final successfulSyncs = <String>[];

      for (var reportJson in pendingReportsJson) {
        try {
          final reportData = Map<String, dynamic>.from(json.decode(reportJson));

          // Remove offline-specific fields before syncing
          final offlineId = reportData.remove('offlineId');
          reportData.remove('createdOffline');
          reportData.remove('pendingSyncTimestamp');

          // Add to Firestore
          await FirebaseFirestore.instance
              .collection('insights')
              .add(reportData);

          successfulSyncs.add(reportJson);

          if (kDebugMode) {
            print('Successfully synced report: $offlineId');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error syncing individual report: $e');
          }
        }
      }

      // Remove successfully synced reports
      if (successfulSyncs.isNotEmpty) {
        final remainingReports = pendingReportsJson
            .where((report) => !successfulSyncs.contains(report))
            .toList();
        await prefs.setStringList(_pendingReportsKey, remainingReports);

        if (kDebugMode) {
          print(
              'Synced ${successfulSyncs.length} reports, ${remainingReports.length} remaining');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing pending reports: $e');
      }
    }
  }

  /// Update cached data with latest from server
  Future<void> _updateCachedData() async {
    if (!_isOnline) return;

    try {
      // Cache recent reports
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('insights')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final reports = reportsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      await cacheReports(reports);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cached data: $e');
      }
    }
  }

  /// Cache user-specific data
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserDataKey, json.encode(userData));
    } catch (e) {
      if (kDebugMode) {
        print('Error caching user data: $e');
      }
    }
  }

  /// Get cached user data
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_cachedUserDataKey);

      if (userDataJson != null) {
        return Map<String, dynamic>.from(json.decode(userDataJson));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached user data: $e');
      }
    }
    return null;
  }

  /// Get pending reports count
  Future<int> getPendingReportsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReportsJson = prefs.getStringList(_pendingReportsKey) ?? [];
      return pendingReportsJson.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        return DateTime.parse(lastSyncStr);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last sync time: $e');
      }
    }
    return null;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedReportsKey);
      await prefs.remove(_cachedUserDataKey);
      await prefs.remove(_lastSyncKey);

      if (kDebugMode) {
        print('Cleared all cached data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }

  /// Clear pending reports (use with caution)
  Future<void> clearPendingReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingReportsKey);

      if (kDebugMode) {
        print('Cleared pending reports');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing pending reports: $e');
      }
    }
  }

  /// Register callback for when connectivity is restored
  void addOnlineCallback(Function callback) {
    _onlineCallbacks.add(callback);
  }

  /// Register callback for when connectivity is lost
  void addOfflineCallback(Function callback) {
    _offlineCallbacks.add(callback);
  }

  /// Remove callbacks
  void removeOnlineCallback(Function callback) {
    _onlineCallbacks.remove(callback);
  }

  void removeOfflineCallback(Function callback) {
    _offlineCallbacks.remove(callback);
  }

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  /// Get connectivity status as string
  String get connectivityStatus => _isOnline ? 'Online' : 'Offline';

  /// Force sync now (if online)
  Future<bool> forcSync() async {
    if (!_isOnline) return false;

    await _syncPendingReports();
    await _updateCachedData();
    return true;
  }

  /// Cleanup resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineCallbacks.clear();
    _offlineCallbacks.clear();
  }
}

/// Extension methods for easier offline handling
extension OfflineQuerySnapshot on QuerySnapshot {
  /// Convert to cacheable format
  List<Map<String, dynamic>> toCacheableFormat() {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}

/// Offline-aware wrapper for common operations
class OfflineAwareFirestore {
  static final OfflineModeService _offlineService = OfflineModeService();

  /// Get collection with offline fallback
  static Future<List<Map<String, dynamic>>> getCollection(
    String collectionName, {
    int limit = 50,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      if (_offlineService.isOnline) {
        Query query = FirebaseFirestore.instance.collection(collectionName);

        if (orderBy != null) {
          query = query.orderBy(orderBy, descending: descending);
        }

        query = query.limit(limit);

        final snapshot = await query.get();
        final data = snapshot.toCacheableFormat();

        // Cache the results
        if (collectionName == 'insights') {
          await _offlineService.cacheReports(data);
        }

        return data;
      } else {
        // Return cached data
        if (collectionName == 'insights') {
          return await _offlineService.getCachedReports();
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getCollection, falling back to cache: $e');
      }

      // Fallback to cached data
      if (collectionName == 'insights') {
        return await _offlineService.getCachedReports();
      }
      return [];
    }
  }

  /// Add document with offline queueing
  static Future<bool> addDocument(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      if (_offlineService.isOnline) {
        await FirebaseFirestore.instance.collection(collectionName).add(data);
        return true;
      } else {
        // Queue for later sync
        await _offlineService.saveReportForLaterSync(data);
        return false; // Indicates it was queued, not immediately saved
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding document, queueing for later: $e');
      }

      // Queue for later sync
      await _offlineService.saveReportForLaterSync(data);
      return false;
    }
  }
}

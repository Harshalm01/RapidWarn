import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../main.dart' show notificationHistory, AppNotification;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _emergencyAlerts = true;
  bool _locationAlerts = true;
  bool _appUpdates = true;
  bool _incidentUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences =
          await _notificationService.getNotificationPreferences();
      setState(() {
        _emergencyAlerts = preferences['emergency_alerts'] ?? true;
        _locationAlerts = preferences['location_alerts'] ?? true;
        _appUpdates = preferences['app_updates'] ?? true;
        _incidentUpdates = preferences['incident_updates'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load preferences');
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.updateNotificationPreferences(
        emergencyAlerts: _emergencyAlerts,
        locationAlerts: _locationAlerts,
        appUpdates: _appUpdates,
        incidentUpdates: _incidentUpdates,
      );

      _showSuccessSnackBar('Notification preferences saved!');
    } catch (e) {
      _showErrorSnackBar('Failed to save preferences');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.sendTestNotification();
    _showSuccessSnackBar('Test notification sent!');
  }

  Future<void> _sendComprehensiveTest() async {
    _showInfoSnackBar('Sending 5 test notifications over 5 seconds...');
    await _notificationService.sendMultipleTestNotifications();
    await Future.delayed(const Duration(seconds: 6));
    _showSuccessSnackBar(
        'All test notifications sent! Check your notification panel.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2028),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF1B2028),
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildNotificationSettings(),
                  const SizedBox(height: 24),
                  _buildTestSection(),
                  const SizedBox(height: 24),
                  _buildNotificationHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay Alert, Stay Safe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure your notification preferences to receive important emergency alerts.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      color: const Color(0xFF2C3E50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Types',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Emergency Alerts',
              subtitle: 'Critical emergency warnings and disaster alerts',
              icon: Icons.warning_amber_rounded,
              value: _emergencyAlerts,
              iconColor: Colors.red,
              onChanged: (value) => setState(() => _emergencyAlerts = value),
            ),
            const Divider(color: Colors.white24),
            _buildSwitchTile(
              title: 'Location-Based Alerts',
              subtitle: 'Notifications for incidents near your location',
              icon: Icons.location_on,
              value: _locationAlerts,
              iconColor: Colors.blue,
              onChanged: (value) => setState(() => _locationAlerts = value),
            ),
            const Divider(color: Colors.white24),
            _buildSwitchTile(
              title: 'Incident Updates',
              subtitle: 'Updates on incidents you\'ve reported or followed',
              icon: Icons.update,
              value: _incidentUpdates,
              iconColor: Colors.orange,
              onChanged: (value) => setState(() => _incidentUpdates = value),
            ),
            const Divider(color: Colors.white24),
            _buildSwitchTile(
              title: 'App Updates',
              subtitle: 'News, features, and general app notifications',
              icon: Icons.info_outline,
              value: _appUpdates,
              iconColor: Colors.green,
              onChanged: (value) => setState(() => _appUpdates = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      color: const Color(0xFF2C3E50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.purple.shade300),
                const SizedBox(width: 12),
                const Text(
                  'Test Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Send a test notification to make sure everything is working correctly.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendComprehensiveTest,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Send 5 Test Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return Card(
      color: const Color(0xFF2C3E50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.teal.shade300),
                const SizedBox(width: 12),
                const Text(
                  'Recent Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NotificationHistoryScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            notificationHistory.isEmpty
                ? Text(
                    'No notifications yet.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  )
                : Column(
                    children: notificationHistory
                        .take(3)
                        .map((notification) =>
                            _buildNotificationItem(notification))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.body.isNotEmpty)
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2028),
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: const Color(0xFF1B2028),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear all',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Notifications'),
                  content: const Text(
                      'Are you sure you want to clear all notification history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        notificationHistory.clear();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Notification history cleared')),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: notificationHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When you receive notifications, they will appear here.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notificationHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notificationHistory[index];
                return Card(
                  color: const Color(0xFF2C3E50),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: Icon(
                        Icons.notifications,
                        color: Colors.orange.shade300,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(notification.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: notification.body.isNotEmpty,
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Today ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

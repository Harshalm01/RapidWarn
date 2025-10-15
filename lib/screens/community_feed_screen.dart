import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Fire', 'Accident', 'Stampede', 'Riot'];
  bool _showVerifiedOnly = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2028),
      appBar: AppBar(
        title:
            const Text('Community Feed', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2028),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              if (value == 'verified') {
                setState(() {
                  _showVerifiedOnly = !_showVerifiedOnly;
                });
              } else {
                setState(() {
                  _selectedFilter = value;
                });
              }
            },
            itemBuilder: (context) => [
              ..._filters.map((filter) => PopupMenuItem(
                    value: filter,
                    child: Row(
                      children: [
                        if (_selectedFilter == filter)
                          const Icon(Icons.check,
                              color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(filter),
                      ],
                    ),
                  )),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'verified',
                child: Row(
                  children: [
                    if (_showVerifiedOnly)
                      const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text('Verified Only'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildFeedStream(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Colors.orange.withOpacity(0.3),
              checkmarkColor: Colors.orange,
              labelStyle: TextStyle(
                color: isSelected ? Colors.orange : Colors.white70,
              ),
              backgroundColor: const Color(0xFF2A2D36),
              side: BorderSide(
                color: isSelected ? Colors.orange : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedStream() {
    Query query = FirebaseFirestore.instance
        .collection('insights')
        .orderBy('timestamp', descending: true)
        .limit(50);

    // Apply filters
    if (_selectedFilter != 'All') {
      query =
          query.where('prediction', isEqualTo: _selectedFilter.toLowerCase());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading feed',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.feed, color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'All'
                      ? 'No reports in the community yet'
                      : 'No ${_selectedFilter.toLowerCase()} reports found',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to report an incident!',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildFeedItem(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> data, String docId) {
    final prediction = data['prediction'] ?? 'unknown';
    final confidence = data['confidence']?.toDouble() ?? 0.0;
    final timestamp = data['timestamp'] as Timestamp?;
    final latitude = data['latitude']?.toDouble();
    final longitude = data['longitude']?.toDouble();
    final mediaUrl = data['mediaUrl'] as String?;
    final description = data['description'] as String?;
    final isVerified = data['isVerified'] ?? false;
    final upvotes = data['upvotes'] ?? 0;
    final downvotes = data['downvotes'] ?? 0;

    // Skip if showing verified only and this isn't verified
    if (_showVerifiedOnly && !isVerified) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2A2D36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedHeader(prediction, timestamp, isVerified, confidence),
            const SizedBox(height: 12),
            if (description != null && description.isNotEmpty) ...[
              Text(
                description,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
            ],
            if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
              _buildMediaContent(mediaUrl),
              const SizedBox(height: 12),
            ],
            _buildLocationInfo(latitude, longitude),
            const SizedBox(height: 12),
            _buildFeedActions(docId, upvotes, downvotes),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedHeader(String prediction, Timestamp? timestamp,
      bool isVerified, double confidence) {
    return Row(
      children: [
        _buildDisasterIcon(prediction),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _capitalizeFirst(prediction),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isVerified)
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  if (timestamp != null)
                    Text(
                      _formatTimeAgo(timestamp.toDate()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisasterIcon(String prediction) {
    IconData iconData;
    Color iconColor;

    switch (prediction.toLowerCase()) {
      case 'fire':
        iconData = Icons.local_fire_department;
        iconColor = Colors.red;
        break;
      case 'accident':
        iconData = Icons.car_crash;
        iconColor = Colors.orange;
        break;
      case 'stampede':
        iconData = Icons.groups;
        iconColor = Colors.purple;
        break;
      case 'riot':
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.report_problem;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildMediaContent(String mediaUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.error, color: Colors.red, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return const Row(
        children: [
          Icon(Icons.location_off, color: Colors.grey, size: 16),
          SizedBox(width: 4),
          Text('Location not available',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blue, size: 16),
        const SizedBox(width: 4),
        Text(
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
          style: const TextStyle(color: Colors.blue, fontSize: 12),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showLocationOnMap(latitude, longitude),
          child: const Text(
            'View on Map',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedActions(String docId, int upvotes, int downvotes) {
    return Row(
      children: [
        _buildVoteButton(docId, true, upvotes),
        const SizedBox(width: 16),
        _buildVoteButton(docId, false, downvotes),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _shareReport(docId),
          icon: const Icon(Icons.share, color: Colors.grey, size: 16),
          label: const Text('Share', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildVoteButton(String docId, bool isUpvote, int count) {
    return GestureDetector(
      onTap: () => _voteOnReport(docId, isUpvote),
      child: Row(
        children: [
          Icon(
            isUpvote ? Icons.thumb_up : Icons.thumb_down,
            color: Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showLocationOnMap(double latitude, double longitude) {
    // This would navigate to the map view with the specific location
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location: $latitude, $longitude'),
        action: SnackBarAction(
          label: 'Open Maps',
          onPressed: () {
            // In a real app, you'd open the native maps app
            // For now, just show a message
          },
        ),
      ),
    );
  }

  Future<void> _voteOnReport(String docId, bool isUpvote) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote')),
        );
        return;
      }

      final voteField = isUpvote ? 'upvotes' : 'downvotes';
      final userVoteDoc = FirebaseFirestore.instance
          .collection('user_votes')
          .doc('${user.uid}_$docId');

      // Check if user already voted
      final existingVote = await userVoteDoc.get();
      if (existingVote.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already voted on this report')),
        );
        return;
      }

      // Add vote
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final reportRef =
            FirebaseFirestore.instance.collection('insights').doc(docId);
        final reportDoc = await transaction.get(reportRef);

        if (reportDoc.exists) {
          final currentCount = reportDoc.data()![voteField] ?? 0;
          transaction.update(reportRef, {voteField: currentCount + 1});
          transaction.set(userVoteDoc, {
            'userId': user.uid,
            'reportId': docId,
            'voteType': isUpvote ? 'upvote' : 'downvote',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${isUpvote ? 'Upvoted' : 'Downvoted'} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  void _shareReport(String docId) {
    // In a real app, you'd implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}

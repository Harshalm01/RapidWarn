import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class LikedMediaScreen extends StatelessWidget {
  const LikedMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            '⚠️ You must be logged in to view liked media.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final likedQuery = supabase
        .from('media_items')
        .stream(primaryKey: ['id']); // ✅ get all → filter in Dart

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Liked Media'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: likedQuery,
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];

          // ✅ Filter only liked by this user
          final liked = all.where((item) {
            final likedBy = item['liked_by'];
            if (likedBy is List) {
              return likedBy.contains(user.uid);
            }
            return false;
          }).toList();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (liked.isEmpty) {
            return const Center(
              child: Text(
                'No liked media yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: liked.length,
            itemBuilder: (_, i) {
              final item = liked[i];
              final url = item['url'] as String;
              final type = item['type'] as String;

              return Card(
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: type == 'image'
                          ? Image.network(url, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white70, size: 50),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

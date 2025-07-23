// lib/screens/comments_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class CommentsScreen extends StatefulWidget {
  final int mediaId;

  const CommentsScreen({super.key, required this.mediaId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final supabase = Supabase.instance.client;
  final user = FirebaseAuth.instance.currentUser;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final commentsStream = supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('media_id', widget.mediaId)
        .order('created_at', ascending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: commentsStream,
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return ListTile(
                      title: Text(
                        c['comment_text'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        c['created_at'].toString(),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.tealAccent),
                  onPressed: _addComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await supabase.from('comments').insert({
      'media_id': widget.mediaId,
      'user_id': user?.uid ?? 'anonymous',
      'comment_text': text,
    });

    _controller.clear();
  }
}

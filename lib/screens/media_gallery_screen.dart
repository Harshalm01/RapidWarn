import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaGalleryScreen extends StatelessWidget {
  const MediaGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text("Media Gallery")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('media_items')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final mediaItems = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.network(mediaItems[index]['url'], fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }
}

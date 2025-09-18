import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('media_analysis')
            .stream(primaryKey: ['file_url']).order('id', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final alerts =
              snapshot.data!.where((e) => e['status'] == 'unsafe').toList();

          if (alerts.isEmpty) {
            return const Center(child: Text("No alerts at the moment."));
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                leading: Image.network(alert['file_url'],
                    width: 50, height: 50, fit: BoxFit.cover),
                title: Text("Unsafe Content Detected"),
                subtitle: Text(alert['created_at'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

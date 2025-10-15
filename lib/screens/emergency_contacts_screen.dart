import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> personalContacts = [];
  bool isLoading = false;

  final List<EmergencyService> defaultServices = [
    EmergencyService('Police', Icons.local_police, Colors.blue, '100'),
    EmergencyService(
        'Fire Department', Icons.local_fire_department, Colors.red, '101'),
    EmergencyService('Ambulance', Icons.local_hospital, Colors.green, '108'),
    EmergencyService(
        'Disaster Helpline', Icons.support_agent, Colors.orange, '1078'),
    EmergencyService('Women Helpline', Icons.woman, Colors.purple, '1091'),
    EmergencyService('Child Helpline', Icons.child_care, Colors.pink, '1098'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPersonalContacts();
  }

  Future<void> _loadPersonalContacts() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('emergency_contacts') ?? '[]';
    final List<dynamic> contactsList = json.decode(contactsJson);

    setState(() {
      personalContacts =
          contactsList.map((json) => EmergencyContact.fromJson(json)).toList();
      isLoading = false;
    });
  }

  Future<void> _savePersonalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = json
        .encode(personalContacts.map((contact) => contact.toJson()).toList());
    await prefs.setString('emergency_contacts', contactsJson);
  }

  Future<void> _makeCall(String phoneNumber, String name) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot make call to $name'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addPersonalContact(
      String name, String phone, String relationship) {
    final newContact = EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
      relationship: relationship,
    );

    setState(() {
      personalContacts.add(newContact);
    });
    _savePersonalContacts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to emergency contacts'),
        backgroundColor: Colors.green,
      ),
    );
    return Future.value();
  }

  void _removePersonalContact(String id) {
    setState(() {
      personalContacts.removeWhere((contact) => contact.id == id);
    });
    _savePersonalContacts();
  }

  void _showAddManualContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2028),
        title: const Text(
          'Add Emergency Contact',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Relationship (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                _addPersonalContact(
                  nameController.text,
                  phoneController.text,
                  relationController.text.isEmpty
                      ? 'Emergency Contact'
                      : relationController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddManualContactDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Services Section
                  _buildSectionHeader('Emergency Services', Icons.emergency),
                  const SizedBox(height: 12),
                  ...defaultServices
                      .map((service) => _buildServiceTile(service)),

                  const SizedBox(height: 32),

                  // Personal Contacts Section
                  _buildSectionHeader(
                      'Personal Emergency Contacts', Icons.contacts),
                  const SizedBox(height: 12),

                  if (personalContacts.isEmpty)
                    _buildEmptyState()
                  else
                    ...personalContacts
                        .map((contact) => _buildPersonalContactTile(contact)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTile(EmergencyService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1B2028),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: service.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(service.icon, color: service.color),
        ),
        title: Text(
          service.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          service.number,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: service.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _makeCall(service.number, service.name),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalContactTile(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1B2028),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            contact.name[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.phone,
              style: const TextStyle(color: Colors.white70),
            ),
            if (contact.relationship.isNotEmpty)
              Text(
                contact.relationship,
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.call, color: Colors.white),
                onPressed: () => _makeCall(contact.phone, contact.name),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removePersonalContact(contact.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: const Color(0xFF1B2028),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.contact_phone,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No personal emergency contacts added',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add contacts for quick access during emergencies',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddManualContactDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyService {
  final String name;
  final IconData icon;
  final Color color;
  final String number;

  EmergencyService(this.name, this.icon, this.color, this.number);
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        relationship: json['relationship'] ?? '',
      );
}

import 'package:flutter/material.dart';

void main() {
  runApp(const PhotoContactsApp());
}

class PhotoContactsApp extends StatelessWidget {
  const PhotoContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Contacts',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
      ),
      home: const ContactsScreen(),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, String>> _contacts = [
    {'first': 'John', 'last': 'Doe', 'color': '0xFFE3F2FD'},
    {'first': 'Mary', 'last': 'Smith', 'color': '0xFFFCE4EC'},
    {'first': 'Robert', 'last': 'Johnson', 'color': '0xFFE8F5E9'},
    {'first': 'Alexandrina', 'last': 'Montgomery', 'color': '0xFFFFF3E0'},
    {'first': 'David', 'last': 'Brown', 'color': '0xFFF3E5F5'},
    {'first': 'James', 'last': 'Wilson', 'color': '0xFFE0F7FA'},
    {'first': 'Patricia', 'last': 'Davis', 'color': '0xFFEFEBE9'},
    {'first': 'Michael', 'last': 'Miller', 'color': '0xFFECEFF1'},
  ];

  void _showCallPopup(BuildContext context, Map<String, String> contact) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${contact['first']} ${contact['last']}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Initiating regular call to ${contact['first']}...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(24),
                            backgroundColor: Colors.green,
                          ),
                          child: const Icon(Icons.phone, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text('Normal Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening WhatsApp Video for ${contact['first']}...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(24),
                            backgroundColor: const Color(0xFF25D366),
                          ),
                          child: const Icon(Icons.videocam, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text('WhatsApp Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Map<String, String> contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${contact['first']}'),
          content: const Text('This will open the screen to change the photo, first name, last name, or phone number.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('EDIT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 24.0), // The absolute fix is right here!
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _showCallPopup(context, contact),
                onLongPress: () => _showEditDialog(context, contact),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(int.parse(contact['color']!)),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 4),
                        ),
                        child: Icon(Icons.person, size: 90, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact['first']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              contact['last']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
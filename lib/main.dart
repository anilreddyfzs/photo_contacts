import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Contacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (await Permission.contacts.request().isGranted) {
        List<Contact> contacts = await FlutterContacts.getAll(
          properties: ContactProperties.all,
        );

        setState(() {
          _allContacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
        
        _filterContacts();
      } else {
        setState(() {
          _errorMessage = 'Contacts permission is required to use this app.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading contacts: $e';
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((contact) {
          final name = (contact.displayName ?? '').toLowerCase();
          final String phone = contact.phones.isNotEmpty 
              ? (contact.phones.first.number ?? '').replaceAll(RegExp(r'[^\d]'), '') 
              : '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _makeNormalCall(String number) async {
    final Uri callUri = Uri.parse("tel:${number.replaceAll(RegExp(r'[^\d+]'), '')}");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final String cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    final Uri waUri = Uri.parse("whatsapp://send?phone=$cleanNumber");
    
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri);
    } else {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showActionDialog(Contact contact) {
    final String phoneNumber = contact.phones.isNotEmpty ? (contact.phones.first.number ?? '') : '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        titlePadding: const EdgeInsets.only(top: 24, bottom: 20),
        contentPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 28),
        title: Text(
          contact.displayName ?? 'No Name',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Phone Call Square Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (phoneNumber.isNotEmpty) _makeNormalCall(phoneNumber);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.call, size: 46, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(width: 24),
              // 2. Beautiful Re-engineered Genuine WhatsApp Styled Logo Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (phoneNumber.isNotEmpty) _launchWhatsApp(phoneNumber);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The solid green speech bubble base shape
                        const Icon(
                          Icons.chat_bubble, 
                          size: 48, 
                          color: Colors.green
                        ),
                        // Inner offset layer to embed a crisp white phone receiver inside the chat base
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, right: 1),
                          child: Icon(
                            Icons.call, 
                            size: 24, 
                            color: Colors.grey.shade50
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        backgroundColor: Colors.deepPurple.shade50,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Search by name or number...',
                prefixIcon: const Icon(Icons.search, size: 26),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center))
                    : _filteredContacts.isEmpty
                        ? const Center(child: Text('No contacts found', style: TextStyle(fontSize: 20, color: Colors.grey)))
                        : RefreshIndicator(
                            onRefresh: _fetchContacts,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                final thumbBytes = contact.photo?.thumbnail;
                                final hasPhoto = thumbBytes != null && thumbBytes.isNotEmpty;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showActionDialog(contact),
                                    onLongPress: () {
                                      final dynamic idValue = contact.id;
                                      if (idValue != null) {
                                        FlutterContacts.native.showEditor(idValue.toString());
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.deepPurple.shade100,
                                            backgroundImage: hasPhoto ? MemoryImage(thumbBytes) : null,
                                            child: !hasPhoto
                                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.displayName ?? 'No Name',
                                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  contact.phones.isNotEmpty ? (contact.phones.first.number ?? 'No Number') : 'No Number',
                                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
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
          ),
        ],
      ),
    );
  }
}
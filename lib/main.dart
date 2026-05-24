import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> _favoriteIds = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndFetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritesAndFetchContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _favoriteIds = prefs.getStringList('favorite_contact_ids') ?? [];
      });
    } catch (_) {}
    await _fetchContacts();
  }

  Future<void> _toggleFavorite(String contactId) async {
    setState(() {
      if (_favoriteIds.contains(contactId)) {
        _favoriteIds.remove(contactId);
      } else {
        _favoriteIds.add(contactId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_contact_ids', _favoriteIds);
    } catch (_) {}
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (await Permission.contacts.request().isGranted) {
        List<Contact> contacts = await FlutterContacts.getAll(
          properties: {
            ContactProperty.name,
            ContactProperty.phone,
            ContactProperty.photoThumbnail,
          },
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
          // FIXED LINE 125: Read property into local scope before string transformation passes
          final dynamic rawName = contact.displayName;
          final String name = (rawName ?? '').toString().toLowerCase();

          if (contact.phones.isEmpty) {
            return name.contains(query);
          }
          final dynamic rawPhone = contact.phones.first.number;
          final String phone = (rawPhone ?? '').toString().replaceAll(
            RegExp(r'[^\d]'),
            '',
          );
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _makeNormalCall(String number) async {
    final Uri callUri = Uri.parse(
      "tel:${number.replaceAll(RegExp(r'[^\d+]'), '')}",
    );
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
    final dynamic rawPhone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : '';
    final String phoneNumber = (rawPhone ?? '').toString();

    // FIXED LINE 159: Safe fallback via type conversion bounds
    final dynamic rawName = contact.displayName;
    final String contactName = (rawName ?? '').toString();

    final thumbBytes = contact.photo?.thumbnail;
    final hasPhoto = thumbBytes != null && thumbBytes.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: 280,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.deepPurple.shade50,
                  backgroundImage: hasPhoto ? MemoryImage(thumbBytes) : null,
                  child: !hasPhoto
                      ? Icon(
                          Icons.person,
                          size: 75,
                          color: Colors.deepPurple.shade200,
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  contactName.isEmpty ? 'No Name' : contactName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Phone Call Square
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (phoneNumber.isNotEmpty) {
                          _makeNormalCall(phoneNumber);
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call,
                          size: 36,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Custom Speech Bubble WhatsApp Vector Logo Layout
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (phoneNumber.isNotEmpty) {
                          _launchWhatsApp(phoneNumber);
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_rounded,
                                size: 42,
                                color: Colors.green,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Transform.rotate(
                                  angle: 0.4,
                                  child: const Icon(
                                    Icons.phone,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsListView(List<Contact> contactsList) {
    if (contactsList.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: contactsList.length,
      itemBuilder: (context, index) {
        final contact = contactsList[index];

        // FIXED LINE 313 & 317: Convert dynamic field states safely out of schema loops
        final dynamic rawId = contact.id;
        final String currentId = (rawId ?? '').toString();

        final isFav = _favoriteIds.contains(currentId);
        final thumbBytes = contact.photo?.thumbnail;
        final hasPhoto = thumbBytes != null && thumbBytes.isNotEmpty;

        final dynamic rawDisplayName = contact.displayName;
        final String displayName = (rawDisplayName ?? '').toString();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showActionDialog(contact),
            onLongPress: () {
              if (currentId.isNotEmpty) {
                FlutterContacts.native.showEditor(currentId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurple.shade100,
                    backgroundImage: hasPhoto ? MemoryImage(thumbBytes) : null,
                    child: !hasPhoto
                        ? const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isEmpty ? 'No Name' : displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phones.isNotEmpty
                              ? (contact.phones.first.number ?? 'No Number')
                              : 'No Number',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFav ? Colors.amber : Colors.grey.shade400,
                      size: 30,
                    ),
                    onPressed: () {
                      if (currentId.isNotEmpty) {
                        _toggleFavorite(currentId);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Photo Contacts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
          ),
          backgroundColor: Colors.deepPurple.shade50,
          centerTitle: true,
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            tabs: [
              Tab(icon: Icon(Icons.star_rounded, size: 26)),
              Tab(text: 'All Contacts'),
            ],
          ),
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
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: _fetchContacts,
                          child: _buildContactsListView(
                            _filteredContacts
                                .where((c) => _favoriteIds.contains(c.id ?? ''))
                                .toList(),
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: _fetchContacts,
                          child: _buildContactsListView(_filteredContacts),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

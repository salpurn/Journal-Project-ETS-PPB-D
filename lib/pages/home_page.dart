import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore.dart';
import '../services/notification_service.dart';
import 'detail_note_page.dart';
import 'user_info_page.dart';
import 'inbox_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final labelTextController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirestoreService firestoreService = FirestoreService();

  Widget customCachedImage(String imageUrl, {double? width, double? height, double? memCacheWidth}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: memCacheWidth?.toInt(),
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[100],
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  void openNoteBox() {
    titleTextController.clear();
    contentTextController.clear();
    labelTextController.clear();
    _selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Ceritain harimu!"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: labelTextController, decoration: const InputDecoration(labelText: "Label")),
                    TextField(controller: titleTextController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(controller: contentTextController, decoration: const InputDecoration(labelText: "Content"), maxLines: 3),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (pickedFile != null) setDialogState(() => _selectedImage = File(pickedFile.path));
                      },
                      child: Container(
                        height: 120, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                        child: _selectedImage == null 
                          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.orange), Text("Add Photo")])
                          : ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _isUploading ? null : () async {
                  setDialogState(() => _isUploading = true);
                  String imageUrl = "";
                  if (_selectedImage != null) {
                    imageUrl = await firestoreService.uploadImage(_selectedImage!) ?? "";
                  }
                  await firestoreService.addNote(titleTextController.text, contentTextController.text, labelTextController.text, imageUrl);
                  NotificationService.showNoteCreated(); // Contoh penggunaan notif
                  if (mounted) {
                    setDialogState(() => _isUploading = false);
                    Navigator.pop(context);
                  }
                },
                child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showInbox() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getMyInbox(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Inbox kosong")));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var invite = snapshot.data!.docs[index];
              return ListTile(
                title: Text("Undangan dari ${invite['hostEmail']}"),
                subtitle: Text("Catatan: ${invite['noteTitle']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () async {
                      await firestoreService.acceptInvitation(invite.id, invite['hostId'], invite['noteId']);
                      NotificationService.showInvitationAccepted(invite['hostEmail']);
                      Navigator.pop(context);
                    }),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => firestoreService.denyInvitation(invite.id, invite['hostId'], invite['noteId'])),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text("My Journal Gwe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.mail_outline, color: Colors.white), onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InboxPage()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "My Notes", icon: Icon(Icons.person)),
              Tab(text: "Shared with Me", icon: Icon(Icons.group)),
            ],
          ),
        ),
        drawer: _buildDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: openNoteBox,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: TabBarView(
          children: [
            _buildNoteList(firestoreService.getNotes(), isShared: false),
            _buildNoteList(firestoreService.getCollaboratedNotes(), isShared: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteList(Stream<QuerySnapshot> stream, {required bool isShared}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"), // Ini akan kasih tau kalau Permission Denied
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Kosong"));
        
        var notes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            var data = notes[index].data() as Map<String, dynamic>;
            String docId = notes[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: data['imageUrl'] != "" 
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: customCachedImage(data['imageUrl'], width: 50, height: 50))
                  : const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.notes, color: Colors.white)),
                title: Text(data['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isShared ? "Host: ${data['hostEmail']}" : data['content'] ?? '', maxLines: 1),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailNotePage(data: data, docId: docId))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.orange),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty) ? NetworkImage(user.photoURL!) : null,
                  child: (user?.photoURL == null || user!.photoURL!.isEmpty) ? const Icon(Icons.person, color: Colors.orange, size: 40) : null,
                ),
                accountName: Text(user?.displayName ?? "User"),
                accountEmail: Text(user?.email ?? "No Email"),
            ),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text("Edit Profil"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserInfoPage()))),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () => FirebaseAuth.instance.signOut()),
        ],
      ),
    );
  }
}
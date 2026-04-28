import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore.dart';
import '../services/notification_service.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final FirestoreService firestoreService = FirestoreService();
  final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Collaboration Inbox"),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Rikuesan Collab", icon: Icon(Icons.mail_outline)),
              Tab(text: "Hasil Ngajakin Collab", icon: Icon(Icons.send_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReceivedInvitations(),
            _buildSentInvitations(),
          ],
        ),
      ),
    );
  }

  // 1. Tab Undangan Masuk
  Widget _buildReceivedInvitations() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('invitations')
          .where('targetEmail', isEqualTo: currentUserEmail)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("Gak ada undangan masuk.");

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['noteTitle'] ?? 'Catatan Tanpa Judul'),
                subtitle: Text("Dari: ${data['hostEmail']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await firestoreService.acceptInvitation(
                          doc.id, data['hostId'], data['noteId'],
                        );
                        NotificationService.showInvitationAccepted(data['hostEmail']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => firestoreService.denyInvitation(
                        doc.id, data['hostId'], data['noteId'],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Tab Undangan Terkirim
  Widget _buildSentInvitations() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('invitations')
          .where('hostId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("Kamu belum ngajak siapa-siapa.");

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['targetEmail']),
              subtitle: Text("Status: ${data['status']}"),
              trailing: data['status'] == 'pending' 
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showCancelDialog(doc.id, data['noteId'], data['targetEmail']),
                  )
                : _buildStatusChip(data['status']),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'accepted' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text("Waduh Error: $error", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    ));
  }

  void _showCancelDialog(String inviteId, String noteId, String targetEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Batalin Undangan?"),
        content: Text("Yakin mau batalin buat $targetEmail?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Enggak")),
          TextButton(
            onPressed: () async {
              await firestoreService.cancelInvitation(noteId, targetEmail);
              Navigator.pop(context);
            },
            child: const Text("Ya, Batalin", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
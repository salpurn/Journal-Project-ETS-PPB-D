// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore.dart';
import '../services/notification_service.dart';

class DetailNotePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailNotePage({super.key, required this.data, required this.docId});

  @override
  State<DetailNotePage> createState() => _DetailNotePageState();
}

class _DetailNotePageState extends State<DetailNotePage> {
  final FirestoreService firestoreService = FirestoreService();
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  
  File? _editImage;
  bool _isUpdating = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.data['imageUrl'];
  }

  // Pengecekan apakah user yang login adalah pemilik (Host)
  bool get isHost => widget.data['hostId'] == currentUserUid;

  // Helper untuk Image Caching
  Widget customCachedImage(String imageUrl, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
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

  // Fungsi untuk mengundang teman (Hanya untuk Host)
  void _showInviteDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Invite Collaborator"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: "Enter friend's email",
            icon: Icon(Icons.mail_outline),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              String targetEmail = emailController.text.trim();
              if (targetEmail.isNotEmpty) {
                await firestoreService.inviteByEmail(
                  noteId: widget.docId,
                  targetEmail: targetEmail,
                  noteTitle: widget.data['title'] ?? 'Untitled',
                );
                // Trigger notifikasi sukses kirim
                await NotificationService.showInvitationSent(targetEmail);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rikuesan kamu udah kekirim ke $targetEmail!"), backgroundColor: Colors.green,),
                );
              }
            },
            child: const Text("Invite", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditBox(Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title']);
    final contentController = TextEditingController(text: currentData['content']);
    final labelController = TextEditingController(text: currentData['label']);
    _editImage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isHost ? "Edit Journal" : "Edit Collaboration"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: "Label", icon: Icon(Icons.label_important_outline)),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title", icon: Icon(Icons.title)),
                    ),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: "Content", icon: Icon(Icons.notes)),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    
                    // Container Foto
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: _editImage != null
                                ? Image.file(_editImage!, width: double.infinity, height: 180, fit: BoxFit.cover)
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                    ? customCachedImage(_currentImageUrl!, width: double.infinity, height: 180)
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                                            SizedBox(height: 8),
                                            Text("Add Photo", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                          ),
                          
                          // Tombol Hapus & Ganti (Hanya aktif jika Host atau diizinkan edit foto)
                          if (_editImage != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          _editImage = null;
                                          _currentImageUrl = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                      onPressed: () async {
                                        final pickedFile = await ImagePicker().pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 70,
                                        );
                                        if (pickedFile != null) {
                                          setDialogState(() {
                                            _editImage = File(pickedFile.path);
                                            _currentImageUrl = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_editImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final pickedFile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 70,
                                    );
                                    if (pickedFile != null) {
                                      setDialogState(() => _editImage = File(pickedFile.path));
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _isUpdating ? null : () async {
                  setDialogState(() => _isUpdating = true);
                  
                  String finalImageUrl = _currentImageUrl ?? "";
                  if (_editImage != null) {
                    finalImageUrl = await firestoreService.uploadImage(_editImage!) ?? "";
                  }

                  // Menggunakan updateNoteShared agar kolaborator juga bisa mengupdate 
                  // dokumen yang berada di dalam path koleksi Host.
                  await firestoreService.updateNoteShared(
                    widget.data['hostId'], 
                    widget.docId, 
                    {
                      'title': titleController.text,
                      'content': contentController.text,
                      'label': labelController.text,
                      'imageUrl': finalImageUrl,
                      'lastEditorId': currentUserUid, // Tambahkan ini agar sistem tahu siapa pengedit terakhir
                    }
                  );

                  setDialogState(() => _isUpdating = false);
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() => _currentImageUrl = finalImageUrl);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Journal updated!")),
                    );
                  }
                },
                child: _isUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String createdStr = "Unknown";
    if (widget.data['createdAt'] != null) {
      DateTime dt = (widget.data['createdAt'] as Timestamp).toDate();
      createdStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    String? modifiedStr;
    if (widget.data['updatedAt'] != null) {
      DateTime dt = (widget.data['updatedAt'] as Timestamp).toDate();
      modifiedStr = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    // --- PERBAIKAN LOGIKA WARNA & COLLABORATOR TEXT DI SINI ---
    final String? lastEditorId = widget.data['lastEditorId'];
    Color contentColor = (lastEditorId != null && lastEditorId != currentUserUid) 
        ? Colors.blueGrey 
        : Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Isi Jurnal"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (isHost)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: _showInviteDialog,
              tooltip: "Invite Friend",
            ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _openEditBox(widget.data)),
          if (isHost)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _showDeleteDialog(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isHost)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group_outlined, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text("Shared by: ${(widget.data['hostEmail'] == null || widget.data['hostEmail'].isEmpty) ? 'You' : widget.data['hostEmail']}", 
                            style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Text(
                    widget.data['label']?.toUpperCase() ?? 'GENERAL',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.data['title'] ?? 'Untitled',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: customCachedImage(_currentImageUrl!, width: double.infinity),
                      ),
                    ),
                  
                  // Bagian Text Content & Info Kolaborator
                  if (lastEditorId != null && lastEditorId != currentUserUid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "(Edited by collaborator)",
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ),
                  Text(
                    widget.data['content'] ?? '',
                    style: TextStyle(
                      fontSize: 16, 
                      height: 1.5, 
                      color: contentColor,
                      fontWeight: contentColor == Colors.blueGrey ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                if (modifiedStr != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Last Modified:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(modifiedStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange)),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Created at:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(createdStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Jurnal"),
        content: const Text("Yakin nih? Gabisa dibalikin lagi loh."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await firestoreService.deleteNote(widget.docId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to Home
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
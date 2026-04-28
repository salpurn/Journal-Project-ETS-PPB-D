import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final String? email = FirebaseAuth.instance.currentUser!.email;
  
  late final CollectionReference notes = 
      FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');

  Future<void> addNote(String title, String content, String label, String imageUrl) {
    return notes.add({
      'title': title,
      'content': content,
      'label': label,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
      'hostId': uid,
      'hostEmail': email,
      'collaborators': [], 
      'pendingRequests': [], 
    });
  }

  Stream<QuerySnapshot> getNotes() {
    return notes.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getCollaboratedNotes() {
    return FirebaseFirestore.instance
        .collectionGroup('notes')
        .where('collaborators', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> inviteByEmail({required String noteId, required String targetEmail, required String noteTitle}) async {
    await notes.doc(noteId).update({
      'pendingRequests': FieldValue.arrayUnion([targetEmail])
    });

    await FirebaseFirestore.instance.collection('invitations').add({
      'noteId': noteId,
      'noteTitle': noteTitle,
      'hostId': uid,
      'hostEmail': email,
      'targetEmail': targetEmail,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getMyInbox() {
    return FirebaseFirestore.instance
        .collection('invitations')
        .where('targetEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptInvitation(String invitationId, String hostId, String noteId) async {
    await FirebaseFirestore.instance.collection('invitations').doc(invitationId).update({'status': 'accepted'});
    await FirebaseFirestore.instance.collection('users').doc(hostId).collection('notes').doc(noteId).update({
      'collaborators': FieldValue.arrayUnion([uid]),
      'pendingRequests': FieldValue.arrayRemove([email])
    });
  }

  Future<void> denyInvitation(String invitationId, String hostId, String noteId) async {
    await FirebaseFirestore.instance.collection('invitations').doc(invitationId).update({'status': 'rejected'});
    await FirebaseFirestore.instance.collection('users').doc(hostId).collection('notes').doc(noteId).update({
      'pendingRequests': FieldValue.arrayRemove([email])
    });
  }

  Future<void> cancelInvitation(String noteId, String targetEmail) async {
    await notes.doc(noteId).update({'pendingRequests': FieldValue.arrayRemove([targetEmail])});
    final inviteQuery = await FirebaseFirestore.instance.collection('invitations')
        .where('noteId', isEqualTo: noteId).where('targetEmail', isEqualTo: targetEmail).get();
    for (var doc in inviteQuery.docs) { await doc.reference.delete(); }
  }

  Future<void> updateNoteShared(String hostId, String docId, Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('users').doc(hostId).collection('notes').doc(docId).update({
      ...data,
      'updatedAt': Timestamp.now(),
      'lastEditorId': uid,
    });
  }

  Future<void> deleteNote(String id) => notes.doc(id).delete();

  Future<String?> uploadImage(File imageFile, {String? title, String? label}) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('journal_images').child(uid).child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) { return null; }
  }
}
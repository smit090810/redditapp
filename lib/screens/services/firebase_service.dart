import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'auth_service.dart'; // Import your existing auth service

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService =
      AuthService(); // Use your existing auth service

  // Auth methods - use your existing AuthService
  AuthService get auth => _authService;

  // User methods
  Future<void> createUserProfile(
      String uid, String username, String phoneNumber) {
    return _firestore.collection('users').doc(uid).set({
      'username': username,
      'phoneNumber': phoneNumber,
      'karma': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  // Community methods
  Future<DocumentReference> createCommunity(
      String name, String description, String userId) {
    return _firestore.collection('communities').add({
      'name': name,
      'description': description,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'members': 1,
    });
  }

  Stream<QuerySnapshot> getCommunities() {
    return _firestore
        .collection('communities')
        .orderBy('members', descending: true)
        .snapshots();
  }

  // Post methods
  Future<DocumentReference> createPost(
      String title, String content, String communityId, String userId,
      [String? mediaUrl]) {
    return _firestore.collection('posts').add({
      'title': title,
      'content': content,
      'communityId': communityId,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'downvotes': 0,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    });
  }

  Stream<QuerySnapshot> getPostsForCommunity(String communityId) {
    return _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Comment methods
  Future<DocumentReference> addComment(
      String postId, String content, String userId) {
    return _firestore.collection('comments').add({
      'postId': postId,
      'content': content,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'downvotes': 0,
    });
  }

  Stream<QuerySnapshot> getCommentsForPost(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Storage methods - Fixed method using Uint8List
  Future<String> uploadMedia(String path, List<int> fileBytes) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(
        Uint8List.fromList(fileBytes),
        SettableMetadata(contentType: 'image/jpeg'), // Specify the content type
      );

      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        throw Exception('Upload failed: ${uploadTask.state}');
      }
    } catch (e) {
      print('Error uploading media: $e');
      throw e;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

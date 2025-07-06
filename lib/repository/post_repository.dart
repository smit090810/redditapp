import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/services/firebase_service.dart';
import 'dart:typed_data';

class PostRepository {
  final FirebaseService _firebaseService = FirebaseService();

  Future<DocumentReference> createPost(
      String title, String content, String communityId, String userId,
      [Uint8List? mediaBytes]) async {
    String? mediaUrl;
    if (mediaBytes != null) {
      final path = 'posts/$userId/${DateTime.now().millisecondsSinceEpoch}';
      mediaUrl = await _firebaseService.uploadMedia(path, mediaBytes);
    }
    return _firebaseService.createPost(
        title, content, communityId, userId, mediaUrl);
  }

  Stream<QuerySnapshot> getPostsForCommunity(String communityId) {
    return _firebaseService.getPostsForCommunity(communityId);
  }

  Future<DocumentReference> addComment(
      String postId, String content, String userId) {
    return _firebaseService.addComment(postId, content, userId);
  }

  Stream<QuerySnapshot> getCommentsForPost(String postId) {
    return _firebaseService.getCommentsForPost(postId);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/services/firebase_service.dart';

class CommunityRepository {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> createCommunity(String name, String description, String userId) {
    return _firebaseService.createCommunity(name, description, userId);
  }

  Stream<QuerySnapshot> getCommunities() {
    return _firebaseService.getCommunities();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/services/firebase_service.dart';
import '../screens/services/auth_service.dart';

class UserRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  // Get current user
  User? getCurrentUser() {
    return _authService.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Create user profile after phone authentication
  Future<void> createUserProfile(String username, String phoneNumber) async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _firebaseService.createUserProfile(
          currentUser.uid, username, phoneNumber);
    } else {
      throw Exception('No authenticated user found');
    }
  }

  // Sign out
  Future<void> signOut() {
    return _authService.signOut();
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _firebaseService.getUserProfile(uid);
  }

  // Check if user profile exists
  Future<bool> userProfileExists() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final docSnapshot =
          await _firebaseService.getUserProfile(currentUser.uid);
      return docSnapshot.exists;
    }
    return false;
  }
}

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Add email to a phone auth account
  Future<void> linkEmailToAccount(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create email credential
        AuthCredential emailCredential =
            EmailAuthProvider.credential(email: email, password: password);

        // Link email to the current phone auth account
        await user.linkWithCredential(emailCredential);
        print("Email linked successfully: $email");
      } else {
        throw FirebaseAuthException(
            code: 'no-user', message: 'No user is currently signed in.');
      }
    } catch (e) {
      print("Error linking email: $e");
      throw e;
    }
  }

  // Update email for an existing user - for phone auth users
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print("Attempting to update email to: $newEmail");
        await user.verifyBeforeUpdateEmail(newEmail);
        print("Verification email sent to: $newEmail");
        return;
      } else {
        throw FirebaseAuthException(
            code: 'no-user', message: 'No user is currently signed in.');
      }
    } catch (e) {
      print("Error updating email: $e");
      throw e;
    }
  }

  // Re-authenticate a user with email and password
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create a credential
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);

        // Re-authenticate
        await user.reauthenticateWithCredential(credential);
        print("User re-authenticated successfully");
      } else {
        throw FirebaseAuthException(
            code: 'no-user', message: 'No user is currently signed in.');
      }
    } catch (e) {
      print("Error re-authenticating user: $e");
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

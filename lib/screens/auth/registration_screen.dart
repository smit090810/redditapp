import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/auth/phone_input_widget.dart';
import '../widgets/auth/otp_verification_widget.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _verificationId = '';
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendOTP(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _authService.verifyOTP(
            verificationId: _verificationId,
            smsCode: credential.smsCode ?? '',
          );
          _createUserProfile();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
          setState(() {
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP(String otp) async {
    if (otp.length < 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.verifyOTP(
        verificationId: _verificationId,
        smsCode: otp,
      );

      if (credential.user != null) {
        await _createUserProfile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Create user profile in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'username': _usernameController.text,
          'phoneNumber': _phoneController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update display name in Firebase Auth
        await user.updateDisplayName(_nameController.text);

        _navigateToHome();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create profile: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    // Navigate to home screen after successful registration
    // For now, just show a success message and pop back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration successful!')),
    );
    Navigator.pop(context); // Go back to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    _codeSent ? 'Verify Your Phone' : 'Create Account',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),

                  // Subtitle
                  Text(
                    _codeSent
                        ? 'We\'ve sent a verification code to ${_phoneController.text}'
                        : 'Join the Reddit Clone community',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32.0),

                  // Registration Form or OTP Input based on state
                  if (!_codeSent) ...[
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: 16.0),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: 16.0),

                    // Phone Field
                    PhoneInputWidget(
                      controller: _phoneController,
                      onChanged: (value) {},
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: 24.0),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('CONTINUE', style: TextStyle(fontSize: 16.0)),
                    ),
                  ] else ...[
                    OTPVerificationWidget(
                      controller: _otpController,
                      onCompleted: _verifyOTP,
                      isLoading: _isLoading,
                    ),
                    SizedBox(height: 16.0),
                    TextButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: Text('Resend Code'),
                    ),
                    SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _verifyOTP(_otpController.text),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('VERIFY', style: TextStyle(fontSize: 16.0)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

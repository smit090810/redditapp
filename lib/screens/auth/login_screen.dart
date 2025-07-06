import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/auth/phone_input_widget.dart';
import '../widgets/auth/otp_verification_widget.dart';
import 'registration_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _verificationId = '';
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Format the phone number correctly for Firebase
    String phoneNumber = _phoneController.text.trim();

    // If the phone number doesn't start with '+', add the Indian country code
    if (!phoneNumber.startsWith('+')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '+91${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+91$phoneNumber';
      }
    }

    try {
      await _authService.sendOTP(
        phoneNumber: phoneNumber, // Use the formatted phone number
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await _authService.verifyOTP(
            verificationId: _verificationId,
            smsCode: credential.smsCode ?? '',
          );
          _navigateToHome();
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
        _navigateToHome();
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

  void _navigateToHome() {
    // Replace current screen with HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo or Image
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.forum_outlined,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.0),

                  // Title
                  Text(
                    _codeSent ? 'Verify Your Phone' : 'Welcome Back',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.0),

                  // Subtitle
                  Text(
                    _codeSent
                        ? 'We\'ve sent a verification code to ${_phoneController.text}'
                        : 'Sign in to continue to Reddit Clone',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48.0),

                  // Phone Input or OTP Input based on state
                  if (!_codeSent) ...[
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

                  SizedBox(height: 32.0),

                  // Registration option
                  if (!_codeSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?"),
                        TextButton(
                          onPressed: _navigateToRegistration,
                          child: Text('Register'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

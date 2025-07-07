import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'settings_base_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _email = user.email;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                try {
                  // Reauthenticate user
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);

                    // Change password
                    await user.updatePassword(newPasswordController.text);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password updated successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmail() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    if (_email != null) {
      emailController.text = _email!;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password for Verification',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Reauthenticate user
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);

                    // Update email
                    await user.updateEmail(emailController.text);

                    // Update email in Firestore too
                    await _firestore.collection('users').doc(user.uid).update({
                      'email': emailController.text,
                    });

                    setState(() {
                      _email = emailController.text;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email updated successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Warning: This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter Password to Confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  // Reauthenticate user
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);

                    // Delete from Firestore first
                    String uid = user.uid;
                    await _firestore.collection('users').doc(uid).delete();

                    // Delete user account
                    await user.delete();

                    Navigator.pop(context);
                    await _authService.signOut();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child:
                  Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Account Settings',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              _buildSection(
                title: 'Account Information',
                children: [
                  _buildItem(
                    title: 'Email',
                    subtitle: _email ?? 'No email set',
                    onTap: _changeEmail,
                  ),
                  _buildItem(
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: _changePassword,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Account Management',
                children: [
                  _buildItem(
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    onTap: _deleteAccount,
                    isDestructive: true,
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right),
    );
  }
}

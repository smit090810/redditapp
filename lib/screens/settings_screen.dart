import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './services/auth_service.dart';
import './widgets/custom_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'English';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hasEmail = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _loadUserEmail();
  }

  Future<void> _loadUserSettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            _darkMode = userDoc.data()?['darkMode'] ?? false;
            _notifications = userDoc.data()?['notifications'] ?? true;
            _language = userDoc.data()?['language'] ?? 'English';
          });
        }
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error loading settings: ${e.toString()}');
    }
  }

  Future<void> _loadUserEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _emailController.text = user.email ?? '';
          _hasEmail = user.email != null && user.email!.isNotEmpty;
        });
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error loading email: ${e.toString()}');
    }
  }

  Future<void> _updateEmail() async {
    try {
      if (_emailController.text.isEmpty) {
        showCustomSnackBar(context, 'Please enter an email address');
        return;
      }

      if (_hasEmail) {
        // If user already has an email, we need to re-authenticate before updating
        if (_passwordController.text.isEmpty) {
          showCustomSnackBar(
              context, 'Please enter your password to update email');
          return;
        }

        // Re-authenticate user before changing email
        await _authService.reauthenticateUser(
            _auth.currentUser!.email!, _passwordController.text);

        // Update email
        await _authService.updateEmail(_emailController.text);

        showCustomSnackBar(context, 'Email updated successfully');
      } else {
        // For users adding email for the first time, link it with a password
        if (_passwordController.text.isEmpty) {
          showCustomSnackBar(
              context, 'Please create a password to link with your email');
          return;
        }

        // Link email to the account
        await _authService.linkEmailToAccount(
            _emailController.text, _passwordController.text);

        setState(() {
          _hasEmail = true;
        });

        showCustomSnackBar(context, 'Email added successfully');
      }

      // Clear password field
      _passwordController.clear();
    } catch (e) {
      showCustomSnackBar(context,
          'Error ${_hasEmail ? 'updating' : 'adding'} email: ${e.toString()}');
    }
  }

  Future<void> _updateSettings(String setting, dynamic value) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          setting: value,
        });

        // Update local state
        setState(() {
          switch (setting) {
            case 'darkMode':
              _darkMode = value;
              break;
            case 'notifications':
              _notifications = value;
              break;
            case 'language':
              _language = value;
              break;
          }
        });

        showCustomSnackBar(context, '$setting updated successfully');
      }
    } catch (e) {
      showCustomSnackBar(context, 'Error updating $setting: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account settings section
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Email settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasEmail ? 'Update Email' : 'Add Email',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasEmail
                          ? 'Password (required to update email)'
                          : 'Create Password (to link with email)',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter password',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateEmail,
                        child: Text(_hasEmail ? 'Update Email' : 'Add Email'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App settings section
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dark mode toggle
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (bool value) {
                _updateSettings('darkMode', value);
              },
            ),

            // Notifications toggle
            SwitchListTile(
              title: const Text('Notifications'),
              value: _notifications,
              onChanged: (bool value) {
                _updateSettings('notifications', value);
              },
            ),

            // Language dropdown
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_language),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog();
              },
            ),

            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _authService.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateSettings('language', 'English');
                  },
                ),
                ListTile(
                  title: const Text('Spanish'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateSettings('language', 'Spanish');
                  },
                ),
                ListTile(
                  title: const Text('French'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateSettings('language', 'French');
                  },
                ),
                ListTile(
                  title: const Text('German'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateSettings('language', 'German');
                  },
                ),
                ListTile(
                  title: const Text('Chinese'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateSettings('language', 'Chinese');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

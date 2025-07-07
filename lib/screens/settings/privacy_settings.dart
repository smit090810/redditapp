import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_base_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProfilePublic = true;
  bool _showActiveStatus = true;
  bool _allowDirectMessages = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _isProfilePublic = data['isProfilePublic'] ?? true;
            _showActiveStatus = data['showActiveStatus'] ?? true;
            _allowDirectMessages = data['allowDirectMessages'] ?? true;
          });
        } else {
          // Create default privacy settings
          await _firestore.collection('users').doc(user.uid).update({
            'isProfilePublic': true,
            'showActiveStatus': true,
            'allowDirectMessages': true,
          });
        }
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacySetting(String setting, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          setting: value,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setting updated')),
        );
      }
    } catch (e) {
      print('Error updating privacy setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
      // Revert the toggle if there was an error
      setState(() {
        switch (setting) {
          case 'isProfilePublic':
            _isProfilePublic = !_isProfilePublic;
            break;
          case 'showActiveStatus':
            _showActiveStatus = !_showActiveStatus;
            break;
          case 'allowDirectMessages':
            _allowDirectMessages = !_allowDirectMessages;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Privacy & Safety',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              _buildSection(
                title: 'Profile Privacy',
                children: [
                  SwitchListTile(
                    title: Text('Public Profile'),
                    subtitle: Text('Make your profile visible to everyone'),
                    value: _isProfilePublic,
                    onChanged: (value) {
                      setState(() {
                        _isProfilePublic = value;
                      });
                      _updatePrivacySetting('isProfilePublic', value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Show Active Status'),
                    subtitle: Text('Let others know when you are online'),
                    value: _showActiveStatus,
                    onChanged: (value) {
                      setState(() {
                        _showActiveStatus = value;
                      });
                      _updatePrivacySetting('showActiveStatus', value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Communication Privacy',
                children: [
                  SwitchListTile(
                    title: Text('Allow Direct Messages'),
                    subtitle: Text('Let people message you directly'),
                    value: _allowDirectMessages,
                    onChanged: (value) {
                      setState(() {
                        _allowDirectMessages = value;
                      });
                      _updatePrivacySetting('allowDirectMessages', value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Data & Privacy',
                children: [
                  ListTile(
                    title: Text('Manage Data'),
                    subtitle: Text('Download or delete your data'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      _showDataManagementOptions();
                    },
                  ),
                  ListTile(
                    title: Text('Blocked Accounts'),
                    subtitle: Text('Manage accounts you\'ve blocked'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _BlockedAccountsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
    );
  }

  void _showDataManagementOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Download Your Data'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Data download request submitted. You\'ll receive an email when it\'s ready.')),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Your Data',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDataDeletion();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDataDeletion() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Your Data'),
          content: Text(
              'This will delete all your data except your account. Your posts and comments will remain but will be anonymized. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Data deletion process started. This may take up to 30 days to complete.')),
                );
              },
              child:
                  Text('Delete My Data', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
        Divider(),
      ],
    );
  }
}

class _BlockedAccountsScreen extends StatefulWidget {
  @override
  _BlockedAccountsScreenState createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<_BlockedAccountsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          List<dynamic> blockedIds = data['blockedUsers'] ?? [];

          // Fetch details for each blocked user
          List<Map<String, dynamic>> blockedDetails = [];

          for (String id in List<String>.from(blockedIds)) {
            try {
              final blockedUserDoc =
                  await _firestore.collection('users').doc(id).get();
              if (blockedUserDoc.exists) {
                Map<String, dynamic> userData =
                    blockedUserDoc.data() as Map<String, dynamic>;
                blockedDetails.add({
                  'id': id,
                  'username': userData['username'] ?? 'Unknown user',
                  'profileImageUrl': userData['profileImageUrl'],
                });
              }
            } catch (e) {
              print('Error fetching blocked user $id: $e');
            }
          }

          setState(() {
            _blockedUsers = blockedDetails;
          });
        }
      }
    } catch (e) {
      print('Error loading blocked users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          List<dynamic> blockedIds = data['blockedUsers'] ?? [];
          blockedIds.remove(userId);

          await _firestore.collection('users').doc(user.uid).update({
            'blockedUsers': blockedIds,
          });

          setState(() {
            _blockedUsers.removeWhere((user) => user['id'] == userId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User unblocked')),
          );
        }
      }
    } catch (e) {
      print('Error unblocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unblocking user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Accounts'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Blocked Users',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'You haven\'t blocked anyone yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profileImageUrl'] != null
                            ? NetworkImage(user['profileImageUrl'])
                            : null,
                        child: user['profileImageUrl'] == null
                            ? Text(user['username'][0].toUpperCase())
                            : null,
                      ),
                      title: Text(user['username']),
                      trailing: TextButton(
                        onPressed: () => _unblockUser(user['id']),
                        child: Text('Unblock'),
                      ),
                    );
                  },
                ),
    );
  }
}

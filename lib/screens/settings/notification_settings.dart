import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_base_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _commentReplies = true;
  bool _postReplies = true;
  bool _upvotes = false;
  bool _messages = true;
  bool _newFollowers = true;
  bool _communityUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final notificationDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .get();

        if (notificationDoc.exists) {
          Map<String, dynamic> data =
              notificationDoc.data() as Map<String, dynamic>;

          setState(() {
            _pushEnabled = data['pushEnabled'] ?? true;
            _emailEnabled = data['emailEnabled'] ?? true;
            _commentReplies = data['commentReplies'] ?? true;
            _postReplies = data['postReplies'] ?? true;
            _upvotes = data['upvotes'] ?? false;
            _messages = data['messages'] ?? true;
            _newFollowers = data['newFollowers'] ?? true;
            _communityUpdates = data['communityUpdates'] ?? true;
          });
        } else {
          // Create default notification settings
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('notifications')
              .set({
            'pushEnabled': true,
            'emailEnabled': true,
            'commentReplies': true,
            'postReplies': true,
            'upvotes': false,
            'messages': true,
            'newFollowers': true,
            'communityUpdates': true,
          });
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('notifications')
            .update({
          setting: value,
        });
      }
    } catch (e) {
      print('Error updating notification setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
      // Revert toggle if there was an error
      setState(() {
        switch (setting) {
          case 'pushEnabled':
            _pushEnabled = !_pushEnabled;
            break;
          case 'emailEnabled':
            _emailEnabled = !_emailEnabled;
            break;
          case 'commentReplies':
            _commentReplies = !_commentReplies;
            break;
          case 'postReplies':
            _postReplies = !_postReplies;
            break;
          case 'upvotes':
            _upvotes = !_upvotes;
            break;
          case 'messages':
            _messages = !_messages;
            break;
          case 'newFollowers':
            _newFollowers = !_newFollowers;
            break;
          case 'communityUpdates':
            _communityUpdates = !_communityUpdates;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Notifications',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              _buildSection(
                title: 'Notification Channels',
                children: [
                  SwitchListTile(
                    title: Text('Push Notifications'),
                    subtitle: Text('Receive push notifications on your device'),
                    value: _pushEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushEnabled = value;
                      });
                      _updateNotificationSetting('pushEnabled', value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Email Notifications'),
                    subtitle: Text('Receive email notifications'),
                    value: _emailEnabled,
                    onChanged: (value) {
                      setState(() {
                        _emailEnabled = value;
                      });
                      _updateNotificationSetting('emailEnabled', value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Activity Notifications',
                children: [
                  SwitchListTile(
                    title: Text('Comment Replies'),
                    subtitle: Text('When someone replies to your comment'),
                    value: _commentReplies,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _commentReplies = value;
                            });
                            _updateNotificationSetting('commentReplies', value);
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Post Replies'),
                    subtitle: Text('When someone comments on your post'),
                    value: _postReplies,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _postReplies = value;
                            });
                            _updateNotificationSetting('postReplies', value);
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Upvotes'),
                    subtitle: Text('When someone upvotes your content'),
                    value: _upvotes,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _upvotes = value;
                            });
                            _updateNotificationSetting('upvotes', value);
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Direct Messages'),
                    subtitle: Text('When you receive a direct message'),
                    value: _messages,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _messages = value;
                            });
                            _updateNotificationSetting('messages', value);
                          }
                        : null,
                  ),
                ],
              ),
              _buildSection(
                title: 'Social Notifications',
                children: [
                  SwitchListTile(
                    title: Text('New Followers'),
                    subtitle: Text('When someone follows you'),
                    value: _newFollowers,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _newFollowers = value;
                            });
                            _updateNotificationSetting('newFollowers', value);
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: Text('Community Updates'),
                    subtitle: Text('News and updates from your communities'),
                    value: _communityUpdates,
                    onChanged: _pushEnabled
                        ? (value) {
                            setState(() {
                              _communityUpdates = value;
                            });
                            _updateNotificationSetting(
                                'communityUpdates', value);
                          }
                        : null,
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
        Divider(),
      ],
    );
  }
}

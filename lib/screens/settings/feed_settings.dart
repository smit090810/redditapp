import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_base_screen.dart';

class FeedSettingsScreen extends StatefulWidget {
  const FeedSettingsScreen({Key? key}) : super(key: key);

  @override
  _FeedSettingsScreenState createState() => _FeedSettingsScreenState();
}

class _FeedSettingsScreenState extends State<FeedSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _defaultSort = 'hot'; // 'hot', 'new', 'top', 'controversial'
  bool _autoplayMedia = true;
  bool _showNSFWContent = false;
  bool _blurNSFWThumbnails = true;
  bool _collapseReadPosts = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedSettings();
  }

  Future<void> _loadFeedSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final feedDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('feed')
            .get();

        if (feedDoc.exists) {
          Map<String, dynamic> data = feedDoc.data() as Map<String, dynamic>;

          setState(() {
            _defaultSort = data['defaultSort'] ?? 'hot';
            _autoplayMedia = data['autoplayMedia'] ?? true;
            _showNSFWContent = data['showNSFWContent'] ?? false;
            _blurNSFWThumbnails = data['blurNSFWThumbnails'] ?? true;
            _collapseReadPosts = data['collapseReadPosts'] ?? false;
          });
        } else {
          // Create default feed settings
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('feed')
              .set({
            'defaultSort': 'hot',
            'autoplayMedia': true,
            'showNSFWContent': false,
            'blurNSFWThumbnails': true,
            'collapseReadPosts': false,
          });
        }
      }
    } catch (e) {
      print('Error loading feed settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFeedSetting(String setting, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('feed')
            .update({
          setting: value,
        });
      }
    } catch (e) {
      print('Error updating feed setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Hot'),
                leading: Icon(Icons.local_fire_department),
                selected: _defaultSort == 'hot',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _defaultSort = 'hot';
                  });
                  _updateFeedSetting('defaultSort', 'hot');
                },
              ),
              ListTile(
                title: Text('New'),
                leading: Icon(Icons.new_releases),
                selected: _defaultSort == 'new',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _defaultSort = 'new';
                  });
                  _updateFeedSetting('defaultSort', 'new');
                },
              ),
              ListTile(
                title: Text('Top'),
                leading: Icon(Icons.arrow_upward),
                selected: _defaultSort == 'top',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _defaultSort = 'top';
                  });
                  _updateFeedSetting('defaultSort', 'top');
                },
              ),
              ListTile(
                title: Text('Controversial'),
                leading: Icon(Icons.forum),
                selected: _defaultSort == 'controversial',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _defaultSort = 'controversial';
                  });
                  _updateFeedSetting('defaultSort', 'controversial');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Feed Settings',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              _buildSection(
                title: 'Content Display',
                children: [
                  ListTile(
                    title: Text('Default Sort'),
                    subtitle: Text(_defaultSort.capitalize()),
                    trailing: Icon(Icons.chevron_right),
                    onTap: _showSortOptions,
                  ),
                  SwitchListTile(
                    title: Text('Autoplay Media'),
                    subtitle: Text('Play videos and GIFs automatically'),
                    value: _autoplayMedia,
                    onChanged: (value) {
                      setState(() {
                        _autoplayMedia = value;
                      });
                      _updateFeedSetting('autoplayMedia', value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Collapse Read Posts'),
                    subtitle:
                        Text('Automatically collapse posts after reading'),
                    value: _collapseReadPosts,
                    onChanged: (value) {
                      setState(() {
                        _collapseReadPosts = value;
                      });
                      _updateFeedSetting('collapseReadPosts', value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Content Filtering',
                children: [
                  SwitchListTile(
                    title: Text('Show NSFW Content'),
                    subtitle: Text('Display adult content in your feed'),
                    value: _showNSFWContent,
                    onChanged: (value) {
                      setState(() {
                        _showNSFWContent = value;
                      });
                      _updateFeedSetting('showNSFWContent', value);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Blur NSFW Thumbnails'),
                    subtitle: Text('Blur previews of adult content'),
                    value: _blurNSFWThumbnails,
                    onChanged: _showNSFWContent
                        ? (value) {
                            setState(() {
                              _blurNSFWThumbnails = value;
                            });
                            _updateFeedSetting('blurNSFWThumbnails', value);
                          }
                        : null,
                  ),
                ],
              ),
              ListTile(
                title: Text(
                  'Community Content Preferences',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _CommunityPreferencesScreen(),
                    ),
                  );
                },
                trailing: Icon(Icons.chevron_right),
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

// Extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class _CommunityPreferencesScreen extends StatefulWidget {
  @override
  _CommunityPreferencesScreenState createState() =>
      _CommunityPreferencesScreenState();
}

class _CommunityPreferencesScreenState
    extends State<_CommunityPreferencesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _communities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunitiesPreferences();
  }

  Future<void> _loadCommunitiesPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user's joined communities
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          List<dynamic> communities = userData['communities'] ?? [];

          // Get community preferences
          final prefsDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('communityPreferences')
              .get();

          Map<String, dynamic> preferences = {};
          if (prefsDoc.exists) {
            preferences = prefsDoc.data() as Map<String, dynamic>;
          }

          // Build the communities list with preferences
          List<Map<String, dynamic>> communityList = [];
          for (String communityId in List<String>.from(communities)) {
            bool showInHome = preferences[communityId] ?? true;

            communityList.add({
              'id': communityId,
              'name': 'r/$communityId',
              'showInHome': showInHome,
            });
          }

          setState(() {
            _communities = communityList;
          });
        }
      }
    } catch (e) {
      print('Error loading community preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCommunityPreference(
      String communityId, bool showInHome) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('communityPreferences')
            .set({
          communityId: showInHome,
        }, SetOptions(merge: true));

        // Update local state
        setState(() {
          int index = _communities
              .indexWhere((community) => community['id'] == communityId);
          if (index != -1) {
            _communities[index]['showInHome'] = showInHome;
          }
        });
      }
    } catch (e) {
      print('Error updating community preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating preference')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Preferences'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _communities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Communities Joined',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Join communities to customize your feed',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _communities.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final community = _communities[index];
                    return SwitchListTile(
                      title: Text(community['name']),
                      subtitle: Text(community['showInHome']
                          ? 'Shown in home feed'
                          : 'Hidden from home feed'),
                      value: community['showInHome'],
                      onChanged: (value) {
                        _updateCommunityPreference(community['id'], value);
                      },
                    );
                  },
                ),
    );
  }
}

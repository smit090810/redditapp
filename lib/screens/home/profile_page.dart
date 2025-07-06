import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/home/post_card.dart';
import './saved_posts_page.dart';
import '../post/post_detail_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isEditingBio = false;
  UserModel? _userProfile;
  List<PostModel> _userPosts = [];
  List<CommentModel> _userComments = [];
  final TextEditingController _bioController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isCurrentUser = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfCurrentUser();
    _fetchUserProfile();
  }

  void _checkIfCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _isCurrentUser = currentUser.uid == widget.userId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _createDefaultUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if the username is set from registration
      String username = user.displayName ?? 'user${user.uid.substring(0, 5)}';

      final userDoc = {
        'username': username,
        'name': user.displayName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'bio': 'Hi there! I am new to Reddit.',
        'karma': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'communities': [],
        'profileImageUrl': user.photoURL,
      };

      await _firestore.collection('users').doc(user.uid).set(userDoc);

      print('Created default user profile for ${user.uid}');

      // Fetch the newly created profile
      _fetchUserProfile();
    } catch (e) {
      print('Error creating default user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: $e')),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug information
      print('Fetching user profile for ID: ${widget.userId}');

      // Fetch user data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        print('User document exists');
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User data: $userData');

        setState(() {
          _userProfile = UserModel.fromMap(userData, userDoc.id);
          if (_userProfile?.bio != null) {
            _bioController.text = _userProfile!.bio!;
          }
          _isLoading = false;
        });

        // After getting user profile, fetch posts and comments
        _fetchUserPosts();
        _fetchUserComments();
      } else {
        print('User document does not exist');

        if (_isCurrentUser) {
          // If this is the current user and profile doesn't exist, create one
          print('Creating new profile for current user');
          await _createDefaultUserProfile();
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found')),
          );
        }
      }
    } catch (e) {
      print('Error in _fetchUserProfile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('createdBy', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
          'Found ${postsSnapshot.docs.length} posts for user ${widget.userId}');

      List<PostModel> posts = [];
      for (var doc in postsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // Get the community name
        String communityId = data['communityId'] ?? '';
        String communityName = communityId;
        if (communityName.isNotEmpty && !communityName.startsWith('r/')) {
          communityName = 'r/$communityName';
        }

        posts.add(PostModel(
          id: doc.id,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          authorId: data['createdBy'] ?? '',
          authorName: data['authorName'] ?? '',
          communityName: communityName,
          imageUrl: data['mediaUrl'],
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
        ));
      }

      setState(() {
        _userPosts = posts;
      });
    } catch (e) {
      print('Error fetching user posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
  }

  Future<void> _fetchUserComments() async {
    try {
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('createdBy', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      print(
          'Found ${commentsSnapshot.docs.length} comments for user ${widget.userId}');

      List<CommentModel> comments = [];
      for (var doc in commentsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        comments.add(CommentModel(
          id: doc.id,
          postId: data['postId'] ?? '',
          content: data['content'] ?? '',
          authorId: data['createdBy'] ?? '',
          authorName: data['authorName'] ?? '',
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
        ));
      }

      setState(() {
        _userComments = comments;
      });
    } catch (e) {
      print('Error fetching user comments: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        _uploadProfileImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Upload image to Firebase Storage
      final ref = _storage.ref().child('profile_images/${widget.userId}');
      await ref.putFile(_profileImage!);

      // Get download URL
      final url = await ref.getDownloadURL();

      // Update user profile in Firestore
      await _firestore.collection('users').doc(widget.userId).update({
        'profileImageUrl': url,
      });

      // Refresh user profile
      _fetchUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _updateBio() async {
    if (_bioController.text.trim() == _userProfile?.bio) {
      setState(() {
        _isEditingBio = false;
      });
      return;
    }

    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'bio': _bioController.text.trim(),
      });

      setState(() {
        if (_userProfile != null) {
          _userProfile = UserModel(
            id: _userProfile!.id,
            username: _userProfile!.username,
            name: _userProfile!.name,
            profileImageUrl: _userProfile!.profileImageUrl,
            bio: _bioController.text.trim(),
            karma: _userProfile!.karma,
            createdAt: _userProfile!.createdAt,
            communities: _userProfile!.communities,
          );
        }
        _isEditingBio = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bio updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bio: $e')),
      );
    }
  }

  void _navigateToSavedPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedPostsPage()),
    );
  }

  String _formatCakeDay(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: Icon(Icons.bookmark_border, color: Colors.black),
              onPressed: _navigateToSavedPosts,
              tooltip: 'Saved Posts',
            ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('User profile not found'),
                      SizedBox(height: 20),
                      if (_isCurrentUser)
                        ElevatedButton(
                          onPressed: _createDefaultUserProfile,
                          child: Text('Create Profile'),
                        ),
                    ],
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(),
                      ),
                      SliverOverlapAbsorber(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                            context),
                        sliver: SliverPersistentHeader(
                          delegate: _SliverAppBarDelegate(
                            TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Theme.of(context).primaryColor,
                              tabs: [
                                Tab(text: 'Posts'),
                                Tab(text: 'Comments'),
                                Tab(text: 'About'),
                              ],
                            ),
                          ),
                          pinned: true,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Posts tab
                      _buildPostsTab(),

                      // Comments tab
                      _buildCommentsTab(),

                      // About tab
                      _buildAboutTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _isCurrentUser ? _pickImage : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: _userProfile!.profileImageUrl != null
                      ? NetworkImage(_userProfile!.profileImageUrl!)
                      : null,
                  child: _userProfile!.profileImageUrl == null
                      ? _isUploadingImage
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _userProfile!.username[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                      : null,
                ),
              ),
              if (_isCurrentUser)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Username
          Text(
            'u/${_userProfile!.username}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),

          // Karma and cake day
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                '${_userProfile!.karma} karma',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(width: 16),
              Icon(Icons.cake, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                'Cake day: ${_formatCakeDay(_userProfile!.createdAt)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Bio
          if (_isEditingBio)
            Column(
              children: [
                TextField(
                  controller: _bioController,
                  maxLength: 150,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write something about yourself...',
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _bioController.text = _userProfile?.bio ?? '';
                          _isEditingBio = false;
                        });
                      },
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateBio,
                      child: Text('Save'),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _userProfile!.bio ?? 'No bio yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (_isCurrentUser)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditingBio = true;
                        });
                      },
                      child: Text('Edit Bio'),
                    ),
                ],
              ),
            ),
          SizedBox(height: 16),

          // Follow stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${_userProfile!.communities.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text('Communities'),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    '${_userPosts.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text('Posts'),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // Sign out button
          if (_isCurrentUser)
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                minimumSize: Size(150, 40),
              ),
              child: Text('Sign Out'),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (BuildContext context) {
          return RefreshIndicator(
            onRefresh: _fetchUserPosts,
            child: CustomScrollView(
              key: PageStorageKey<String>('posts'),
              slivers: <Widget>[
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (_userPosts.isEmpty) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: Text('No posts yet'),
                        );
                      }
                      return PostCard(post: _userPosts[index]);
                    },
                    childCount: _userPosts.isEmpty ? 1 : _userPosts.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsTab() {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (BuildContext context) {
          return RefreshIndicator(
            onRefresh: _fetchUserComments,
            child: CustomScrollView(
              key: PageStorageKey<String>('comments'),
              slivers: <Widget>[
                SliverOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                _userComments.isEmpty
                    ? SliverFillRemaining(
                        child: Center(child: Text('No comments yet')),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final comment = _userComments[index];
                            return _buildCommentItem(comment);
                          },
                          childCount: _userComments.length,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('posts').doc(comment.postId).get(),
      builder: (context, snapshot) {
        String postTitle = 'Loading post...';
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          postTitle = data['title'] ?? 'Unknown post';
        } else if (snapshot.hasError) {
          postTitle = 'Error loading post';
        }

        return InkWell(
          onTap: () async {
            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;

              // Get community name
              String communityId = data['communityId'] ?? '';
              String communityName = communityId;
              if (!communityName.isEmpty && !communityName.startsWith('r/')) {
                communityName = 'r/$communityName';
              }

              // Create post model
              PostModel post = PostModel(
                id: comment.postId,
                title: data['title'] ?? '',
                content: data['content'] ?? '',
                authorId: data['createdBy'] ?? '',
                authorName: data['authorName'] ?? '',
                communityName: communityName,
                imageUrl: data['mediaUrl'],
                upvotes: data['upvotes'] ?? 0,
                downvotes: data['downvotes'] ?? 0,
                commentCount: data['commentCount'] ?? 0,
                createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
              );

              // Navigate to post detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(post: post),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment on post: $postTitle',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      comment.score.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_downward, size: 14, color: Colors.grey),
                    Spacer(),
                    Text(
                      '${_getTimeAgo(comment.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (BuildContext context) {
          return CustomScrollView(
            key: PageStorageKey<String>('about'),
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Trophy Case',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Verified Email'),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Active Communities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._userProfile!.communities.isEmpty
                        ? [
                            Center(
                                child:
                                    Text('Not a member of any communities yet'))
                          ]
                        : _userProfile!.communities.map((community) {
                            return _buildCommunityItem(
                              community[0].toUpperCase(),
                              Colors.primaries[
                                  community.hashCode % Colors.primaries.length],
                              'r/$community',
                              'Member',
                            );
                          }).toList(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommunityItem(
      String letter, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Text(letter),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
}

// This delegate is used for the tab bar to make it sticky
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).cardColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../widgets/home/post_card.dart';

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
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<PostModel> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserProfile();
    _fetchUserPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, fetch from Firebase
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _userProfile = {
          'username': 'RedditUser42',
          'karma': 3254,
          'cakeDay': 'June 12, 2022',
          'bio':
              'Flutter developer and Reddit enthusiast. I love coding and sharing knowledge!',
          'followers': 42,
          'following': 56,
        };
        _isLoading = false;
      });
    } catch (e) {
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
      // In a real app, fetch from Firebase
      await Future.delayed(Duration(seconds: 1));

      List<PostModel> dummyPosts = [
        PostModel(
          id: '4',
          title: 'My first Flutter app!',
          content:
              'Just finished building my first Flutter app. What do you think?',
          authorId: widget.userId,
          authorName: 'RedditUser42',
          communityName: 'r/Flutter',
          imageUrl:
              'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7',
          upvotes: 128,
          downvotes: 8,
          commentCount: 23,
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        ),
        PostModel(
          id: '5',
          title: 'Question about Firebase Authentication',
          content: 'Has anyone implemented phone auth with Firebase? Any tips?',
          authorId: widget.userId,
          authorName: 'RedditUser42',
          communityName: 'r/Firebase',
          imageUrl: null,
          upvotes: 42,
          downvotes: 2,
          commentCount: 15,
          createdAt: DateTime.now().subtract(Duration(days: 14)),
        ),
      ];

      setState(() {
        _userPosts = dummyPosts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
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
              ? Center(child: Text('User not found'))
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
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 50,
            child: Text(
              _userProfile!['username'][0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Username
          Text(
            'u/${_userProfile!['username']}',
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
                '${_userProfile!['karma']} karma',
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(width: 16),
              Icon(Icons.cake, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                'Cake day: ${_userProfile!['cakeDay']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Bio
          if (_userProfile!['bio'] != null)
            Text(
              _userProfile!['bio'],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          SizedBox(height: 16),

          // Follow stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '${_userProfile!['followers']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text('Followers'),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    '${_userProfile!['following']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text('Following'),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          // Sign out button
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
          return CustomScrollView(
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
          return CustomScrollView(
            key: PageStorageKey<String>('comments'),
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverFillRemaining(
                child: Center(child: Text('No comments yet')),
              ),
            ],
          );
        },
      ),
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
                    _buildCommunityItem(
                        'F', Colors.blue, 'r/Flutter', 'Member for 1 year'),
                    _buildCommunityItem('P', Colors.orange, 'r/Programming',
                        'Member for 8 months'),
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

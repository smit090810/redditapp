import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../widgets/home/post_card.dart';
import '../services/firebase_service.dart';
import 'create_post_page.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<String> _sortOptions = ['Hot', 'New', 'Top', 'Controversial'];
  String _currentSort = 'New';
  bool _isLoading = false;
  List<PostModel> _posts = [];
  final FirebaseService _firebaseService = FirebaseService();
  Stream<QuerySnapshot>? _postsStream;

  @override
  void initState() {
    super.initState();
    _setupPostsStream();
  }

  void _setupPostsStream() {
    // Get all posts from Firestore, ordered by creation date
    _postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Reddit',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' Clone',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Implement search
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _currentSort,
                  icon: Icon(Icons.arrow_drop_down),
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentSort = newValue;
                      });
                    }
                  },
                  items: _sortOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Spacer(),
                Icon(Icons.view_agenda, size: 20, color: Colors.grey),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No posts found'));
                }

                // Convert the snapshot data to a list of PostModel objects
                List<PostModel> posts = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;

                  // Get the username for the post author
                  String authorId = data['createdBy'] ?? '';
                  String authorName = data['authorName'] ?? 'Anonymous';

                  // Get the community name
                  String communityId = data['communityId'] ?? '';
                  String communityName = communityId;
                  if (!communityName.startsWith('r/')) {
                    communityName = 'r/$communityName';
                  }

                  return PostModel(
                    id: doc.id,
                    title: data['title'] ?? '',
                    content: data['content'] ?? '',
                    authorId: authorId,
                    authorName: authorName,
                    communityName: communityName,
                    imageUrl: data['mediaUrl'],
                    upvotes: data['upvotes'] ?? 0,
                    downvotes: data['downvotes'] ?? 0,
                    commentCount: data['commentCount'] ?? 0,
                    createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
                  );
                }).toList();

                // Sort posts based on the selected sort option
                if (_currentSort == 'New') {
                  posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                } else if (_currentSort == 'Top') {
                  posts.sort((a, b) => b.score.compareTo(a.score));
                } else if (_currentSort == 'Controversial') {
                  posts.sort((a, b) => (b.upvotes + b.downvotes)
                      .compareTo(a.upvotes + a.downvotes));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      // This will trigger a rebuild with the latest data
                    });
                    return Future.delayed(Duration.zero);
                  },
                  child: ListView.separated(
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      return PostCard(post: posts[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Add floating action button to create new posts
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          ).then((_) {
            // This will refresh the page when coming back from create post
            setState(() {});
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

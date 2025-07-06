import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../widgets/home/post_card.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<String> _sortOptions = ['Hot', 'New', 'Top', 'Controversial'];
  String _currentSort = 'Hot';
  bool _isLoading = false;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This is a placeholder. In a real app, you would fetch from Firebase
      // For now, we'll use dummy data
      await Future.delayed(Duration(seconds: 1));

      List<PostModel> dummyPosts = [
        PostModel(
          id: '1',
          title: 'Check out this awesome sunset!',
          content: 'I took this picture yesterday at the beach',
          authorId: 'user1',
          authorName: 'NaturePhotographer',
          communityName: 'r/Photography',
          imageUrl:
              'https://images.unsplash.com/photo-1616036740257-9449ea1f6605',
          upvotes: 253,
          downvotes: 12,
          commentCount: 45,
          createdAt: DateTime.now().subtract(Duration(hours: 3)),
        ),
        PostModel(
          id: '2',
          title: 'Just finished this coding project after 3 months!',
          content: 'Built a full-stack web app with React and Node.js',
          authorId: 'user2',
          authorName: 'CodeMaster42',
          communityName: 'r/Programming',
          imageUrl: null,
          upvotes: 187,
          downvotes: 5,
          commentCount: 34,
          createdAt: DateTime.now().subtract(Duration(hours: 7)),
        ),
        PostModel(
          id: '3',
          title: 'My homemade pizza recipe',
          content:
              'After years of practice, I finally perfected my dough recipe',
          authorId: 'user3',
          authorName: 'ChefExtraordinaire',
          communityName: 'r/Cooking',
          imageUrl:
              'https://images.unsplash.com/photo-1513104890138-7c749659a591',
          upvotes: 498,
          downvotes: 21,
          commentCount: 92,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
        ),
      ];

      setState(() {
        _posts = dummyPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchPosts,
                    child: _posts.isEmpty
                        ? Center(child: Text('No posts found'))
                        : ListView.separated(
                            itemCount: _posts.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
                            itemBuilder: (context, index) {
                              return PostCard(post: _posts[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

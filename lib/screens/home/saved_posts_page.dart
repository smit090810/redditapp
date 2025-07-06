import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../widgets/home/post_card.dart';

class SavedPostsPage extends StatefulWidget {
  @override
  _SavedPostsPageState createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<PostModel> _savedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get saved post IDs
      final savedPostsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_posts')
          .orderBy('savedAt', descending: true)
          .get();

      if (savedPostsSnapshot.docs.isEmpty) {
        setState(() {
          _savedPosts = [];
          _isLoading = false;
        });
        return;
      }

      // Get the actual posts
      List<PostModel> posts = [];
      for (var doc in savedPostsSnapshot.docs) {
        final String postId = doc.data()['postId'];

        final postDoc = await _firestore.collection('posts').doc(postId).get();
        if (postDoc.exists) {
          final data = postDoc.data() as Map<String, dynamic>;

          // Get the username for the post author
          String authorId = data['createdBy'] ?? '';
          String authorName = data['authorName'] ?? 'Anonymous';

          // Get the community name
          String communityId = data['communityId'] ?? '';
          String communityName = communityId;
          if (!communityName.startsWith('r/')) {
            communityName = 'r/$communityName';
          }

          posts.add(PostModel(
            id: postDoc.id,
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
          ));
        }
      }

      setState(() {
        _savedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved posts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved posts')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? Center(child: Text('No saved posts'))
              : RefreshIndicator(
                  onRefresh: _loadSavedPosts,
                  child: ListView.builder(
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: _savedPosts[index]);
                    },
                  ),
                ),
    );
  }
}

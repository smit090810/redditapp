import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import 'vote_buttons.dart';
import '../../post/post_detail_page.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isSaved = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = _auth.currentUser;
    if (user != null) {
      final savedDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_posts')
          .doc(widget.post.id)
          .get();

      setState(() {
        _isSaved = savedDoc.exists;
      });
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(_currentPost.createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(_currentPost.createdAt);
    }
  }

  Future<void> _toggleSavePost() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to save posts')),
      );
      return;
    }

    final savedPostRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_posts')
        .doc(_currentPost.id);

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        // Save the post
        await savedPostRef.set({
          'postId': _currentPost.id,
          'savedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved')),
        );
      } else {
        // Unsave the post
        await savedPostRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post removed from saved')),
        );
      }
    } catch (e) {
      // Revert UI if there's an error
      setState(() {
        _isSaved = !_isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _sharePost() async {
    final postUrl =
        'https://redditapp.com/post/${_currentPost.id}'; // Replace with your actual URL scheme
    try {
      await Share.share(
        '${_currentPost.title}\n\n${_currentPost.content}\n\n$postUrl',
        subject: _currentPost.title,
      );
    } catch (e) {
      // If share package fails, fallback to clipboard
      await Clipboard.setData(ClipboardData(
        text: '${_currentPost.title}\n\n${_currentPost.content}\n\n$postUrl',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  Future<void> _refreshPostData() async {
    try {
      DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(_currentPost.id).get();

      if (postDoc.exists && postDoc.data() != null) {
        Map<String, dynamic> data = postDoc.data() as Map<String, dynamic>;

        // Get the community name
        String communityId = data['communityId'] ?? '';
        String communityName = communityId;
        if (!communityName.startsWith('r/')) {
          communityName = 'r/$communityName';
        }

        setState(() {
          _currentPost = PostModel(
            id: postDoc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            authorId: data['createdBy'] ?? '',
            authorName: data['authorName'] ?? 'Anonymous',
            communityName: communityName,
            imageUrl: data['mediaUrl'],
            upvotes: data['upvotes'] ?? 0,
            downvotes: data['downvotes'] ?? 0,
            commentCount: data['commentCount'] ?? 0,
            createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          );
        });
      }
    } catch (e) {
      print('Error refreshing post data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final userId = currentUser?.uid ?? '';

    return InkWell(
      onTap: () async {
        // Navigate to post detail and wait for result
        final result = await Navigator.push<PostModel>(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: _currentPost),
          ),
        );

        // If post data was updated, refresh the UI
        if (result != null) {
          setState(() {
            _currentPost = result;
          });
        } else {
          // Even if no result is returned, refresh the post data to get latest comments
          _refreshPostData();
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    _currentPost.communityName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  Text(' • '),
                  Text(
                    'Posted by u/${_currentPost.authorName} ${_getTimeAgo()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),

            // Post Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                _currentPost.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),

            // Post Content
            if (_currentPost.content.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _currentPost.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Post Image
            if (_currentPost.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: NetworkImage(_currentPost.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Post Footer
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Vote Buttons
                  VoteButtons(
                    postId: _currentPost.id,
                    score: _currentPost.score,
                    userId: userId,
                    upvotes: _currentPost.upvotes,
                    downvotes: _currentPost.downvotes,
                    onVoteChanged: _refreshPostData,
                  ),
                  SizedBox(width: 16.0),

                  // Comments
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push<PostModel>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PostDetailPage(post: _currentPost),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _currentPost = result;
                        });
                      } else {
                        _refreshPostData();
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 20.0, color: Colors.grey),
                        SizedBox(width: 4.0),
                        Text(
                          '${_currentPost.commentCount}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.0),

                  // Share
                  InkWell(
                    onTap: _sharePost,
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20.0, color: Colors.grey),
                        SizedBox(width: 4.0),
                        Text(
                          'Share',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),

                  // Save
                  InkWell(
                    onTap: _toggleSavePost,
                    child: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20.0,
                      color: _isSaved
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1.0, thickness: 1.0),
          ],
        ),
      ),
    );
  }
}

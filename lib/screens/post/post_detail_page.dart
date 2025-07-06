import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../widgets/home/vote_buttons.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPostingSaved = false;
  bool _isSubmitting = false;
  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  late PostModel _currentPost;
  bool _postDataChanged = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the post to track changes
    _currentPost = widget.post;
    _loadComments();
    _checkIfPostIsSaved();
  }

  Future<void> _checkIfPostIsSaved() async {
    final user = _auth.currentUser;
    if (user != null) {
      final savedDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_posts')
          .doc(widget.post.id)
          .get();

      setState(() {
        _isPostingSaved = savedDoc.exists;
      });
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
        .doc(widget.post.id);

    setState(() {
      _isPostingSaved = !_isPostingSaved;
    });

    try {
      if (_isPostingSaved) {
        // Save the post
        await savedPostRef.set({
          'postId': widget.post.id,
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
        _isPostingSaved = !_isPostingSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _refreshPostData() async {
    try {
      // Fetch the latest post data
      final postDoc =
          await _firestore.collection('posts').doc(widget.post.id).get();

      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;

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

          // Mark that data has changed
          _postDataChanged = true;
        });
      }
    } catch (e) {
      print('Error refreshing post data: $e');
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      print('Loading comments for post: ${widget.post.id}');

      // Get comments for the post
      final commentsQuery = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: widget.post.id)
          .get();

      print('Found ${commentsQuery.docs.length} comments');

      // Debug what fields we're getting
      if (commentsQuery.docs.isNotEmpty) {
        print('First comment data: ${commentsQuery.docs.first.data()}');
      }

      List<CommentModel> loadedComments = [];

      for (var doc in commentsQuery.docs) {
        Map<String, dynamic> data = doc.data();
        try {
          final comment = CommentModel(
            id: doc.id,
            postId: data['postId'] ?? '',
            content: data['content'] ?? '',
            authorId: data['createdBy'] ?? '',
            authorName: data['authorName'] ?? 'Anonymous',
            upvotes: data['upvotes'] ?? 0,
            downvotes: data['downvotes'] ?? 0,
            createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          );
          loadedComments.add(comment);
        } catch (e) {
          print('Error parsing comment: $e');
        }
      }

      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });

      // Also update the post data to get the accurate comment count
      await _refreshPostData();
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<String> _getUsernameFromId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['username'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('Error getting username: $e');
      return 'User';
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get username
      String username = await _getUsernameFromId(user.uid);

      // Debug print statements
      print('Submitting comment for post: ${widget.post.id}');
      print('User ID: ${user.uid}');
      print('Username: $username');

      final commentData = {
        'postId': widget.post.id,
        'content': _commentController.text.trim(),
        'createdBy': user.uid,
        'authorName': username,
        'createdAt': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
      };

      print('Comment data to be added: $commentData');

      // Add comment to Firestore
      DocumentReference commentRef =
          await _firestore.collection('comments').add(commentData);

      print('Comment added with ID: ${commentRef.id}');

      // Update post's comment count
      await _firestore.collection('posts').doc(widget.post.id).update({
        'commentCount': FieldValue.increment(1),
      });

      // Create a new comment model and add it to the list
      final newComment = CommentModel(
        id: commentRef.id,
        postId: widget.post.id,
        content: _commentController.text.trim(),
        authorId: user.uid,
        authorName: username,
        upvotes: 0,
        downvotes: 0,
        createdAt: DateTime.now(),
      );

      setState(() {
        _comments.add(newComment);
        _commentController.clear();
        _isSubmitting = false;
        _postDataChanged = true;
      });

      // Refresh comments to ensure UI is up to date
      _loadComments();

      // Also update post data to get the accurate comment count
      await _refreshPostData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment posted')),
      );
    } catch (e) {
      print('Error posting comment: $e');
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting comment: $e')),
      );
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              Text(
                'u/${comment.authorName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
              SizedBox(width: 8.0),
              Text(
                _getTimeAgo(comment.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0),
          // Comment content
          Text(comment.content),
          SizedBox(height: 8.0),
          // Comment actions
          Row(
            children: [
              // Upvote
              Icon(Icons.arrow_upward, size: 16.0, color: Colors.grey),
              SizedBox(width: 4.0),
              Text(comment.score.toString()),
              SizedBox(width: 4.0),
              // Downvote
              Icon(Icons.arrow_downward, size: 16.0, color: Colors.grey),
              SizedBox(width: 16.0),
              // Reply
              Text(
                'Reply',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final userId = currentUser?.uid ?? '';

    return WillPopScope(
      onWillPop: () async {
        // Return the updated post data when navigating back
        if (_postDataChanged) {
          Navigator.of(context).pop(_currentPost);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Post'),
          actions: [
            IconButton(
              icon: Icon(
                _isPostingSaved ? Icons.bookmark : Icons.bookmark_border,
              ),
              onPressed: _toggleSavePost,
            ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                // Share post functionality
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Post content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadComments();
                  await _refreshPostData();
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post header and content
                      Container(
                        padding: EdgeInsets.all(16.0),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _currentPost.communityName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(' • '),
                                Text(
                                  'Posted by u/${_currentPost.authorName} ${_getTimeAgo(_currentPost.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              _currentPost.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            SizedBox(height: 12.0),
                            Text(_currentPost.content),
                            if (_currentPost.imageUrl != null) ...[
                              SizedBox(height: 12.0),
                              Image.network(
                                _currentPost.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ],
                            SizedBox(height: 12.0),
                            // Vote buttons and comment count
                            Row(
                              children: [
                                VoteButtons(
                                  postId: _currentPost.id,
                                  score: _currentPost.score,
                                  userId: userId,
                                  upvotes: _currentPost.upvotes,
                                  downvotes: _currentPost.downvotes,
                                  onVoteChanged: () {
                                    // Refresh post data when vote changes
                                    _refreshPostData();
                                  },
                                ),
                                SizedBox(width: 16.0),
                                Icon(Icons.chat_bubble_outline,
                                    size: 20.0, color: Colors.grey),
                                SizedBox(width: 4.0),
                                Text(
                                  '${_comments.length} comments',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1.0, thickness: 8.0),
                      // Comments section
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Comments',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: _loadComments,
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingComments)
                        Center(child: CircularProgressIndicator())
                      else if (_comments.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No comments yet')),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return _buildCommentItem(_comments[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Comment input
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  _isSubmitting
                      ? CircularProgressIndicator()
                      : IconButton(
                          icon: Icon(Icons.send,
                              color: Theme.of(context).primaryColor),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

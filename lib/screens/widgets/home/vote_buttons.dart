import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repository/post_repository.dart';

class VoteButtons extends StatefulWidget {
  final String postId;
  final int score;
  final String userId;
  final int upvotes;
  final int downvotes;
  final VoidCallback onVoteChanged;

  const VoteButtons({
    Key? key,
    required this.postId,
    required this.score,
    required this.userId,
    required this.upvotes,
    required this.downvotes,
    required this.onVoteChanged,
  }) : super(key: key);

  @override
  _VoteButtonsState createState() => _VoteButtonsState();
}

class _VoteButtonsState extends State<VoteButtons> {
  bool _upvoted = false;
  bool _downvoted = false;
  late int _currentScore;

  @override
  void initState() {
    super.initState();
    _currentScore = widget.score;
    _checkExistingVote();
  }

  Future<void> _checkExistingVote() async {
    try {
      // Check if user has already voted on this post
      final voteSnapshot = await FirebaseFirestore.instance
          .collection('votes')
          .where('postId', isEqualTo: widget.postId)
          .where('userId', isEqualTo: widget.userId)
          .get();

      if (voteSnapshot.docs.isNotEmpty) {
        final voteData = voteSnapshot.docs.first.data();
        setState(() {
          _upvoted = voteData['voteType'] == 'upvote';
          _downvoted = voteData['voteType'] == 'downvote';
        });
      }
    } catch (e) {
      print('Error checking existing vote: $e');
    }
  }

  Future<void> _handleUpvote() async {
    // Optimistically update UI
    setState(() {
      if (_upvoted) {
        // Cancel upvote
        _currentScore -= 1;
        _upvoted = false;
      } else {
        // Add upvote
        _currentScore += 1;
        if (_downvoted) {
          // If previously downvoted, remove downvote as well
          _currentScore += 1;
        }
        _upvoted = true;
        _downvoted = false;
      }
    });

    try {
      // Save vote to Firebase
      final votesCollection = FirebaseFirestore.instance.collection('votes');
      final postsCollection = FirebaseFirestore.instance.collection('posts');

      // Check if the user already voted on this post
      final querySnapshot = await votesCollection
          .where('postId', isEqualTo: widget.postId)
          .where('userId', isEqualTo: widget.userId)
          .get();

      // Update the post document with the new vote count
      final postRef = postsCollection.doc(widget.postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (_upvoted) {
          // User is upvoting
          if (querySnapshot.docs.isEmpty) {
            // User hasn't voted before, create new vote document
            transaction.set(votesCollection.doc(), {
              'postId': widget.postId,
              'userId': widget.userId,
              'voteType': 'upvote',
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Increment upvotes in post document
            transaction.update(postRef, {
              'upvotes': FieldValue.increment(1),
            });
          } else {
            // User is changing their vote
            final voteDoc = querySnapshot.docs.first;
            final voteData = voteDoc.data();

            if (voteData['voteType'] == 'downvote') {
              // Change from downvote to upvote
              transaction.update(votesCollection.doc(voteDoc.id), {
                'voteType': 'upvote',
                'timestamp': FieldValue.serverTimestamp(),
              });

              transaction.update(postRef, {
                'upvotes': FieldValue.increment(1),
                'downvotes': FieldValue.increment(-1),
              });
            } else if (voteData['voteType'] == 'upvote') {
              // Cancel upvote
              transaction.delete(votesCollection.doc(voteDoc.id));

              transaction.update(postRef, {
                'upvotes': FieldValue.increment(-1),
              });
            }
          }
        } else {
          // User is canceling upvote
          if (!querySnapshot.docs.isEmpty) {
            transaction
                .delete(votesCollection.doc(querySnapshot.docs.first.id));
            transaction.update(postRef, {
              'upvotes': FieldValue.increment(-1),
            });
          }
        }
      });

      // Notify parent about vote change
      widget.onVoteChanged();
    } catch (e) {
      // If there's an error, revert the UI
      print('Error handling upvote: $e');
      setState(() {
        _upvoted = !_upvoted;
        if (_upvoted) {
          _currentScore += 1;
        } else {
          _currentScore -= 1;
        }
      });
    }
  }

  Future<void> _handleDownvote() async {
    // Optimistically update UI
    setState(() {
      if (_downvoted) {
        // Cancel downvote
        _currentScore += 1;
        _downvoted = false;
      } else {
        // Add downvote
        _currentScore -= 1;
        if (_upvoted) {
          // If previously upvoted, remove upvote as well
          _currentScore -= 1;
        }
        _downvoted = true;
        _upvoted = false;
      }
    });

    try {
      // Save vote to Firebase
      final votesCollection = FirebaseFirestore.instance.collection('votes');
      final postsCollection = FirebaseFirestore.instance.collection('posts');

      // Check if the user already voted on this post
      final querySnapshot = await votesCollection
          .where('postId', isEqualTo: widget.postId)
          .where('userId', isEqualTo: widget.userId)
          .get();

      // Update the post document with the new vote count
      final postRef = postsCollection.doc(widget.postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (_downvoted) {
          // User is downvoting
          if (querySnapshot.docs.isEmpty) {
            // User hasn't voted before, create new vote document
            transaction.set(votesCollection.doc(), {
              'postId': widget.postId,
              'userId': widget.userId,
              'voteType': 'downvote',
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Increment downvotes in post document
            transaction.update(postRef, {
              'downvotes': FieldValue.increment(1),
            });
          } else {
            // User is changing their vote
            final voteDoc = querySnapshot.docs.first;
            final voteData = voteDoc.data();

            if (voteData['voteType'] == 'upvote') {
              // Change from upvote to downvote
              transaction.update(votesCollection.doc(voteDoc.id), {
                'voteType': 'downvote',
                'timestamp': FieldValue.serverTimestamp(),
              });

              transaction.update(postRef, {
                'upvotes': FieldValue.increment(-1),
                'downvotes': FieldValue.increment(1),
              });
            } else if (voteData['voteType'] == 'downvote') {
              // Cancel downvote
              transaction.delete(votesCollection.doc(voteDoc.id));

              transaction.update(postRef, {
                'downvotes': FieldValue.increment(-1),
              });
            }
          }
        } else {
          // User is canceling downvote
          if (!querySnapshot.docs.isEmpty) {
            transaction
                .delete(votesCollection.doc(querySnapshot.docs.first.id));
            transaction.update(postRef, {
              'downvotes': FieldValue.increment(-1),
            });
          }
        }
      });

      // Notify parent about vote change
      widget.onVoteChanged();
    } catch (e) {
      // If there's an error, revert the UI
      print('Error handling downvote: $e');
      setState(() {
        _downvoted = !_downvoted;
        if (_downvoted) {
          _currentScore -= 1;
        } else {
          _currentScore += 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_upward,
            size: 20.0,
            color: _upvoted ? Theme.of(context).primaryColor : Colors.grey,
          ),
          onPressed: _handleUpvote,
          constraints: BoxConstraints(minWidth: 30.0, minHeight: 30.0),
          padding: EdgeInsets.zero,
        ),
        Text(
          _currentScore.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _upvoted
                ? Theme.of(context).primaryColor
                : _downvoted
                    ? Colors.blue
                    : Colors.black,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_downward,
            size: 20.0,
            color: _downvoted ? Colors.blue : Colors.grey,
          ),
          onPressed: _handleDownvote,
          constraints: BoxConstraints(minWidth: 30.0, minHeight: 30.0),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

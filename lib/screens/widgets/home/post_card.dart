import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import 'vote_buttons.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(post.createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(post.createdAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to post detail
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
                    post.communityName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  Text(' • '),
                  Text(
                    'Posted by u/${post.authorName} ${_getTimeAgo()}',
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
                post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),

            // Post Content
            if (post.content.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Post Image
            if (post.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: NetworkImage(post.imageUrl!),
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
                    score: post.score,
                    onUpvote: () {},
                    onDownvote: () {},
                  ),
                  SizedBox(width: 16.0),

                  // Comments
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 20.0, color: Colors.grey),
                      SizedBox(width: 4.0),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(width: 16.0),

                  // Share
                  Row(
                    children: [
                      Icon(Icons.share, size: 20.0, color: Colors.grey),
                      SizedBox(width: 4.0),
                      Text(
                        'Share',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Spacer(),

                  // Save
                  Icon(Icons.bookmark_border, size: 20.0, color: Colors.grey),
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

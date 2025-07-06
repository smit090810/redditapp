import 'package:flutter/material.dart';

class VoteButtons extends StatefulWidget {
  final int score;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const VoteButtons({
    Key? key,
    required this.score,
    required this.onUpvote,
    required this.onDownvote,
  }) : super(key: key);

  @override
  _VoteButtonsState createState() => _VoteButtonsState();
}

class _VoteButtonsState extends State<VoteButtons> {
  // In a real app, you'd track the user's vote status via Firebase
  bool _upvoted = false;
  bool _downvoted = false;

  void _handleUpvote() {
    setState(() {
      if (_upvoted) {
        _upvoted = false;
      } else {
        _upvoted = true;
        _downvoted = false;
      }
    });
    widget.onUpvote();
  }

  void _handleDownvote() {
    setState(() {
      if (_downvoted) {
        _downvoted = false;
      } else {
        _downvoted = true;
        _upvoted = false;
      }
    });
    widget.onDownvote();
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
          widget.score.toString(),
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

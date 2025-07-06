import 'package:flutter/material.dart';
import '../widgets/home/community_card.dart';

class CommunitiesPage extends StatefulWidget {
  @override
  _CommunitiesPageState createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final List<Map<String, dynamic>> _communities = [
    {
      'name': 'r/Flutter',
      'members': 158000,
      'description':
          'A subreddit for Google\'s Flutter UI toolkit for building natively compiled applications.',
      'imageUrl': 'https://avatars.githubusercontent.com/u/14101776',
    },
    {
      'name': 'r/Programming',
      'members': 4200000,
      'description': 'Computer Programming',
      'imageUrl': null,
    },
    {
      'name': 'r/Photography',
      'members': 2800000,
      'description': 'For photographers and photography enthusiasts.',
      'imageUrl':
          'https://images.unsplash.com/photo-1542038784456-1ea8e935640e',
    },
    {
      'name': 'r/AskReddit',
      'members': 36500000,
      'description': 'Ask Reddit: the front page of the internet.',
      'imageUrl': null,
    },
    {
      'name': 'r/Gaming',
      'members': 31900000,
      'description': 'A subreddit for (almost) anything related to games.',
      'imageUrl': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Communities',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Communities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _communities.length,
              itemBuilder: (context, index) {
                final community = _communities[index];
                return CommunityCard(
                  name: community['name'],
                  members: community['members'],
                  description: community['description'],
                  imageUrl: community['imageUrl'],
                  onTap: () {
                    // Navigate to community page
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

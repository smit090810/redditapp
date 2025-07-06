import 'package:flutter/material.dart';

class CommunityCard extends StatelessWidget {
  final String name;
  final int members;
  final String description;
  final String? imageUrl;
  final VoidCallback onTap;

  const CommunityCard({
    Key? key,
    required this.name,
    required this.members,
    required this.description,
    this.imageUrl,
    required this.onTap,
  }) : super(key: key);

  String _formatMembers() {
    if (members >= 1000000) {
      return '${(members / 1000000).toStringAsFixed(1)}M members';
    } else if (members >= 1000) {
      return '${(members / 1000).toStringAsFixed(1)}K members';
    } else {
      return '$members members';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community Icon
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl!) : null,
              radius: 24,
              child: imageUrl == null
                  ? Text(
                      name.substring(2, 3).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 16.0),

            // Community Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    _formatMembers(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ),

            // Join Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}

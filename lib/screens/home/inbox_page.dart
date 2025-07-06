import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'upvote',
      'text': 'Your post "Flutter tips and tricks" received 50 upvotes',
      'time': 'Just now',
      'read': false,
    },
    {
      'type': 'comment',
      'text': 'User123 commented on your post: "Great content, thanks!"',
      'time': '2h ago',
      'read': false,
    },
    {
      'type': 'reply',
      'text': 'User456 replied to your comment: "I agree with your point"',
      'time': '5h ago',
      'read': true,
    },
    {
      'type': 'award',
      'text': 'Your comment received a Silver Award',
      'time': '1d ago',
      'read': true,
    },
  ];

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'TechEnthusiast',
      'message':
          'Hey, I saw your post about Flutter. Can you help me with a problem?',
      'time': '1h ago',
      'read': false,
    },
    {
      'sender': 'PhotoGuru',
      'message': 'Thanks for the feedback on my photography!',
      'time': '1d ago',
      'read': true,
    },
    {
      'sender': 'RedditMod',
      'message': 'Your post has been approved in r/Flutter',
      'time': '2d ago',
      'read': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Inbox',
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(text: 'Notifications'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notifications Tab
          _notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      leading: _getNotificationIcon(notification['type']),
                      title: Text(
                        notification['text'],
                        style: TextStyle(
                          fontWeight: notification['read']
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification['time']),
                      trailing: notification['read']
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () {
                        // Mark as read and show notification detail
                        setState(() {
                          notification['read'] = true;
                        });
                      },
                    );
                  },
                ),

          // Messages Tab
          _messages.isEmpty
              ? Center(child: Text('No messages'))
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          message['sender'][0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        message['sender'],
                        style: TextStyle(
                          fontWeight: message['read']
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(message['message']),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(message['time']),
                          SizedBox(height: 4),
                          if (!message['read'])
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        // Mark as read and show message detail
                        setState(() {
                          message['read'] = true;
                        });
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'upvote':
        iconData = Icons.arrow_upward;
        iconColor = Colors.orange;
        break;
      case 'comment':
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'reply':
        iconData = Icons.reply;
        iconColor = Colors.green;
        break;
      case 'award':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }
}

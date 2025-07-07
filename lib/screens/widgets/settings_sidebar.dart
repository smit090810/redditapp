import 'package:flutter/material.dart';
import '../settings/account_settings.dart';
import '../settings/privacy_settings.dart';
import '../settings/notification_settings.dart';
import '../settings/feed_settings.dart';
import '../settings/appearance_settins.dart';
import '../settings/language_settings.dart';

class SettingsSidebar extends StatelessWidget {
  final Function() onClose;

  const SettingsSidebar({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Settings categories
              _buildSettingItem(context, Icons.account_circle, 'Account', () {
                Navigator.pop(context); // Close the drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(),
                  ),
                );
              }),
              _buildSettingItem(context, Icons.shield, 'Privacy & Safety', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacySettingsScreen(),
                  ),
                );
              }),
              _buildSettingItem(context, Icons.notifications, 'Notifications',
                  () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsScreen(),
                  ),
                );
              }),
              _buildSettingItem(context, Icons.remove_red_eye, 'Feed Settings',
                  () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedSettingsScreen(),
                  ),
                );
              }),
              _buildSettingItem(context, Icons.palette, 'Appearance', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppearanceSettingsScreen(),
                  ),
                );
              }),
              _buildSettingItem(context, Icons.language, 'Language', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LanguageSettingsScreen(),
                  ),
                );
              }),

              const Divider(),

              // Additional options
              _buildSettingItem(context, Icons.help_outline, 'Help Center', () {
                Navigator.pop(context);
                _showHelpCenter(context);
              }),
              _buildSettingItem(context, Icons.bug_report, 'Report an Issue',
                  () {
                Navigator.pop(context);
                _showReportIssue(context);
              }),

              const Spacer(),

              // App version info
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help Center'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              context,
              Icons.book,
              'User Guide',
              'Learn how to use this app',
            ),
            _buildHelpItem(
              context,
              Icons.question_answer,
              'FAQ',
              'Frequently asked questions',
            ),
            _buildHelpItem(
              context,
              Icons.support_agent,
              'Contact Support',
              'Get help from our team',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title')),
        );
      },
    );
  }

  void _showReportIssue(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report an Issue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Issue Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Please describe the issue in detail',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Issue reported! We\'ll look into it.')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}

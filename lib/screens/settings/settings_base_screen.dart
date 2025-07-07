import 'package:flutter/material.dart';

class SettingsBaseScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showBackButton;

  const SettingsBaseScreen({
    Key? key,
    required this.title,
    required this.children,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: ListView(
        children: children,
      ),
    );
  }
}

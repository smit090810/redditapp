import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../repository/post_repository.dart';
import '../services/firebase_service.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCommunity = 'r/Flutter';
  File? _image;
  bool _isPosting = false;
  final FirebaseService _firebaseService = FirebaseService();
  final PostRepository _postRepository = PostRepository();

  final List<String> _communities = [
    'r/Flutter',
    'r/Programming',
    'r/Photography',
    'r/AskReddit',
    'r/Gaming'
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPosting = true;
    });

    try {
      // Get current user from your Firebase service
      final user = _firebaseService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      String userId = user.uid;

      // Use your Firebase service to get user profile
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      String authorName = 'User';
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        authorName = userData['username'] ?? 'Anonymous';
      }

      // Extract community ID from _selectedCommunity (remove 'r/' prefix)
      String communityId = _selectedCommunity.substring(2);

      // Convert File to Uint8List if image exists
      Uint8List? mediaBytes;
      if (_image != null) {
        mediaBytes = await _image!.readAsBytes();
      }

      // Save post to Firebase using your repository
      await _postRepository.createPost(
        _titleController.text,
        _contentController.text,
        communityId,
        userId,
        mediaBytes,
      );

      // Reset form after successful post
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _image = null;
        _isPosting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully!')),
      );

      // Navigate back to the feed page to see the new post
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          'Create Post',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'POST',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCommunity,
                decoration: InputDecoration(
                  labelText: 'Choose a community',
                  border: OutlineInputBorder(),
                ),
                items: _communities.map((String community) {
                  return DropdownMenuItem<String>(
                    value: community,
                    child: Text(community),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCommunity = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Give your post a title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content (optional)',
                  hintText: 'What do you want to share?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),

              // Image preview and buttons
              if (_image != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: _removeImage,
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Add an image'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

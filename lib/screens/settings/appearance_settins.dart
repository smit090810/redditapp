import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_base_screen.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppearanceSettingsScreenState createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _themeMode = 'system'; // 'system', 'light', 'dark', 'amoled'
  bool _reducedAnimations = false;
  String _postSize = 'medium'; // 'compact', 'medium', 'large'
  double _textSize = 1.0; // text scale factor, 0.8 to 1.2
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppearanceSettings();
  }

  Future<void> _loadAppearanceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final appearanceDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('appearance')
            .get();

        if (appearanceDoc.exists) {
          Map<String, dynamic> data =
              appearanceDoc.data() as Map<String, dynamic>;

          setState(() {
            _themeMode = data['themeMode'] ?? 'system';
            _reducedAnimations = data['reducedAnimations'] ?? false;
            _postSize = data['postSize'] ?? 'medium';
            _textSize = (data['textSize'] ?? 1.0).toDouble();
          });
        } else {
          // Create default appearance settings
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('appearance')
              .set({
            'themeMode': 'system',
            'reducedAnimations': false,
            'postSize': 'medium',
            'textSize': 1.0,
          });
        }
      }
    } catch (e) {
      print('Error loading appearance settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAppearanceSetting(String setting, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('appearance')
            .update({
          setting: value,
        });
      }
    } catch (e) {
      print('Error updating appearance setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  void _showThemeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('System Default'),
                leading: Icon(Icons.brightness_auto),
                selected: _themeMode == 'system',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _themeMode = 'system';
                  });
                  _updateAppearanceSetting('themeMode', 'system');
                },
              ),
              ListTile(
                title: Text('Light'),
                leading: Icon(Icons.brightness_high),
                selected: _themeMode == 'light',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _themeMode = 'light';
                  });
                  _updateAppearanceSetting('themeMode', 'light');
                },
              ),
              ListTile(
                title: Text('Dark'),
                leading: Icon(Icons.brightness_4),
                selected: _themeMode == 'dark',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _themeMode = 'dark';
                  });
                  _updateAppearanceSetting('themeMode', 'dark');
                },
              ),
              ListTile(
                title: Text('AMOLED Dark (True Black)'),
                leading: Icon(Icons.brightness_2),
                selected: _themeMode == 'amoled',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _themeMode = 'amoled';
                  });
                  _updateAppearanceSetting('themeMode', 'amoled');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostSizeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Compact'),
                leading: Icon(Icons.format_align_justify),
                selected: _postSize == 'compact',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _postSize = 'compact';
                  });
                  _updateAppearanceSetting('postSize', 'compact');
                },
              ),
              ListTile(
                title: Text('Medium'),
                leading: Icon(Icons.table_rows),
                selected: _postSize == 'medium',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _postSize = 'medium';
                  });
                  _updateAppearanceSetting('postSize', 'medium');
                },
              ),
              ListTile(
                title: Text('Large'),
                leading: Icon(Icons.view_agenda),
                selected: _postSize == 'large',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _postSize = 'large';
                  });
                  _updateAppearanceSetting('postSize', 'large');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Appearance',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              _buildSection(
                title: 'Theme',
                children: [
                  ListTile(
                    title: Text('Dark Mode'),
                    subtitle: Text(_themeMode.capitalize()),
                    trailing: Icon(Icons.chevron_right),
                    onTap: _showThemeOptions,
                  ),
                  SwitchListTile(
                    title: Text('Reduced Animations'),
                    subtitle: Text('Reduce motion effects'),
                    value: _reducedAnimations,
                    onChanged: (value) {
                      setState(() {
                        _reducedAnimations = value;
                      });
                      _updateAppearanceSetting('reducedAnimations', value);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Content Display',
                children: [
                  ListTile(
                    title: Text('Post Size'),
                    subtitle: Text(_postSize.capitalize()),
                    trailing: Icon(Icons.chevron_right),
                    onTap: _showPostSizeOptions,
                  ),
                  Column(
                    children: [
                      ListTile(
                        title: Text('Text Size'),
                        subtitle: Text(_getTextSizeLabel()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text('A', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: _textSize,
                                min: 0.8,
                                max: 1.2,
                                divisions: 4,
                                onChanged: (value) {
                                  setState(() {
                                    _textSize = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  _updateAppearanceSetting('textSize', value);
                                },
                              ),
                            ),
                            Text('A', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                      // Text preview with the current scale factor
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(16),
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaleFactor: _textSize,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Text Size Preview',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'This is how your content will appear with the current text size setting.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
    );
  }

  String _getTextSizeLabel() {
    if (_textSize <= 0.8) return 'Small';
    if (_textSize <= 0.9) return 'Medium Small';
    if (_textSize <= 1.0) return 'Normal';
    if (_textSize <= 1.1) return 'Medium Large';
    return 'Large';
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }
}

// Extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

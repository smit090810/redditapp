import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_base_screen.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  _LanguageSettingsScreenState createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedLanguage = 'en';
  bool _isLoading = true;

  // List of available languages
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español (Spanish)'},
    {'code': 'fr', 'name': 'Français (French)'},
    {'code': 'de', 'name': 'Deutsch (German)'},
    {'code': 'it', 'name': 'Italiano (Italian)'},
    {'code': 'pt', 'name': 'Português (Portuguese)'},
    {'code': 'ru', 'name': 'Русский (Russian)'},
    {'code': 'ja', 'name': '日本語 (Japanese)'},
    {'code': 'zh', 'name': '中文 (Chinese)'},
    {'code': 'ko', 'name': '한국어 (Korean)'},
    {'code': 'ar', 'name': 'العربية (Arabic)'},
    {'code': 'hi', 'name': 'हिन्दी (Hindi)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguageSettings();
  }

  Future<void> _loadLanguageSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final languageDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('language')
            .get();

        if (languageDoc.exists) {
          Map<String, dynamic> data =
              languageDoc.data() as Map<String, dynamic>;

          setState(() {
            _selectedLanguage = data['language'] ?? 'en';
          });
        } else {
          // Create default language setting
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('language')
              .set({
            'language': 'en',
          });
        }
      }
    } catch (e) {
      print('Error loading language settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLanguageSetting(String languageCode) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('language')
            .update({
          'language': languageCode,
        });

        setState(() {
          _selectedLanguage = languageCode;
        });

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language updated'),
            action: SnackBarAction(
              label: 'Reload App',
              onPressed: () {
                // In a real app, you would trigger a app restart or language reload here
                // For now, we'll just show another snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('App would reload with new language')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error updating language setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating language')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBaseScreen(
      title: 'Language',
      children: _isLoading
          ? [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ]
          : [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select your preferred language for the app interface. Content will still be shown in its original language.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              Divider(),
              ..._languages.map((language) {
                return RadioListTile<String>(
                  title: Text(language['name']!),
                  value: language['code']!,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      _updateLanguageSetting(value);
                    }
                  },
                );
              }).toList(),
              SizedBox(height: 20),
              Divider(),
              ListTile(
                title: Text('Content Translation'),
                subtitle: Text('Auto-translate posts and comments'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _TranslationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
    );
  }
}

class _TranslationSettingsScreen extends StatefulWidget {
  @override
  _TranslationSettingsScreenState createState() =>
      _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState
    extends State<_TranslationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _autoTranslate = false;
  List<String> _languagesToTranslate = [];
  bool _isLoading = true;

  // List of available languages for translation
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español (Spanish)'},
    {'code': 'fr', 'name': 'Français (French)'},
    {'code': 'de', 'name': 'Deutsch (German)'},
    {'code': 'it', 'name': 'Italiano (Italian)'},
    {'code': 'pt', 'name': 'Português (Portuguese)'},
    {'code': 'ru', 'name': 'Русский (Russian)'},
    {'code': 'ja', 'name': '日本語 (Japanese)'},
    {'code': 'zh', 'name': '中文 (Chinese)'},
    {'code': 'ko', 'name': '한국어 (Korean)'},
    {'code': 'ar', 'name': 'العربية (Arabic)'},
    {'code': 'hi', 'name': 'हिन्दी (Hindi)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTranslationSettings();
  }

  Future<void> _loadTranslationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final translationDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('translation')
            .get();

        if (translationDoc.exists) {
          Map<String, dynamic> data =
              translationDoc.data() as Map<String, dynamic>;

          setState(() {
            _autoTranslate = data['autoTranslate'] ?? false;
            _languagesToTranslate =
                List<String>.from(data['languagesToTranslate'] ?? []);
          });
        } else {
          // Create default translation settings
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('translation')
              .set({
            'autoTranslate': false,
            'languagesToTranslate': [],
          });
        }
      }
    } catch (e) {
      print('Error loading translation settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAutoTranslate(bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('translation')
            .update({
          'autoTranslate': value,
        });

        setState(() {
          _autoTranslate = value;
        });
      }
    } catch (e) {
      print('Error updating auto-translate setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
      setState(() {
        _autoTranslate = !value; // Revert the change
      });
    }
  }

  Future<void> _toggleLanguageTranslation(
      String languageCode, bool selected) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        List<String> updatedLanguages =
            List<String>.from(_languagesToTranslate);

        if (selected) {
          if (!updatedLanguages.contains(languageCode)) {
            updatedLanguages.add(languageCode);
          }
        } else {
          updatedLanguages.remove(languageCode);
        }

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('translation')
            .update({
          'languagesToTranslate': updatedLanguages,
        });

        setState(() {
          _languagesToTranslate = updatedLanguages;
        });
      }
    } catch (e) {
      print('Error updating languages to translate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translation Settings'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text('Auto-Translate Content'),
                  subtitle: Text(
                      'Automatically translate content in foreign languages'),
                  value: _autoTranslate,
                  onChanged: _updateAutoTranslate,
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select languages to auto-translate:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ..._languages.map((language) {
                  return CheckboxListTile(
                    title: Text(language['name']!),
                    value: _languagesToTranslate.contains(language['code']),
                    onChanged: _autoTranslate
                        ? (selected) {
                            if (selected != null) {
                              _toggleLanguageTranslation(
                                  language['code']!, selected);
                            }
                          }
                        : null,
                  );
                }).toList(),
              ],
            ),
    );
  }
}

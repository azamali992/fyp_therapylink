import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/Views/profile_info.dart';
import 'package:therapylink/Views/privacy_security_page.dart';
import 'package:therapylink/Views/font_size_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSizeProvider =
        Provider.of<FontSizeProvider>(context, listen: false);
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      fontSizeProvider.updateTextSize(prefs.getDouble('textSize') ?? 16.0);
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    if (value is double) prefs.setDouble(key, value);
    if (value is String) prefs.setString(key, value);

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('settings')
          .doc(uid)
          .set({key: value}, SetOptions(merge: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final fontSize = Provider.of<FontSizeProvider>(context).textSize *
        MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundGradientStart,
                AppColors.backgroundGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader('Account Settings', fontSize),
              _buildSettingItem(
                icon: Icons.person,
                title: 'Profile Information',
                fontSize: fontSize,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileInfoPage()),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                fontSize: fontSize,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacySecurityPage()),
                  );
                },
              ),
              const Divider(color: Colors.white30),
              _buildSectionHeader('App Settings', fontSize),
              SwitchListTile(
                title: Text('Enable Notifications',
                    style: TextStyle(color: Colors.white, fontSize: fontSize)),
                secondary: const Icon(Icons.notifications, color: Colors.white),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() => _notificationsEnabled = value);
                  _savePreference('notifications', value);
                  _showConfirmation(
                      'Notifications ${value ? "enabled" : "disabled"}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.white),
                title: Text('Text Size',
                    style: TextStyle(color: Colors.white, fontSize: fontSize)),
                subtitle: Slider(
                  value: fontSize / MediaQuery.of(context).textScaleFactor,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  label: fontSize.round().toString(),
                  onChanged: (double value) {
                    final scaledValue = value;
                    Provider.of<FontSizeProvider>(context, listen: false)
                        .updateTextSize(scaledValue);
                    _savePreference('textSize', scaledValue);
                  },
                ),
              ),
              const Divider(color: Colors.white30),
              _buildSectionHeader('Preferences', fontSize),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white),
                title: Text('Language',
                    style: TextStyle(color: Colors.white, fontSize: fontSize)),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: AppColors.bgpurple,
                  style: TextStyle(color: Colors.white, fontSize: fontSize),
                  items: <String>['English', 'Spanish', 'French', 'German']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: fontSize)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedLanguage = newValue);
                      _savePreference('language', newValue);
                      _showConfirmation('Language set to $newValue');
                    }
                  },
                ),
              ),
              const Divider(color: Colors.white30),
              _buildSectionHeader('Support', fontSize),
              _buildSettingItem(
                icon: Icons.help,
                title: 'Help & FAQ',
                fontSize: fontSize,
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.feedback,
                title: 'Send Feedback',
                fontSize: fontSize,
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.info,
                title: 'About',
                fontSize: fontSize,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize + 4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: TextStyle(color: Colors.white, fontSize: fontSize)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: onTap,
    );
  }
}

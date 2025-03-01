import 'package:flutter/material.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _textSize = 16.0;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
      body: Container(
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
            _buildSectionHeader('Account Settings'),
            _buildSettingItem(
              icon: Icons.person,
              title: 'Profile Information',
              onTap: () {
                // Navigate to profile information page
              },
            ),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Privacy & Security',
              onTap: () {
                // Navigate to privacy settings
              },
            ),
            const Divider(color: Colors.white30),
            _buildSectionHeader('App Settings'),
            SwitchListTile(
              title: const Text('Enable Notifications',
                  style: TextStyle(color: Colors.white)),
              secondary: const Icon(Icons.notifications, color: Colors.white),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Dark Mode',
                  style: TextStyle(color: Colors.white)),
              secondary: const Icon(Icons.dark_mode, color: Colors.white),
              value: _darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.white),
              title: const Text('Text Size',
                  style: TextStyle(color: Colors.white)),
              subtitle: Slider(
                value: _textSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: _textSize.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _textSize = value;
                  });
                },
              ),
            ),
            const Divider(color: Colors.white30),
            _buildSectionHeader('Preferences'),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title:
                  const Text('Language', style: TextStyle(color: Colors.white)),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: AppColors.bgpurple,
                style: const TextStyle(color: Colors.white),
                items: <String>['English', 'Spanish', 'French', 'German']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  }
                },
              ),
            ),
            const Divider(color: Colors.white30),
            _buildSectionHeader('Support'),
            _buildSettingItem(
              icon: Icons.help,
              title: 'Help & FAQ',
              onTap: () {
                // Navigate to help page
              },
            ),
            _buildSettingItem(
              icon: Icons.feedback,
              title: 'Send Feedback',
              onTap: () {
                // Open feedback dialog
              },
            ),
            _buildSettingItem(
              icon: Icons.info,
              title: 'About',
              onTap: () {
                // Show about dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: onTap,
    );
  }
}

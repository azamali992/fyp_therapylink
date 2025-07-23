import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:therapylink/Views/phone_auth_screen.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String uid;
  bool _loading = true;

  bool _privateAccount = false;
  bool _locationAccess = false;
  bool _twoFactorAuth = false;

  @override
  void initState() {
    super.initState();
    uid = _auth.currentUser!.uid;
    _firestore.collection('users').doc(uid).update({
      'lastLogout': DateTime.now().toIso8601String(),
      'scheduledDeletion': null,
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _privateAccount = data['privateAccount'] ?? false;
      _locationAccess = data['locationAccess'] ?? false;
      _twoFactorAuth = data['twoFactorAuth'] ?? false;
    }

    setState(() {
      _privateAccount = prefs.getBool('privateAccount') ?? _privateAccount;
      _locationAccess = prefs.getBool('locationAccess') ?? _locationAccess;
      _twoFactorAuth = prefs.getBool('twoFactorAuth') ?? _twoFactorAuth;
      _loading = false;
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await _firestore.collection('users').doc(uid).update({key: value});
  }

  Future<void> _exportUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final logsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .get();
      final logs = logsSnapshot.docs.map((d) => d.data()).toList();

      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();
      final chats = chatsSnapshot.docs.map((d) => d.data()).toList();

      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();
      final posts = postsSnapshot.docs.map((d) => d.data()).toList();

      userData['logs'] = logs;
      userData['chats'] = chats;
      userData['posts'] = posts;

      final rawJson = const JsonEncoder.withIndent('  ').convert(userData);
      final encrypted = sha256.convert(utf8.encode(rawJson)).toString();

      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/user_backup_$uid.json');
      await file.writeAsString(encrypted);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Encrypted backup saved to ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting data: ${e.toString()}")),
      );
    }
  }

  Future<void> _confirmPasswordAndDelete() async {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Password"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = _auth.currentUser;
                final cred = EmailAuthProvider.credential(
                    email: user!.email!, password: passwordController.text);
                await user.reauthenticateWithCredential(cred);
                _showDeleteCountdown();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Re-auth failed: ${e.toString()}")),
                );
              }
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  void _showDeleteCountdown() {
    int secondsLeft = 10;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (secondsLeft == 0) {
            timer.cancel();
            Navigator.of(context).pop();
            final confirmed = await _confirmOTP();
            if (confirmed) {
              await _firestore.collection('users').doc(uid).update({
                'scheduledDeletion': DateTime.now()
                    .add(const Duration(days: 7))
                    .toIso8601String(),
              });
              await _auth.signOut();
              Navigator.of(context).pop();
            }
          } else {
            setState(() => secondsLeft--);
          }
        });

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
                "Account will be scheduled for deletion in $secondsLeft seconds..."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmOTP() async {
    final phone = await _firestore
        .collection('users')
        .doc(uid)
        .get()
        .then((doc) => doc['phoneNumber']);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneAuthScreen(phoneNumber: phone),
      ),
    );
    return result == true;
  }

  void _showChangePasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = passwordController.text;
              final confirm = confirmController.text;

              if (newPassword != confirm) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }

              try {
                await _auth.currentUser!.updatePassword(newPassword);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Password changed successfully")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.toString()}")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppColors.bgpurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.bgpurple,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  title: const Text('Private Account',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Only approved users can see your activity',
                      style: TextStyle(color: Colors.white70)),
                  secondary: const Icon(Icons.lock, color: Colors.white),
                  value: _privateAccount,
                  onChanged: (value) {
                    setState(() => _privateAccount = value);
                    _updateSetting('privateAccount', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Location Access',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Used for personalized content and safety',
                      style: TextStyle(color: Colors.white70)),
                  secondary: const Icon(Icons.location_on, color: Colors.white),
                  value: _locationAccess,
                  onChanged: (value) async {
                    if (value) {
                      LocationPermission permission =
                          await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied ||
                          permission == LocationPermission.deniedForever) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Location permission denied")),
                        );
                        return;
                      }
                      setState(() => _locationAccess = true);
                      _updateSetting('locationAccess', true);
                    } else {
                      setState(() => _locationAccess = false);
                      _updateSetting('locationAccess', false);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Two-Factor Authentication',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Verify using real phone OTP',
                      style: TextStyle(color: Colors.white70)),
                  secondary: const Icon(Icons.security, color: Colors.white),
                  value: _twoFactorAuth,
                  onChanged: (value) async {
                    if (value) {
                      final phone = await _firestore
                          .collection('users')
                          .doc(uid)
                          .get()
                          .then((doc) => doc['phoneNumber']);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhoneAuthScreen(phoneNumber: phone),
                        ),
                      );

                      if (result == true) {
                        setState(() => _twoFactorAuth = true);
                        _updateSetting('twoFactorAuth', true);
                      }
                    } else {
                      setState(() => _twoFactorAuth = false);
                      _updateSetting('twoFactorAuth', false);
                    }
                  },
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.password, color: Colors.white),
                  title: const Text('Change Password',
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: _showChangePasswordDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: const Text('Export My Data',
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: _exportUserData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete My Account',
                      style: TextStyle(color: Colors.redAccent)),
                  trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.red),
                  onTap: _confirmPasswordAndDelete,
                ),
              ],
            ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:therapylink/Views/stress_relieving.dart';
import 'package:therapylink/Views/profile_info.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/Views/about_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = 'User';
  String _currentMood = 'Happy';
  String _email = 'user@example.com';
  String _dob = '';
  String _phone = '';
  String _gender = 'Male';
  String _country = 'Pakistan';
  int _age = 0;
  Map<String, int> _moodLevels = {
    'Happy': 70,
    'Sad': 20,
    'Angry': 10,
    'Anxious': 30,
    'Stressed': 40,
    'Calm': 60,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            // Use username as the primary display name
            _name = userData['username'] ??
                userData['fullName'] ??
                userData['name'] ??
                'User';
            _email = user.email ?? 'user@example.com';

            // Additional profile details from profile_info.dart approach
            _dob = userData['dob'] ?? '';
            _phone = userData['phone'] ?? '';
            _gender = userData['gender'] ?? 'Male';
            _country = userData['country'] ?? 'Pakistan';

            // Calculate age if DOB is available
            if (_dob.isNotEmpty) {
              try {
                DateTime dob = DateTime.parse(_dob);
                _age = DateTime.now().year - dob.year;
                // Adjust age if birthday hasn't occurred yet this year
                if (DateTime.now().month < dob.month ||
                    (DateTime.now().month == dob.month &&
                        DateTime.now().day < dob.day)) {
                  _age--;
                }
              } catch (e) {
                print('Error calculating age: $e');
              }
            }
          });
        }

        // Load sentiment data after user data is loaded
        await _loadSentimentData();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSentimentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get sentiments from Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sentiments')
          .orderBy('timestamp', descending: true)
          .get();

      // Count for each sentiment type
      int posCount = 0;
      int negCount = 0;
      int neuCount = 0;
      int totalCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final sentiment = (data['sentiment'] as String).toLowerCase();

        if (sentiment == 'pos' || sentiment == 'positive') {
          posCount++;
        } else if (sentiment == 'neg' || sentiment == 'negative') {
          negCount++;
        } else if (sentiment == 'neu' || sentiment == 'neutral') {
          neuCount++;
        }
        totalCount++;
      }

      // Calculate percentages (defaults to 0 if no sentiments)
      int posPercentage =
          totalCount > 0 ? ((posCount / totalCount) * 100).round() : 0;
      int negPercentage =
          totalCount > 0 ? ((negCount / totalCount) * 100).round() : 0;
      int neuPercentage =
          totalCount > 0 ? ((neuCount / totalCount) * 100).round() : 0;

      // Update mood levels with real sentiment data
      setState(() {
        _moodLevels = {
          'Positive': posPercentage,
          'Negative': negPercentage,
          'Neutral': neuPercentage,
        };

        // Update current mood based on most frequent sentiment
        if (totalCount > 0) {
          if (posCount >= negCount && posCount >= neuCount) {
            _currentMood = 'Positive';
          } else if (negCount >= posCount && negCount >= neuCount) {
            _currentMood = 'Negative';
          } else {
            _currentMood = 'Neutral';
          }
        }
      });
    } catch (e) {
      print('Error loading sentiment data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
              Color.fromARGB(255, 55, 13, 104),
              AppColors.backgroundGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.02,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.bgpurple),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Loading profile...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile header with user status and avatar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    // Profile Avatar with animated glow effect
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(seconds: 2),
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      curve: Curves.easeInOut,
                                      builder: (context, value, child) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.bgpurple
                                                    .withOpacity(0.5 * value),
                                                blurRadius: 20 * value,
                                                spreadRadius: 5 * value,
                                              ),
                                            ],
                                          ),
                                          child: const CircleAvatar(
                                            radius: 60,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: AppColors.bgpurple,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // Online status indicator
                                    Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),

                            // User name and subtitle with refresh button
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _name,
                                        style: const TextStyle(
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white70),
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(
                                                Icons.refresh,
                                                color: Colors.white70,
                                                size: 22,
                                              ),
                                              onPressed: _loadUserData,
                                              tooltip: 'Refresh profile data',
                                            ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.bgpurple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: AppColors.bgpurple
                                              .withOpacity(0.5)),
                                    ),
                                    child: const Text(
                                      'Premium Member',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Stats row
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem('Sessions', '24'),
                                  _buildVerticalDivider(),
                                  _buildStatItem('Streak', '7 days'),
                                  _buildVerticalDivider(),
                                  _buildStatItem('Progress', '87%'),
                                ],
                              ),
                            ),

                            // Profile card with frosted glass effect
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: screenWidth * 0.9,
                                  padding: const EdgeInsets.all(20.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Profile Information',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.white70,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              // Navigate to ProfileInfoPage for editing
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ProfileInfoPage(),
                                                ),
                                              ).then((_) {
                                                // Reload user data when returning from edit page
                                                _loadUserData();
                                              });
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                          color: Colors.white24, height: 20),
                                      _buildProfileInfo('Email', _email),
                                      const SizedBox(height: 15.0),
                                      _buildProfileInfo(
                                          'Current Mood', _currentMood),
                                      const SizedBox(height: 15.0),
                                      _buildProfileInfo('Gender', _gender),
                                      const SizedBox(height: 15.0),
                                      _buildProfileInfo('Country', _country),
                                      const SizedBox(height: 15.0),
                                      if (_dob.isNotEmpty) ...[
                                        _buildProfileInfo('Age', '$_age years'),
                                        const SizedBox(height: 15.0),
                                      ],
                                      if (_phone.isNotEmpty) ...[
                                        _buildProfileInfo('Phone', _phone),
                                        const SizedBox(height: 15.0),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30.0),

                            // Mood Levels Section with Card Effect
                            Container(
                              width: screenWidth * 0.9,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.3),
                                    Colors.indigo.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.psychology,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Mood Analysis',
                                        style: TextStyle(
                                          fontSize: 24.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              'This Week',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Track your emotional patterns over time',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),

                                  // Mood level indicators with animations
                                  ..._moodLevels.entries.map((entry) =>
                                      _buildMoodLevel(entry.key, entry.value)),

                                  // View Details Button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Navigate to MoodAnalysisPage for detailed analysis
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MoodAnalysisPage(),
                                          ),
                                        ).then((_) {
                                          // Refresh data when returning from the mood analysis page
                                          _loadSentimentData();
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View Details',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Recommended Activities Section
                            const SizedBox(height: 30),
                            Container(
                              width: screenWidth * 0.9,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(75, 72, 0, 138),
                                    Color.fromARGB(75, 33, 0, 93),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recommended for You',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Tap any activity to access stress relief options',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 15.0),
                                  _buildRecommendedActivity(
                                    'Stress Relief',
                                    'Various options',
                                    Icons.spa_outlined,
                                    0.8,
                                  ),
                                  _buildRecommendedActivity(
                                    'Ambient Sounds',
                                    'Background audio',
                                    Icons.music_note,
                                    0.6,
                                  ),
                                  _buildRecommendedActivity(
                                    'Relaxation',
                                    'Multiple techniques',
                                    Icons.self_improvement,
                                    0.4,
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons section
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  'Settings',
                                  Icons.settings,
                                  () {
                                    // Navigate to the existing settings page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SettingsPage(), // Use your existing SettingsPage
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  'Support',
                                  Icons.settings,
                                  () {
                                    // Navigate to the existing settings page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutPage(), // Use your existing SettingsPage
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  'Logout',
                                  Icons.logout,
                                  () async {
                                    // Show confirmation dialog
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppColors.bgpurple,
                                        title: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to logout?',
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                  color: Colors.white70),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Logout',
                                              style: TextStyle(
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    // Proceed with logout if confirmed
                                    if (shouldLogout == true) {
                                      try {
                                        await _auth.signOut();

                                        // Navigate to login screen and clear all previous routes
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/login', // Make sure this route name matches your login route
                                          (route) => false,
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error logging out: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for building stat items
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Helper method for vertical divider
  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // Helper method for building action buttons
  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building recommended activities
  Widget _buildRecommendedActivity(
      String title, String duration, IconData icon, double opacity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          // Navigate to stress relief page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StressRelievingPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1 * opacity),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgpurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodLevel(String mood, dynamic level) {
    // Convert int to double percentage (0.0 to 1.0)
    double levelPercent = (level is int) ? level / 100.0 : (level as double);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mood,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              Text(
                '${(levelPercent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Stack(
            children: [
              // Background bar
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Animated progress bar
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0.0, end: levelPercent),
                builder: (context, value, child) {
                  return Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.7 * value,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.bgpurple,
                          Color.fromARGB(255, 130, 60, 229),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bgpurple.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

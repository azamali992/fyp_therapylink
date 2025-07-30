import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../auth.dart';
import 'login.dart';
import 'dart:ui';

class PsychologistProfilePage extends StatefulWidget {
  const PsychologistProfilePage({super.key});

  @override
  _PsychologistProfilePageState createState() =>
      _PsychologistProfilePageState();
}

class _PsychologistProfilePageState extends State<PsychologistProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _professionalProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Load professional profile data
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userProfile = userDoc.exists ? userDoc.data() : null;
          _professionalProfile =
              professionalDoc.exists ? professionalDoc.data() : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'approved':
        return '🟢';
      case 'pending':
        return '🟡';
      case 'rejected':
        return '🔴';
      case 'under_review':
        return '🟠';
      default:
        return '⚪';
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'rejected':
        return 'Rejected';
      case 'under_review':
        return 'Under Review';
      default:
        return 'Unknown Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Edit profile feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Container(
        height: screenHeight,
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgpink,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header Card
                            _buildProfileHeader(screenWidth),

                            SizedBox(height: screenHeight * 0.03),

                            // Verification Status Card
                            _buildVerificationStatus(screenWidth),

                            SizedBox(height: screenHeight * 0.03),

                            // Basic Information Card
                            _buildBasicInformation(screenWidth),

                            SizedBox(height: screenHeight * 0.03),

                            // Professional Information Card
                            _buildProfessionalInformation(screenWidth),

                            SizedBox(height: screenHeight * 0.03),

                            // Statistics Card
                            _buildStatistics(screenWidth),

                            SizedBox(height: screenHeight * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader(double screenWidth) {
    final user = FirebaseAuth.instance.currentUser;
    final username = _userProfile?['username'] ?? 'Psychologist';
    final email = user?.email ?? 'No email';
    final specialty = _professionalProfile?['specialty'] ?? 'Psychology';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.bgpink, AppColors.bgpurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bgpink.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStatus(double screenWidth) {
    final status = _professionalProfile?['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Verification Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      statusColor,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (status.toLowerCase() == 'pending' ||
                    status.toLowerCase() == 'under_review')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Your account is being reviewed by our admin team. You will be notified once the verification is complete.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformation(double screenWidth) {
    return _buildInfoCard(
      screenWidth: screenWidth,
      title: 'Basic Information',
      icon: Icons.person,
      children: [
        _buildInfoRow(
            'Age', _userProfile?['age']?.toString() ?? 'Not specified'),
        _buildInfoRow('Gender', _userProfile?['gender'] ?? 'Not specified'),
        _buildInfoRow('Phone', _userProfile?['phone'] ?? 'Not specified'),
        _buildInfoRow('Date of Birth', _userProfile?['dob'] ?? 'Not specified'),
      ],
    );
  }

  Widget _buildProfessionalInformation(double screenWidth) {
    final languages = _professionalProfile?['languages'] as List<dynamic>?;
    final languageString = languages?.join(', ') ?? 'Not specified';

    return _buildInfoCard(
      screenWidth: screenWidth,
      title: 'Professional Information',
      icon: Icons.work,
      children: [
        _buildInfoRow('License Number',
            _professionalProfile?['licenseNumber'] ?? 'Not specified'),
        _buildInfoRow(
            'Specialty', _professionalProfile?['specialty'] ?? 'Not specified'),
        _buildInfoRow(
            'Education', _professionalProfile?['education'] ?? 'Not specified'),
        _buildInfoRow(
            'Years of Experience',
            _professionalProfile?['yearsExperience']?.toString() ??
                'Not specified'),
        _buildInfoRow('Languages', languageString),
        const SizedBox(height: 8),
        const Text(
          'Bio:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _professionalProfile?['bio'] ?? 'No bio available',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(double screenWidth) {
    final averageRating =
        _professionalProfile?['averageRating']?.toDouble() ?? 0.0;
    final totalRatings =
        (_professionalProfile?['ratings'] as List<dynamic>?)?.length ?? 0;
    final createdAt = _professionalProfile?['createdAt'] as Timestamp?;
    final joinDate = createdAt?.toDate().toString().split(' ')[0] ?? 'Unknown';

    return _buildInfoCard(
      screenWidth: screenWidth,
      title: 'Statistics',
      icon: Icons.analytics,
      children: [
        _buildInfoRow(
            'Average Rating',
            averageRating > 0
                ? '${averageRating.toStringAsFixed(1)} ⭐'
                : 'No ratings yet'),
        _buildInfoRow('Total Ratings', totalRatings.toString()),
        _buildInfoRow('Member Since', joinDate),
        _buildInfoRow(
            'Profile Completion', '${_calculateProfileCompletion()}%'),
      ],
    );
  }

  Widget _buildInfoCard({
    required double screenWidth,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateProfileCompletion() {
    int completedFields = 0;
    int totalFields = 12; // Total number of important fields

    // Check user profile fields
    if (_userProfile?['username']?.toString().isNotEmpty == true)
      completedFields++;
    if (_userProfile?['age']?.toString().isNotEmpty == true) completedFields++;
    if (_userProfile?['gender']?.toString().isNotEmpty == true)
      completedFields++;
    if (_userProfile?['phone']?.toString().isNotEmpty == true)
      completedFields++;
    if (_userProfile?['dob']?.toString().isNotEmpty == true) completedFields++;

    // Check professional profile fields
    if (_professionalProfile?['licenseNumber']?.toString().isNotEmpty == true)
      completedFields++;
    if (_professionalProfile?['specialty']?.toString().isNotEmpty == true)
      completedFields++;
    if (_professionalProfile?['education']?.toString().isNotEmpty == true)
      completedFields++;
    if (_professionalProfile?['yearsExperience']?.toString().isNotEmpty == true)
      completedFields++;
    if (_professionalProfile?['bio']?.toString().isNotEmpty == true)
      completedFields++;
    if ((_professionalProfile?['languages'] as List<dynamic>?)?.isNotEmpty ==
        true) completedFields++;
    if (_professionalProfile?['status']?.toString().isNotEmpty == true)
      completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }
}

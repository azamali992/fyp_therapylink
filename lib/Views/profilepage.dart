import 'package:flutter/material.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String currentMood;
  final Map<String, double> moodLevels;

  const ProfilePage({
    super.key,
    required this.name,
    required this.currentMood,
    required this.moodLevels,
  });

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.bgpurple,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildProfileInfo('Name', name),
              const SizedBox(height: 16.0),
              _buildProfileInfo('last Mood', currentMood),
              const SizedBox(height: 16.0),
              const Text(
                'Mood Levels',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8.0),
              ...moodLevels.entries
                  .map((entry) => _buildMoodLevel(entry.key, entry.value))
                  ,
            ],
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
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodLevel(String mood, double level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mood,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 4.0),
        LinearProgressIndicator(
          value: level,
          backgroundColor: Colors.white24,
          color: AppColors.bgpurple,
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}

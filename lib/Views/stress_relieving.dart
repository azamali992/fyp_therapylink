import 'package:flutter/material.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/utils/colors.dart';

class StressRelievingPage extends StatelessWidget {
  const StressRelievingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
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
          child: Column(
            children: [
              const TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.self_improvement), text: "Relaxation"),
                  Tab(icon: Icon(Icons.brush), text: "Express Yourself"),
                  Tab(icon: Icon(Icons.music_note), text: "Soothing Sounds"),
                  Tab(icon: Icon(Icons.insert_chart), text: "Mood Tracker"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRelaxationSection(),
                    _buildExpressYourselfSection(),
                    _buildSoothingSoundsSection(),
                    _buildMoodTrackerSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelaxationSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTechniqueCard(
            title: "Deep Breathing",
            description: "Practice deep breathing exercises to calm your mind.",
            icon: Icons.air,
          ),
          _buildTechniqueCard(
            title: "Meditation",
            description: "Engage in guided meditation to reduce stress.",
            icon: Icons.self_improvement,
          ),
          _buildTechniqueCard(
            title: "Visualization",
            description: "Visualize peaceful scenes to relax your mind.",
            icon: Icons.landscape,
          ),
        ],
      ),
    );
  }

  Widget _buildExpressYourselfSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTechniqueCard(
            title: "Journaling",
            description: "Write down your thoughts and feelings.",
            icon: Icons.book,
          ),
          _buildTechniqueCard(
            title: "Artistic Expression",
            description: "Express yourself through drawing or painting.",
            icon: Icons.brush,
          ),
        ],
      ),
    );
  }

  Widget _buildSoothingSoundsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildTechniqueCard(
            title: "Rain",
            description: "Listen to the soothing sound of rain.",
            icon: Icons.cloud,
          ),
          _buildTechniqueCard(
            title: "Ocean",
            description: "Relax with the sound of ocean waves.",
            icon: Icons.waves,
          ),
          _buildTechniqueCard(
            title: "White Noise",
            description: "Block out distractions with white noise.",
            icon: Icons.noise_aware,
          ),
          _buildTechniqueCard(
            title: "Binaural Beats",
            description: "Enhance relaxation with binaural beats.",
            icon: Icons.headphones,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrackerSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Log your mood:",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodButton("😊", "Happy"),
              _buildMoodButton("😢", "Sad"),
              _buildMoodButton("😡", "Angry"),
              _buildMoodButton("😰", "Stressed"),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            "Mood Trends:",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8.0),
          // Add a chart or graph to display mood trends
        ],
      ),
    );
  }

  Widget _buildTechniqueCard({required String title, required String description, required IconData icon}) {
    return Card(
      color: AppColors.bgpurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 40.0),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String mood) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.bgpurple,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24.0),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          mood,
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
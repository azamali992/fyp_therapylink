import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/Views/express%20your%20self/journal_entries_list.dart'
    show JournalEntriesListPage;
import 'package:therapylink/Views/express%20your%20self/artistic_expression_list_page.dart';
import 'package:therapylink/Views/relaxtion/breathing_exercise_list_page.dart';
import 'package:therapylink/Views/relaxtion/meditation_list_page.dart';
import 'package:therapylink/Views/relaxtion/visualization_exercise_list_page.dart';
import 'package:therapylink/utils/colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StressRelievingPage extends StatefulWidget {
  const StressRelievingPage({super.key});

  @override
  State<StressRelievingPage> createState() => _StressRelievingPageState();
}

class _StressRelievingPageState extends State<StressRelievingPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String currentSound = '';
  double currentVolume = 1.0;
  bool isPlaying = false;
  bool isPaused = false;

  Future<void> playSound(String assetPath) async {
    if (currentSound != assetPath) {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(assetPath));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(currentVolume);
      await _audioPlayer.resume();
      setState(() {
        currentSound = assetPath;
        isPlaying = true;
        isPaused = false;
      });
    } else if (!isPlaying || isPaused) {
      await _audioPlayer.resume();
      setState(() {
        isPlaying = true;
        isPaused = false;
      });
    }
  }

  void pauseSound() async {
    await _audioPlayer.pause();
    setState(() {
      isPaused = true;
      isPlaying = false;
    });
  }

  void stopSound() async {
    await _audioPlayer.stop();
    setState(() {
      currentSound = '';
      isPlaying = false;
      isPaused = false;
    });
  }

  void changeVolume(double value) async {
    await _audioPlayer.setVolume(value);
    setState(() {
      currentVolume = value;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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
                    _buildRelaxationSection(context),
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

  Widget _buildRelaxationSection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTechniqueCard(
          "Deep Breathing",
          "Practice deep breathing exercises to calm your mind.",
          Icons.air,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BreathingExerciseListPage()),
            );
          },
        ),
        _buildTechniqueCard(
          "Meditation",
          "Engage in guided meditation to reduce stress.",
          Icons.self_improvement,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeditationListPage()),
            );
          },
        ),
        _buildTechniqueCard(
          "Visualization",
          "Visualize peaceful scenes to relax your mind.",
          Icons.landscape,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisualizationExerciseListPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpressYourselfSection() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTechniqueCard(
          "Journaling",
          "Write down your thoughts and feelings.",
          Icons.book,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalEntriesListPage()),
            );
          },
        ),
        _buildTechniqueCard(
          "Artistic Expression",
          "Express yourself through drawing or painting.",
          Icons.brush,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisticExpressionListPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSoothingSoundsSection() {
    final List<Map<String, dynamic>> sounds = [
      {"title": "Rain", "icon": Icons.cloud, "asset": "audio/rain.mp3"},
      {"title": "Ocean", "icon": Icons.waves, "asset": "audio/ocean_breeze.mp3"},
      {"title": "White Noise", "icon": Icons.noise_aware, "asset": "audio/white_noise.mp3"},
      {"title": "Binaural Beats", "icon": Icons.headphones, "asset": "audio/binaural_beats.mp3"},
      {"title": "Fireplace", "icon": Icons.local_fire_department, "asset": "audio/fireplace.mp3"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        final isCurrent = currentSound == sound["asset"];

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: AppColors.bgpurple,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 22,
                      child: Icon(sound["icon"], color: AppColors.bgpurple),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      sound["title"],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => playSound(sound["asset"]),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                    ),
                    ElevatedButton.icon(
                      onPressed: isCurrent && isPlaying ? pauseSound : null,
                      icon: const Icon(Icons.pause),
                      label: const Text("Pause"),
                    ),
                    ElevatedButton.icon(
                      onPressed: isCurrent && (isPlaying || isPaused) ? stopSound : null,
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                    ),
                  ],
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 12),
                  const Text("Volume", style: TextStyle(color: Colors.white70)),
                  Slider(
                    value: currentVolume,
                    onChanged: (val) => changeVolume(val),
                    min: 0,
                    max: 1,
                    divisions: 10,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white38,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Updated Mood Tracker section =====
  Widget _buildMoodTrackerSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) Emoji buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Log your mood:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
            ],
          ),
        ),

        // 2) Divider + heading
        const Divider(color: Colors.white54),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Your logged moods:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        // 3) List of saved moods
        Expanded(
          child: user == null
              ? const Center(
            child: Text(
              "Sign in to see your logs.",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('mood_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snap.error}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No moods logged yet.",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data()! as Map<String, dynamic>;
                  return Card(
                    color: AppColors.bgpurple.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        data['mood'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "${data['dayOfWeek']}, ${data['dateTime']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButton(String emoji, String mood) {
    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to log your mood.')),
          );
          return;
        }

        final now = DateTime.now();
        final dayOfWeek = DateFormat('EEEE').format(now);
        final dateTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('mood_logs')
            .add({
          'userId':    user.uid,
          'mood':      mood,
          'timestamp': now.toIso8601String(),
          'dayOfWeek': dayOfWeek,
          'dateTime':  dateTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged mood: $mood')),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.bgpurple,
            child: Text(emoji, style: const TextStyle(fontSize: 24.0)),
          ),
          const SizedBox(height: 4.0),
          Text(
            mood,
            style: const TextStyle(fontSize: 14.0, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueCard(
      String title, String description, IconData icon, VoidCallback? onTap) {
    return Card(
      color: AppColors.bgpurple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          style: const TextStyle(fontSize: 14.0, color: Colors.white70),
        ),
        onTap: onTap,
      ),
    );
  }
}

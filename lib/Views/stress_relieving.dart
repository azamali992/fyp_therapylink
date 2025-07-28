import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
              // Modern App Bar with Custom Tab Design
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wellness Center',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Stress Relief & Relaxation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Modern Tab Bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorPadding: const EdgeInsets.all(2),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.self_improvement_rounded,
                                  size: 20),
                              text: "Relax"),
                          Tab(
                              icon: Icon(Icons.brush_rounded, size: 20),
                              text: "Express"),
                          Tab(
                              icon: Icon(Icons.music_note_rounded, size: 20),
                              text: "Sounds"),
                          Tab(
                              icon: Icon(Icons.analytics_rounded, size: 20),
                              text: "Mood"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
    final techniques = [
      {
        "title": "Deep Breathing",
        "description":
            "Practice deep breathing exercises to calm your mind and reduce anxiety",
        "icon": Icons.air_rounded,
        "color": Colors.cyan,
        "page": const BreathingExerciseListPage(),
      },
      {
        "title": "Meditation",
        "description":
            "Engage in guided meditation sessions to find inner peace",
        "icon": Icons.self_improvement_rounded,
        "color": Colors.purple,
        "page": const MeditationListPage(),
      },
      {
        "title": "Visualization",
        "description": "Visualize peaceful scenes and calming environments",
        "icon": Icons.landscape_rounded,
        "color": Colors.green,
        "page": const VisualizationExerciseListPage(),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: techniques.length,
      itemBuilder: (context, index) {
        final technique = techniques[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildModernTechniqueCard(
            technique["title"] as String,
            technique["description"] as String,
            technique["icon"] as IconData,
            technique["color"] as Color,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => technique["page"] as Widget),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpressYourselfSection() {
    final activities = [
      {
        "title": "Journaling",
        "description":
            "Write down your thoughts, feelings, and daily experiences",
        "icon": Icons.book_rounded,
        "color": Colors.orange,
        "page": const JournalEntriesListPage(),
      },
      {
        "title": "Artistic Expression",
        "description":
            "Express yourself through drawing, painting, and creative arts",
        "icon": Icons.brush_rounded,
        "color": Colors.pink,
        "page": const ArtisticExpressionListPage(),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildModernTechniqueCard(
            activity["title"] as String,
            activity["description"] as String,
            activity["icon"] as IconData,
            activity["color"] as Color,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => activity["page"] as Widget),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSoothingSoundsSection() {
    final List<Map<String, dynamic>> sounds = [
      {
        "title": "Rain",
        "description": "Gentle rainfall sounds",
        "icon": Icons.cloud_rounded,
        "asset": "audio/rain.mp3",
        "color": Colors.blue,
      },
      {
        "title": "Ocean",
        "description": "Peaceful ocean waves",
        "icon": Icons.waves_rounded,
        "asset": "audio/ocean_breeze.mp3",
        "color": Colors.cyan,
      },
      {
        "title": "White Noise",
        "description": "Calming white noise",
        "icon": Icons.noise_aware_rounded,
        "asset": "audio/white_noise.mp3",
        "color": Colors.grey,
      },
      {
        "title": "Binaural Beats",
        "description": "Relaxing binaural frequencies",
        "icon": Icons.headphones_rounded,
        "asset": "audio/binaural_beats.mp3",
        "color": Colors.purple,
      },
      {
        "title": "Fireplace",
        "description": "Cozy fireplace crackling",
        "icon": Icons.local_fire_department_rounded,
        "asset": "audio/fireplace.mp3",
        "color": Colors.orange,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        final isCurrent = currentSound == sound["asset"];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? (sound["color"] as Color).withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (sound["color"] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (sound["color"] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      sound["icon"] as IconData,
                      color: sound["color"] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sound["title"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          sound["description"] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSoundButton(
                      icon: Icons.play_arrow_rounded,
                      label: "Play",
                      onPressed: () => playSound(sound["asset"]),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSoundButton(
                      icon: Icons.pause_rounded,
                      label: "Pause",
                      onPressed: isCurrent && isPlaying ? pauseSound : null,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSoundButton(
                      icon: Icons.stop_rounded,
                      label: "Stop",
                      onPressed: isCurrent && (isPlaying || isPaused)
                          ? stopSound
                          : null,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (isCurrent) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.volume_down_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: sound["color"] as Color,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: sound["color"] as Color,
                          overlayColor:
                              (sound["color"] as Color).withOpacity(0.3),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: currentVolume,
                          onChanged: changeVolume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ],
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
        // Modern mood selector
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.mood_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "How are you feeling today?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildModernMoodButton("😊", "Happy", Colors.green),
                  _buildModernMoodButton("😢", "Sad", Colors.blue),
                  _buildModernMoodButton("😡", "Angry", Colors.red),
                  _buildModernMoodButton("😰", "Stressed", Colors.orange),
                ],
              ),
            ],
          ),
        ),

        // Mood history section
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Your Mood History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: user == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Sign in to track your moods",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('mood_logs')
                              .orderBy('timestamp', descending: true)
                              .limit(10)
                              .snapshots(),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Center(
                                child: Text(
                                  "Error loading moods",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                              );
                            }
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              );
                            }
                            final docs = snap.data!.docs;
                            if (docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sentiment_neutral_rounded,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No moods logged yet",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (ctx, i) {
                                final data =
                                    docs[i].data()! as Map<String, dynamic>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _getMoodEmoji(data['mood'] ?? ''),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['mood'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "${data['dayOfWeek']}, ${data['dateTime']}",
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTechniqueCard(String title, String description,
      IconData icon, Color accentColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                ),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: onPressed != null
            ? color.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPressed != null
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    onPressed != null ? color : Colors.white.withOpacity(0.3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMoodButton(String emoji, String mood, Color color) {
    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to log your mood.'),
              backgroundColor: Colors.orange,
            ),
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
          'userId': user.uid,
          'mood': mood,
          'timestamp': now.toIso8601String(),
          'dayOfWeek': dayOfWeek,
          'dateTime': dateTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged mood: $mood'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              mood,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      case 'stressed':
        return '😰';
      default:
        return '😐';
    }
  }
}

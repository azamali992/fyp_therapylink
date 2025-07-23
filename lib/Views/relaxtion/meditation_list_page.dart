import 'package:flutter/material.dart';
import 'meditation_model.dart';
import 'meditation_detail_page.dart';
import 'package:therapylink/utils/colors.dart';

class MeditationListPage extends StatelessWidget {
  const MeditationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MeditationTechnique> techniques = [
      MeditationTechnique(
        title: "Mindfulness Meditation",
        description: "Focus on breath and present awareness.",
        icon: Icons.spa,
        youtubeUrl: "https://www.youtube.com/watch?v=inpok4MKVLM",
        steps: "Sit comfortably\nFocus on your breathing\nObserve your thoughts without judgment\nReturn to breath when distracted\nContinue for 10–20 minutes",
      ),
      MeditationTechnique(
        title: "Loving-Kindness Meditation",
        description: "Send love and compassion to all beings.",
        icon: Icons.favorite,
        youtubeUrl: "https://www.youtube.com/watch?v=sz7cpV7ERsM",
        steps: "Sit comfortably\nInhale deeply and think of someone you love\nRepeat silently: 'May you be happy'\nExtend those wishes to others\nRepeat for several minutes",
      ),
      MeditationTechnique(
        title: "Body Scan Meditation",
        description: "Scan your body and release tension.",
        icon: Icons.accessibility,
        youtubeUrl: "https://www.youtube.com/watch?v=zsCVqFr6j1g",
        steps: "Lie down or sit comfortably\nBring awareness to your feet\nSlowly move attention up through your body\nNotice tension and breathe into it\nFinish with whole-body awareness",
      ),
      MeditationTechnique(
        title: "Transcendental Meditation",
        description: "Use silent mantra repetition.",
        icon: Icons.repeat,
        youtubeUrl: "https://www.youtube.com/watch?v=m8rRzTtP7Tc",
        steps: "Sit comfortably with eyes closed\nChoose a personal mantra (e.g., 'Om')\nSilently repeat the mantra\nLet thoughts come and go\nContinue for 15–20 minutes",
      ),
      MeditationTechnique(
        title: "Zen Meditation (Zazen)",
        description: "Observe thoughts without judgment.",
        icon: Icons.self_improvement,
        youtubeUrl: "https://www.youtube.com/watch?v=NCY9bKeCg8g",
        steps: "Sit upright, hands on lap\nKeep eyes slightly open\nFocus on breath or count it\nLet thoughts pass without attachment\nPractice for 10–30 minutes",
      ),
      MeditationTechnique(
        title: "Chakra Meditation",
        description: "Balance your body’s energy centers.",
        icon: Icons.brightness_medium,
        youtubeUrl: "https://www.youtube.com/watch?v=qs_DuZigRzY",
        steps: "Sit or lie down\nFocus on each chakra one by one\nVisualize its color and location\nChant its associated sound if known\nContinue until all chakras are covered",
      ),
      MeditationTechnique(
        title: "Mantra Meditation",
        description: "Chant or repeat calming phrases.",
        icon: Icons.record_voice_over,
        youtubeUrl: "https://www.youtube.com/watch?v=Ze6DijAglI8",
        steps: "Choose a calming word or phrase (e.g., 'peace')\nSit quietly and repeat it silently\nFocus only on the mantra\nIf distracted, return gently\nPractice for 10–15 minutes",
      ),
      MeditationTechnique(
        title: "Candle Gazing (Trataka)",
        description: "Improve focus by staring at a flame.",
        icon: Icons.local_fire_department,
        youtubeUrl: "https://www.youtube.com/watch?v=b7vJ-fK9Ibc",
        steps: "Light a candle at eye level\nSit 2 feet away and gaze at the flame\nAvoid blinking if possible\nWhen eyes water, close them and visualize\nRepeat for 5–10 minutes",
      ),
      MeditationTechnique(
        title: "Vipassana Meditation",
        description: "Gain insight through awareness.",
        icon: Icons.insights,
        youtubeUrl: "https://www.youtube.com/watch?v=bb3OiJcY9t4",
        steps: "Sit with a straight back\nFocus on breath and bodily sensations\nObserve arising thoughts without reaction\nAcknowledge impermanence\nPractice daily for lasting impact",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meditation Techniques", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          itemCount: techniques.length,
          itemBuilder: (context, index) {
            final technique = techniques[index];
            return Card(
              color: AppColors.bgpurple,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(technique.icon, color: Colors.white, size: 32),
                title: Text(technique.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(technique.description, style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeditationDetailPage(technique: technique),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

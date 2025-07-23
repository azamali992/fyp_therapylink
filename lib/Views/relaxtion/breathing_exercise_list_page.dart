import 'package:flutter/material.dart';
import 'package:therapylink/utils/colors.dart';
import 'breathing_exercise_detail_page.dart';
import 'breathing_exercise_model.dart';

class BreathingExerciseListPage extends StatelessWidget {
  const BreathingExerciseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BreathingExercise> exercises = [
      BreathingExercise(
        title: "Box Breathing",
        description: "Breathe in, hold, breathe out, hold – all for 4 seconds.",
        icon: Icons.crop_square,
        youtubeUrl: "https://youtu.be/tEmt1Znux58?si=kkjhXW1N5aJCNU1i",
        steps: "Inhale for 4 seconds\n"
            "Hold for 4 seconds\n"
            "Exhale for 4 seconds\n"
            "Hold for 4 seconds\n"
            "Repeat for 2–5 minutes.",
      ),
      BreathingExercise(
        title: "4-7-8 Breathing",
        description: "A calming technique that regulates breathing.",
        icon: Icons.looks_4,
        youtubeUrl: "https://www.youtube.com/watch?v=p8fjYPC-k2k",
        steps: "Inhale for 4 seconds\n"
            "Hold for 7 seconds\n"
            "Exhale for 8 seconds\n"
            "Repeat for 4–6 cycles.",
      ),
      BreathingExercise(
        title: "Alternate Nostril Breathing",
        description: "Balances the body and mind through nostril control.",
        icon: Icons.swap_horiz,
        youtubeUrl: "https://www.youtube.com/watch?v=8VwufJrUhic",
        steps: "Close right nostril, inhale through left\n"
            "Close left, exhale through right\n"
            "Inhale through right\n"
            "Close right, exhale through left\n"
            "Repeat for 3–5 minutes.",
      ),
      BreathingExercise(
        title: "Pursed Lip Breathing",
        description: "Slow your breathing and release trapped air.",
        icon: Icons.air_outlined,
        youtubeUrl: "https://www.youtube.com/watch?v=QeYgLLahHv8",
        steps: "Inhale slowly through your nose for 2 seconds\n"
            "Purse your lips as if to whistle\n"
            "Exhale slowly through pursed lips for 4 seconds\n"
            "Repeat for 5–10 minutes.",
      ),
      BreathingExercise(
        title: "Diaphragmatic Breathing",
        description: "Also called belly breathing, encourages deep breath from the diaphragm.",
        icon: Icons.favorite_outline,
        youtubeUrl: "https://www.youtube.com/watch?v=kgTL5G1ibIo",
        steps: "Lie on your back or sit comfortably\n"
            "Place one hand on your chest, one on your stomach\n"
            "Inhale deeply so only your belly rises\n"
            "Exhale slowly\n"
            "Repeat for 5–10 minutes daily.",
      ),
      BreathingExercise(
        title: "Resonant Breathing",
        description: "Also known as coherent breathing. Helps synchronize heart and breath.",
        icon: Icons.sync_alt,
        youtubeUrl: "https://www.youtube.com/watch?v=gz4G31LGyog",
        steps: "Inhale for 5 seconds\n"
            "Exhale for 5 seconds\n"
            "Continue the rhythm for several minutes\n"
            "Ideal for calming the nervous system.",
      ),
      BreathingExercise(
        title: "Humming Bee Breath (Bhramari)",
        description: "A yogic technique using sound vibrations to relax.",
        icon: Icons.music_note,
        youtubeUrl: "https://www.youtube.com/watch?v=Ec2fN3ut7oc",
        steps: "Sit comfortably, close your eyes\n"
            "Inhale deeply through the nose\n"
            "While exhaling, make a gentle humming sound like a bee\n"
            "Feel the vibration in your head\n"
            "Repeat for 5–7 rounds.",
      ),
      BreathingExercise(
        title: "Mindful Breathing",
        description: "Focus your attention on breath to ground your thoughts.",
        icon: Icons.spa,
        youtubeUrl: "https://www.youtube.com/watch?v=nmFUDkj1Aq0",
        steps: "Sit in a quiet place\n"
            "Close your eyes and breathe naturally\n"
            "Focus your attention on your breath\n"
            "If distracted, gently bring focus back to breath\n"
            "Continue for 5–10 minutes.",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
    title: const Text(
    "Breathing Exercises",
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: AppColors.bgpurple,
    iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              color: AppColors.bgpurple,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(exercise.icon, size: 32, color: Colors.white),
                title: Text(
                  exercise.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  exercise.description,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BreathingExerciseDetailPage(exercise: exercise),
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

import 'package:flutter/material.dart';
import 'visualization_exercise_model.dart';
import 'visualization_exercise_detail_page.dart';
import 'package:therapylink/utils/colors.dart';

class VisualizationExerciseListPage extends StatelessWidget {
  const VisualizationExerciseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<VisualizationExercise> exercises = [
      VisualizationExercise(
        title: "Starry Sky",
        description: "Visualize lying under a calm sky full of stars.",
        imageAsset: "assets/starry_sky.jpg",
        audioAsset: "audio/starry_sky.mp3",
        narration: [
          "Close your eyes and imagine a peaceful night sky...",
          "Stars twinkle above you, casting soft light...",
          "Feel the calm as you lie still under the stars...",
          "The air is cool and still, wrapping you in serenity...",
          "You begin to notice constellations painting the sky...",
          "A shooting star blinks across the horizon...",
          "The world feels quiet, vast, and at peace...",
          "Breathe in the calm, breathe out the tension...",
          "Let go of all worries, you are one with the night...",
          "Stay present in this tranquil moment of stillness...",
          // New lines
          "The moonlight kisses your skin with a silver glow...",
          "The universe embraces you in silent harmony...",
          "A gentle breeze carries your thoughts away...",
          "You are grounded, safe, and deeply relaxed...",
        ],
      ),
      VisualizationExercise(
        title: "Ocean Breeze",
        description: "Imagine waves crashing gently as you breathe.",
        imageAsset: "assets/ocean.jpg",
        audioAsset: "audio/ocean_breeze.mp3",
        narration: [
          "You're walking along a quiet beach...",
          "The waves roll in, the breeze cool on your skin...",
          "Each breath flows with the rhythm of the sea...",
          "You feel the sand under your feet, grounding you...",
          "Seagulls echo softly in the distance...",
          "The sunlight glistens on the waves like diamonds...",
          "With every step, your mind clears further...",
          "Breathe in the salty air, feel it calm your senses...",
          "You are free, weightless, peaceful...",
          "This is your sanctuary—return here whenever you need peace...",
          // New lines
          "Shells crunch beneath your feet as you wander slowly...",
          "The horizon stretches endlessly with promise...",
          "The sea hums a lullaby only your heart can hear...",
          "You surrender to the rhythm of waves and breath...",
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visualization Exercises", style: TextStyle(color: Colors.white)),
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
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return Card(
              color: AppColors.bgpurple,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.landscape, color: Colors.white),
                title: Text(exercise.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(exercise.description, style: const TextStyle(color: Colors.white70)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisualizationExerciseDetailPage(exercise: exercise),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

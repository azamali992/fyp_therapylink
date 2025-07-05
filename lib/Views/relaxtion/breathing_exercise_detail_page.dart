import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:therapylink/utils/colors.dart';
import 'breathing_exercise_model.dart';

class BreathingExerciseDetailPage extends StatefulWidget {
  final BreathingExercise exercise;

  const BreathingExerciseDetailPage({super.key, required this.exercise});

  @override
  State<BreathingExerciseDetailPage> createState() => _BreathingExerciseDetailPageState();
}

class _BreathingExerciseDetailPageState extends State<BreathingExerciseDetailPage> {
  YoutubePlayerController? _controller;
  late List<String> steps;
  final List<bool> _completed = [];

  @override
  void initState() {
    super.initState();
    steps = widget.exercise.steps.trim().split('\n');
    _completed.addAll(List.generate(steps.length, (_) => false));

    final videoId = YoutubePlayer.convertUrlToId(widget.exercise.youtubeUrl) ?? "";
    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _launchYouTubeUrl() async {
    final uri = Uri.tryParse(widget.exercise.youtubeUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open YouTube link")),
      );
    }
  }

  Widget _buildStepItem(int index) {
    final isCompleted = _completed[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _completed[index] = !_completed[index];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Step ${index + 1}: ',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    TextSpan(
                      text: steps[index],
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
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
        child: ListView(
          children: [
            const Text(
              "Let's do this!!!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            ...List.generate(steps.length, (index) => _buildStepItem(index)),

            const SizedBox(height: 20),
            const Text(
              "Watch the guide:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            if (_controller != null)
              YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.white,
              )
            else
              const Text(
                "Video could not be loaded.",
                style: TextStyle(color: Colors.white70),
              ),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: _launchYouTubeUrl,
              child: Text(
                widget.exercise.youtubeUrl,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.lightBlueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

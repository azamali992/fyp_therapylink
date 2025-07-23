import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'visualization_exercise_model.dart';
import 'package:therapylink/utils/colors.dart';

class VisualizationExerciseDetailPage extends StatefulWidget {
  final VisualizationExercise exercise;

  const VisualizationExerciseDetailPage({super.key, required this.exercise});

  @override
  State<VisualizationExerciseDetailPage> createState() =>
      _VisualizationExerciseDetailPageState();
}

class _VisualizationExerciseDetailPageState
    extends State<VisualizationExerciseDetailPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool completed = false;
  bool isPaused = false;
  bool isMuted = false;
  double volume = 1.0;
  Timer? _timer;
  int narrationIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startVisualization() async {
    try {
      setState(() {
        isPlaying = true;
        isPaused = false;
        completed = false;
        narrationIndex = 0;
      });

      await _audioPlayer.setSource(AssetSource(widget.exercise.audioAsset));
      await _audioPlayer.setVolume(isMuted ? 0.0 : volume);
      await _audioPlayer.resume();

      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (!isPaused && narrationIndex < widget.exercise.narration.length - 1) {
          setState(() => narrationIndex++);
        } else if (!isPaused) {
          timer.cancel();
          _audioPlayer.stop();
          setState(() {
            completed = true;
            isPlaying = false;
          });
        }
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error playing audio")),
      );
    }
  }

  void _pauseOrResume() async {
    if (isPaused) {
      await _audioPlayer.resume();
      setState(() => isPaused = false);
    } else {
      await _audioPlayer.pause();
      setState(() => isPaused = true);
    }
  }

  void _stopVisualization() async {
    await _audioPlayer.stop();
    _timer?.cancel();
    setState(() {
      isPlaying = false;
      isPaused = false;
      completed = false;
      narrationIndex = 0;
    });
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _audioPlayer.setVolume(isMuted ? 0.0 : volume);
    });
  }

  void _adjustVolume(double newVolume) {
    setState(() {
      volume = newVolume;
      if (!isMuted) {
        _audioPlayer.setVolume(volume);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              completed ? Icons.check_circle : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => completed = !completed);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            exercise.imageAsset,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  "Narrated Visualization",
                  style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...List.generate(
                  exercise.narration.length,
                      (i) => AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: i <= narrationIndex ? 1.0 : 0.2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        "• ${exercise.narration[i]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isPlaying ? null : _startVisualization,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bgpurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isPlaying ? _pauseOrResume : null,
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(isPaused ? "Resume" : "Pause"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isPlaying || isPaused ? _stopVisualization : null,
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleMute,
                      icon: Icon(
                        isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: _adjustVolume,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

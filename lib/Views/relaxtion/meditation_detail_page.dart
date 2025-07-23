import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'meditation_model.dart';
import 'package:therapylink/utils/colors.dart';

class MeditationDetailPage extends StatefulWidget {
  final MeditationTechnique technique;

  const MeditationDetailPage({super.key, required this.technique});

  @override
  State<MeditationDetailPage> createState() => _MeditationDetailPageState();
}

class _MeditationDetailPageState extends State<MeditationDetailPage> {
  YoutubePlayerController? _controller;
  late List<String> steps;
  final List<bool> _completed = [];

  @override
  void initState() {
    super.initState();
    steps = widget.technique.steps.trim().split('\n');
    _completed.addAll(List.generate(steps.length, (_) => false));

    final videoId = YoutubePlayer.convertUrlToId(widget.technique.youtubeUrl) ?? "";
    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _launchYouTubeUrl() async {
    final uri = Uri.tryParse(widget.technique.youtubeUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open YouTube link")),
      );
    }
  }

  Widget _buildStepItem(int index) {
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
            if (_completed[index])
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
        title: Text(widget.technique.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            const Text(
              "Let's begin your meditation:",
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
              const Text("Video could not be loaded.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _launchYouTubeUrl,
              child: Text(
                widget.technique.youtubeUrl,
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

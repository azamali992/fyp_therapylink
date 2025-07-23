import 'package:flutter/material.dart';

class MeditationTechnique {
  final String title;
  final String description;
  final IconData icon;
  final String youtubeUrl;
  final String steps;

  MeditationTechnique({
    required this.title,
    required this.description,
    required this.icon,
    required this.youtubeUrl,
    required this.steps,
  });
}

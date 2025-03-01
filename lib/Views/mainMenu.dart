import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/Views/maps.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/Views/voicechat.dart';
import 'package:therapylink/utils/colors.dart';
import 'home_page.dart'; // Import the ChatBot
import 'stress_relieving.dart'; // Import the StressRelievingPage

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final Map<String, Color> _buttonColors = {
    'Voice Chat': Colors.blue,
    'Settings': Colors.red,
    'Mood Analysis': Colors.orange,
    'Stress Relief': Colors.purple,
    'Local Clinics': Colors.teal,
  };

  final Map<String, bool> _isClicked = {
    'Voice Chat': false,
    'Settings': false,
    'Mood Analysis': false,
    'Stress Relief': false,
    'Local Clinics': false,
  };

  String? _selectedLabel;

  void _handleMenuItemTap(String label) {
    setState(() {
      _selectedLabel = label;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      switch (label) {
        case 'Voice Chat':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VoiceChatPage()),
          );
          break;
        case 'Settings':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
          break;
        case 'Mood Analysis':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoodAnalysisPage()),
          );
          break;
        case 'Stress Relief':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StressRelievingPage()),
          );
          break;
        case 'Local Clinics':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapsPage()),
          );
          break;
        default:
          break;
      }
      setState(() {
        _selectedLabel = null;
      });
    });
  }

  Color _getOriginalColor(String label) {
    switch (label) {
      case 'Voice Chat':
        return Colors.blue;
      case 'Settings':
        return Colors.red;
      case 'Mood Analysis':
        return Colors.orange;
      case 'Stress Relief':
        return Colors.purple;
      case 'Local Clinics':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double baseFontSize =
        screenWidth * 0.05; // Adjust this value as needed

    return Scaffold(
      appBar:
          CustomAppBar(screenWidth: screenWidth, screenHeight: screenHeight),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StaggeredGridView.countBuilder(
            crossAxisCount: 4,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) {
              String label;
              IconData icon;
              String subLabel;
              switch (index) {
                case 0:
                  label = 'Voice Chat';
                  icon = Icons.voice_chat;
                  subLabel = 'Chat with us';
                  break;
                case 1:
                  label = 'Settings';
                  icon = Icons.settings;
                  subLabel = 'Adjust your preferences';
                  break;
                case 2:
                  label = 'Mood Analysis';
                  icon = Icons.analytics;
                  subLabel = 'Analyze your mood';
                  break;
                case 3:
                  label = 'Stress Relief';
                  icon = Icons.person;
                  subLabel = 'Relieve your stress';
                  break;
                case 4:
                  label = 'Local Clinics';
                  icon = Icons.map;
                  subLabel = 'Find nearby clinics';
                  break;
                default:
                  return Container();
              }

              return _buildMenuItem(
                icon: icon,
                label: label,
                subLabel: subLabel,
                context: context,
                height: 150.0,
                width: 150.0,
                baseFontSize: baseFontSize,
              );
            },
            staggeredTileBuilder: (int index) {
              switch (index) {
                case 0:
                  return const StaggeredTile.count(2, 3);
                case 1:
                  return const StaggeredTile.count(2, 2);
                case 2:
                  return const StaggeredTile.count(2, 3);
                case 3:
                  return const StaggeredTile.count(2, 2);
                case 4:
                  return const StaggeredTile.count(4, 2);
                default:
                  return const StaggeredTile.count(1, 1);
              }
            },
          ),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Voice Chat':
        return Icons.voice_chat;
      case 'Settings':
        return Icons.settings;
      case 'Mood Analysis':
        return Icons.analytics;
      case 'Stress Relief':
        return Icons.person;
      case 'Local Clinics':
        return Icons.map;
      default:
        return Icons.help;
    }
  }

  String _getSubLabelForLabel(String label) {
    switch (label) {
      case 'Voice Chat':
        return 'Chat with us';
      case 'Settings':
        return 'Adjust your preferences';
      case 'Mood Analysis':
        return 'Analyze your mood';
      case 'Stress Relief':
        return 'Relieve your stress';
      case 'Local Clinics':
        return 'Find nearby clinics';
      default:
        return '';
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subLabel,
    required BuildContext context,
    required double height,
    required double width,
    required double baseFontSize,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: 40.0,
      borderRadius: BorderRadius.circular(25.0),
      child: InkWell(
        onTap: () {
          _handleMenuItemTap(label);
        },
        onTapDown: (_) {
          setState(() {
            _isClicked[label] = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isClicked[label] = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isClicked[label] = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isClicked[label]!
                    ? _buttonColors[label]!
                        .withOpacity(0.3) // More transparent when clicked
                    : _buttonColors[label]!.withOpacity(0.7),
                _isClicked[label]!
                    ? _buttonColors[label]!
                        .withOpacity(0.4) // More transparent when clicked
                    : _buttonColors[label]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _isClicked[label]!
                  ? Colors.white
                      .withOpacity(0.3) // White border for glass effect
                  : Colors.transparent,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: _isClicked[label]!
                    ? Colors.white
                        .withOpacity(0.1) // Lighter shadow for glass effect
                    : Colors.black.withOpacity(0.2),
                spreadRadius: _isClicked[label]! ? 1 : 2,
                blurRadius: _isClicked[label]! ? 15 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: width * 0.4,
                  height: height * 0.4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24.0, color: _buttonColors[label]),
                ),
                const SizedBox(height: 8.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.7,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:therapylink/Views/custom_app_bar.dart';
import 'package:therapylink/Views/maps.dart';
import 'package:therapylink/Views/moodanalysis.dart';
import 'package:therapylink/Views/settings.dart';
import 'package:therapylink/Views/voicechat.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:therapylink/utils/menu_item_builder.dart'; // Import the extracted method
// Import the ChatBot
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

              return buildMenuItem(
                icon: icon,
                label: label,
                subLabel: subLabel,
                context: context,
                height: 150.0,
                width: 150.0,
                baseFontSize: baseFontSize,
                buttonColors: _buttonColors,
                isClicked: _isClicked,
                handleMenuItemTap: _handleMenuItemTap,
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
}
